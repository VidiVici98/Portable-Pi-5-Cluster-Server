#!/bin/bash

################################################################################
# Cluster Status & Diagnostics Tool
# Purpose: Understand current state of boot node and connected nodes
# Usage: sudo ./scripts/cluster-status.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"
LOG_FILE="/var/log/cluster-diagnostics.log"
REPORT_FILE="/tmp/cluster-status-$(date +%Y%m%d-%H%M%S).txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
WARN=0
FAIL=0

################################################################################
# Utility Functions
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
    echo "=== $1 ===" >> "$REPORT_FILE"
}

print_status() {
    local status=$1
    local message=$2
    
    case $status in
        PASS)
            echo -e "${GREEN}✓ PASS${NC}: $message"
            echo "✓ PASS: $message" >> "$REPORT_FILE"
            ((PASS++))
            ;;
        WARN)
            echo -e "${YELLOW}⚠ WARN${NC}: $message"
            echo "⚠ WARN: $message" >> "$REPORT_FILE"
            ((WARN++))
            ;;
        FAIL)
            echo -e "${RED}✗ FAIL${NC}: $message"
            echo "✗ FAIL: $message" >> "$REPORT_FILE"
            ((FAIL++))
            ;;
        INFO)
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            echo "ℹ INFO: $message" >> "$REPORT_FILE"
            ;;
    esac
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_status PASS "Command available: $1"
        return 0
    else
        print_status FAIL "Command missing: $1"
        return 1
    fi
}

check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        print_status PASS "Service running: $service"
        return 0
    else
        print_status WARN "Service not running: $service ($(systemctl is-active $service))"
        return 1
    fi
}

check_file() {
    local file=$1
    if [ -f "$file" ]; then
        print_status PASS "File exists: $file"
        return 0
    else
        print_status FAIL "File missing: $file"
        return 1
    fi
}

check_dir() {
    local dir=$1
    if [ -d "$dir" ]; then
        print_status PASS "Directory exists: $dir"
        return 0
    else
        print_status FAIL "Directory missing: $dir"
        return 1
    fi
}

################################################################################
# System Checks
################################################################################

check_system_info() {
    print_header "System Information"
    
    echo "Hostname: $(hostname)" >> "$REPORT_FILE"
    print_status INFO "Hostname: $(hostname)"
    
    echo "Kernel: $(uname -r)" >> "$REPORT_FILE"
    print_status INFO "Kernel: $(uname -r)"
    
    echo "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')" >> "$REPORT_FILE"
    print_status INFO "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    
    if grep -q "Raspberry Pi 5" /proc/device-tree/model 2>/dev/null; then
        print_status PASS "Hardware: Raspberry Pi 5"
    elif grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
        print_status WARN "Hardware: $(cat /proc/device-tree/model) (not Pi 5)"
    else
        print_status INFO "Hardware: $(cat /proc/device-tree/model 2>/dev/null || echo 'Unknown')"
    fi
    
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')" >> "$REPORT_FILE"
    print_status INFO "Memory: $(free -h | grep Mem | awk '{print $2}')"
    
    echo "Storage: $(df -h / | tail -1 | awk '{print $4 " free of " $2}')" >> "$REPORT_FILE"
    print_status INFO "Storage: $(df -h / | tail -1 | awk '{print $4 " free of " $2}')"
}

check_network_interfaces() {
    print_header "Network Interfaces"
    
    local active_interfaces=0
    while IFS= read -r iface; do
        if [ -n "$iface" ]; then
            local ip=$(ip addr show "$iface" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
            if [ -n "$ip" ]; then
                print_status PASS "Interface active: $iface ($ip)"
                ((active_interfaces++))
            else
                print_status WARN "Interface inactive: $iface"
            fi
        fi
    done < <(ip link show | grep "^[0-9]" | awk -F': ' '{print $2}' | grep -v "^lo$")
    
    if [ $active_interfaces -eq 0 ]; then
        print_status FAIL "No active network interfaces found"
    fi
}

check_boot_node_services() {
    print_header "Boot Node Services"
    
    check_service "dnsmasq" || true
    check_service "nfs-server" || true
    check_service "nfs-kernel-server" || true
    check_service "rsync" || true
    check_service "ssh" || true
    check_service "chronyd" || true
}

check_tftp_setup() {
    print_header "TFTP/PXE Boot Setup"
    
    check_dir "/srv/tftp" || print_status FAIL "TFTP root missing"
    check_dir "/srv/nfs" || print_status FAIL "NFS root missing"
    
    if [ -d "/srv/tftp" ]; then
        local boot_files=$(find /srv/tftp -type f 2>/dev/null | wc -l)
        print_status INFO "TFTP files: $boot_files files"
    fi
    
    if [ -d "/srv/nfs" ]; then
        local nfs_dirs=$(find /srv/nfs -maxdepth 2 -type d 2>/dev/null | wc -l)
        print_status INFO "NFS directories: $nfs_dirs directories"
    fi
}

check_nfs_exports() {
    print_header "NFS Configuration"
    
    check_file "/etc/exports" || print_status FAIL "NFS exports file missing"
    
    if [ -f "/etc/exports" ]; then
        local active_exports=$(grep -v "^#" /etc/exports | grep -v "^$" | wc -l)
        print_status INFO "Active NFS exports: $active_exports"
        echo "" >> "$REPORT_FILE"
        echo "NFS Exports:" >> "$REPORT_FILE"
        grep -v "^#" /etc/exports | grep -v "^$" >> "$REPORT_FILE"
    fi
}

check_dnsmasq() {
    print_header "DNSMASQ Configuration"
    
    check_file "/etc/dnsmasq.conf" || print_status FAIL "DNSMASQ config missing"
    
    if [ -f "/etc/dnsmasq.conf" ]; then
        local dhcp_range=$(grep "dhcp-range" /etc/dnsmasq.conf | head -1)
        if [ -n "$dhcp_range" ]; then
            print_status INFO "DHCP config: $dhcp_range"
        else
            print_status WARN "No DHCP range configured"
        fi
        
        local pxe_boot=$(grep "dhcp-boot" /etc/dnsmasq.conf | head -1)
        if [ -n "$pxe_boot" ]; then
            print_status INFO "PXE config: $pxe_boot"
        else
            print_status WARN "No PXE boot configured"
        fi
    fi
}

check_node_connectivity() {
    print_header "Node Connectivity Check"
    
    # Read node list from dnsmasq.conf or hosts
    local nodes=(
        "192.168.1.101:boot-node"
        "192.168.1.102:isr"
        "192.168.1.103:mesh"
        "192.168.1.104:vhf"
    )
    
    local reachable=0
    for node_info in "${nodes[@]}"; do
        local ip="${node_info%%:*}"
        local name="${node_info##*:}"
        
        if timeout 2 ping -c 1 "$ip" &>/dev/null; then
            print_status PASS "Node reachable: $name ($ip)"
            ((reachable++))
        else
            print_status WARN "Node unreachable: $name ($ip)"
        fi
    done
    
    if [ $reachable -gt 1 ]; then
        print_status PASS "Multiple nodes detected"
    elif [ $reachable -eq 1 ]; then
        print_status WARN "Only boot node online (no cluster detected)"
    else
        print_status FAIL "No nodes reachable"
    fi
}

check_ssh_access() {
    print_header "SSH Connectivity"
    
    local nodes=(
        "root@192.168.1.102"
        "root@192.168.1.103"
        "root@192.168.1.104"
    )
    
    for node in "${nodes[@]}"; do
        if timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$node" "echo 'OK'" &>/dev/null 2>&1; then
            print_status PASS "SSH accessible: $node"
        else
            print_status WARN "SSH not accessible: $node"
        fi
    done
}

check_configuration_files() {
    print_header "Configuration Files"
    
    check_file "$CONFIG_DIR/network/dnsmasq.conf" || true
    check_file "$CONFIG_DIR/network/hosts" || true
    check_file "$CONFIG_DIR/nfs/exports" || true
    check_file "$CONFIG_DIR/ntp/chrony/chrony.conf" || true
}

check_existing_scripts() {
    print_header "Existing Scripts"
    
    check_file "$SCRIPT_DIR/oled_display_v1.py" || true
    check_file "$SCRIPT_DIR/security_monitor_v1.1.py" || true
}

check_resource_usage() {
    print_header "System Resources"
    
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    print_status INFO "CPU Usage: ${cpu_usage%.*}%"
    
    local mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100)}')
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        print_status WARN "Memory Usage: ${mem_usage}%"
    else
        print_status PASS "Memory Usage: ${mem_usage}%"
    fi
    
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 80 ]; then
        print_status WARN "Disk Usage: ${disk_usage}%"
    else
        print_status PASS "Disk Usage: ${disk_usage}%"
    fi
}

################################################################################
# Main Execution
################################################################################

main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║   Portable Pi 5 Cluster - Status & Diagnostics Tool          ║
║   Run: sudo ./scripts/cluster-status.sh                        ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log "Starting cluster diagnostics..."
    
    # Initialize report
    > "$REPORT_FILE"
    echo "Cluster Diagnostics Report" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    # Run all checks
    check_system_info
    check_network_interfaces
    check_configuration_files
    check_boot_node_services
    check_tftp_setup
    check_nfs_exports
    check_dnsmasq
    check_node_connectivity
    check_ssh_access
    check_existing_scripts
    check_resource_usage
    
    # Summary
    print_header "Summary"
    echo "" >> "$REPORT_FILE"
    echo "Summary:" >> "$REPORT_FILE"
    echo "  PASS: $PASS" >> "$REPORT_FILE"
    echo "  WARN: $WARN" >> "$REPORT_FILE"
    echo "  FAIL: $FAIL" >> "$REPORT_FILE"
    
    echo -e "\n${BLUE}Results Summary:${NC}"
    echo -e "  ${GREEN}PASS: $PASS${NC}"
    echo -e "  ${YELLOW}WARN: $WARN${NC}"
    echo -e "  ${RED}FAIL: $FAIL${NC}"
    
    if [ $FAIL -eq 0 ]; then
        echo -e "\n${GREEN}✓ All critical checks passed${NC}"
    elif [ $FAIL -lt 5 ]; then
        echo -e "\n${YELLOW}⚠ Some issues detected - see report for details${NC}"
    else
        echo -e "\n${RED}✗ Multiple issues detected - system not ready for multi-node cluster${NC}"
    fi
    
    echo -e "\n${BLUE}Full report saved to: $REPORT_FILE${NC}\n"
    
    log "Diagnostics complete"
}

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    exit 1
fi

main "$@"

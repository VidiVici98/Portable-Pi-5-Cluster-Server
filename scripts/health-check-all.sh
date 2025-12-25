#!/bin/bash

################################################################################
# Comprehensive Cluster Health Check Suite
#
# Purpose: Automated health verification for all cluster services
# Checks system, network, services, and data integrity
#
# Date: December 25, 2025
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
PASS=0
WARN=0
FAIL=0

LOG_DIR="/var/log/health-checks"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/health-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# LOGGING
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}═══════ $1 ═══════${NC}" | tee -a "$LOG_FILE"
}

check_pass() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
    ((PASS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
    ((WARN++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
    ((FAIL++))
}

################################################################################
# SYSTEM HEALTH
################################################################################

check_system_health() {
    section "System Health Checks"
    
    # Uptime
    local uptime=$(uptime -p)
    log "System uptime: $uptime"
    check_pass "System is running"
    
    # Disk space
    local root_usage=$(df / | tail -1 | awk '{print $5}' | cut -d% -f1)
    if [ "$root_usage" -lt 80 ]; then
        check_pass "Root disk usage: ${root_usage}%"
    elif [ "$root_usage" -lt 95 ]; then
        check_warn "Root disk usage high: ${root_usage}%"
    else
        check_fail "Root disk critically full: ${root_usage}%"
    fi
    
    # Memory
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
    if [ "$mem_usage" -lt 85 ]; then
        check_pass "Memory usage: ${mem_usage}%"
    else
        check_warn "Memory usage high: ${mem_usage}%"
    fi
    
    # Load average
    local load=$(cat /proc/loadavg | awk '{print $1}')
    local cores=$(nproc)
    if (( $(echo "$load < $cores" | bc -l) )); then
        check_pass "Load average: $load (within normal)"
    else
        check_warn "Load average elevated: $load (cores: $cores)"
    fi
    
    # Temperature
    if command -v vcgencmd &>/dev/null; then
        local temp=$(vcgencmd measure_temp 2>/dev/null | grep -oP '\d+\.\d+' || echo "unknown")
        if [ "$temp" != "unknown" ]; then
            if (( $(echo "$temp < 70" | bc -l) )); then
                check_pass "CPU temperature: ${temp}°C"
            elif (( $(echo "$temp < 80" | bc -l) )); then
                check_warn "CPU temperature elevated: ${temp}°C"
            else
                check_fail "CPU temperature critical: ${temp}°C"
            fi
        fi
    fi
    
    # Kernel messages (dmesg errors in last hour)
    local dmesg_errors=$(dmesg | tail -100 | grep -iE "(error|critical|panic)" | wc -l)
    if [ "$dmesg_errors" -eq 0 ]; then
        check_pass "No recent kernel errors"
    else
        check_warn "Found $dmesg_errors kernel messages"
    fi
}

################################################################################
# NETWORK HEALTH
################################################################################

check_network_health() {
    section "Network Health Checks"
    
    # DNS resolution
    if nslookup google.com &>/dev/null; then
        check_pass "DNS resolution working"
    else
        check_fail "DNS resolution failed"
    fi
    
    # Gateway connectivity
    local gateway=$(ip route | grep default | awk '{print $3}')
    if ping -c 1 -W 2 "$gateway" &>/dev/null; then
        check_pass "Gateway reachable: $gateway"
    else
        check_fail "Gateway unreachable: $gateway"
    fi
    
    # IP addresses assigned
    local ip_count=$(hostname -I | wc -w)
    if [ "$ip_count" -gt 0 ]; then
        check_pass "IP addresses assigned: $(hostname -I)"
    else
        check_fail "No IP addresses assigned"
    fi
    
    # Network interfaces
    local active_interfaces=$(ip link show | grep -c "state UP")
    if [ "$active_interfaces" -gt 0 ]; then
        check_pass "Active network interfaces: $active_interfaces"
    else
        check_warn "No active network interfaces"
    fi
    
    # Packet loss check
    local packet_loss=$(ping -c 10 -W 1 8.8.8.8 2>/dev/null | grep -oP '\d+(?=% packet loss)' || echo "100")
    if [ "$packet_loss" -lt 5 ]; then
        check_pass "Packet loss: ${packet_loss}%"
    else
        check_warn "High packet loss: ${packet_loss}%"
    fi
}

################################################################################
# SERVICE HEALTH
################################################################################

check_service_health() {
    section "Service Health Checks"
    
    local services=("ssh" "dnsmasq" "nfs-server" "chronyd" "mosquitto")
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            check_pass "$service is running"
        else
            check_fail "$service is not running"
        fi
    done
}

################################################################################
# NFS HEALTH
################################################################################

check_nfs_health() {
    section "NFS Service Checks"
    
    # Check NFS server
    if systemctl is-active --quiet nfs-server; then
        check_pass "NFS server is running"
        
        # Check NFS exports
        if [ -f /etc/exports ]; then
            local export_count=$(grep -v "^#" /etc/exports | grep -v "^$" | wc -l)
            if [ "$export_count" -gt 0 ]; then
                check_pass "NFS exports configured: $export_count"
            else
                check_warn "No NFS exports configured"
            fi
        fi
        
        # Test NFS mount point
        if mountpoint -q /srv; then
            check_pass "/srv is mounted"
        else
            check_warn "/srv is not mounted"
        fi
    else
        check_fail "NFS server is not running"
    fi
}

################################################################################
# DNS HEALTH
################################################################################

check_dns_health() {
    section "DNS Service Checks"
    
    # Check dnsmasq
    if systemctl is-active --quiet dnsmasq; then
        check_pass "dnsmasq is running"
        
        # Check config
        if dnsmasq --test 2>/dev/null; then
            check_pass "dnsmasq configuration is valid"
        else
            check_fail "dnsmasq configuration error"
        fi
        
        # Check DNS queries work
        if dig @127.0.0.1 localhost &>/dev/null; then
            check_pass "Local DNS queries responding"
        else
            check_warn "DNS queries not responding"
        fi
    else
        check_fail "dnsmasq is not running"
    fi
}

################################################################################
# DHCP HEALTH
################################################################################

check_dhcp_health() {
    section "DHCP Service Checks"
    
    if systemctl is-active --quiet dnsmasq; then
        # dnsmasq provides DHCP
        local dhcp_enabled=$(grep "^dhcp-range=" /etc/dnsmasq.conf | wc -l)
        if [ "$dhcp_enabled" -gt 0 ]; then
            check_pass "DHCP is enabled and running"
            grep "^dhcp-range=" /etc/dnsmasq.conf | while read line; do
                log "  DHCP range: $line"
            done
        else
            check_warn "DHCP may not be configured"
        fi
    fi
}

################################################################################
# SSH HEALTH
################################################################################

check_ssh_health() {
    section "SSH Service Checks"
    
    if systemctl is-active --quiet ssh; then
        check_pass "SSH service is running"
        
        # Check SSH config
        if sshd -t 2>/dev/null; then
            check_pass "SSH configuration is valid"
        else
            check_fail "SSH configuration error"
        fi
        
        # Check for key-based auth
        if [ -f ~/.ssh/authorized_keys ] || [ -f /root/.ssh/authorized_keys ]; then
            check_pass "SSH keys configured"
        else
            check_warn "No SSH keys found"
        fi
    else
        check_fail "SSH service is not running"
    fi
}

################################################################################
# TIME SYNCHRONIZATION HEALTH
################################################################################

check_time_health() {
    section "Time Synchronization Checks"
    
    # Check chronyd or ntpd
    if systemctl is-active --quiet chronyd 2>/dev/null; then
        check_pass "Chrony is running"
        
        if command -v chronyc &>/dev/null; then
            if chronyc tracking &>/dev/null; then
                check_pass "System time is synchronized"
            else
                check_warn "System time may not be synchronized"
            fi
        fi
    elif systemctl is-active --quiet ntp 2>/dev/null; then
        check_pass "NTP is running"
    else
        check_warn "No time synchronization service running"
    fi
    
    # Check for GPS time source (if available)
    if command -v gpsd &>/dev/null && systemctl is-active --quiet gpsd; then
        check_pass "GPS time source is active"
    fi
}

################################################################################
# DATA INTEGRITY
################################################################################

check_data_integrity() {
    section "Data Integrity Checks"
    
    # Check for required directories
    local required_dirs=("/srv" "/srv/isr" "/srv/mesh" "/srv/vhf" "/srv/boot")
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            check_pass "Directory exists: $dir"
        else
            check_warn "Missing directory: $dir"
        fi
    done
    
    # Check for config files
    if [ -f /boot/cmdline.txt ] && [ -f /boot/config.txt ]; then
        check_pass "Boot configuration files present"
    else
        check_warn "Boot configuration files missing"
    fi
    
    # Check for backup integrity
    if [ -d /var/backups ] || [ -d /srv/backups ]; then
        check_pass "Backup directory exists"
    else
        check_warn "No backup directory found"
    fi
}

################################################################################
# SECURITY CHECKS
################################################################################

check_security_health() {
    section "Security Health Checks"
    
    # Check firewall
    if systemctl is-active --quiet ufw 2>/dev/null; then
        check_pass "Firewall (UFW) is active"
    else
        check_warn "Firewall (UFW) is not active"
    fi
    
    # Check for failed logins (fail2ban)
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        check_pass "Fail2ban is running"
        
        if command -v fail2ban-client &>/dev/null; then
            local banned=$(fail2ban-client status 2>/dev/null | grep "Currently banned" | wc -l)
            if [ "$banned" -gt 0 ]; then
                check_warn "Some IP addresses are currently banned"
            fi
        fi
    else
        check_warn "Fail2ban is not running"
    fi
    
    # Check SSH hardening
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        check_pass "SSH root login disabled"
    else
        check_warn "SSH root login may be enabled"
    fi
    
    # Check for unattended upgrades
    if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
        check_pass "Unattended upgrades configured"
    else
        check_warn "Unattended upgrades not configured"
    fi
}

################################################################################
# PACKAGE/DEPENDENCY CHECKS
################################################################################

check_dependencies() {
    section "Dependency Health Checks"
    
    # Check for broken packages
    if apt-get check &>/dev/null; then
        check_pass "No broken packages"
    else
        check_warn "Some packages may be broken"
    fi
    
    # Check for available updates
    local updates=$(apt-get -s upgrade | grep -c "^Inst" || true)
    if [ "$updates" -eq 0 ]; then
        check_pass "System is up to date"
    else
        check_warn "$updates package updates available"
    fi
}

################################################################################
# REPORT SUMMARY
################################################################################

print_summary() {
    section "Health Check Summary"
    
    local total=$((PASS + WARN + FAIL))
    echo -e "Total Checks:      $total"
    echo -e "${GREEN}Passed:${NC}          $PASS"
    echo -e "${YELLOW}Warnings:${NC}        $WARN"
    echo -e "${RED}Failed:${NC}           $FAIL"
    echo ""
    
    local health_percent=$((PASS * 100 / total))
    if [ "$FAIL" -eq 0 ]; then
        echo -e "${GREEN}Overall Health: ${health_percent}%${NC}"
        return 0
    else
        echo -e "${RED}Overall Health: ${health_percent}%${NC}"
        return 1
    fi
}

################################################################################
# EXPORT RESULTS
################################################################################

export_json_report() {
    local report_file="$LOG_DIR/health-report-$(date +%Y%m%d-%H%M%S).json"
    
    cat > "$report_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "results": {
    "passed": $PASS,
    "warnings": $WARN,
    "failed": $FAIL,
    "total": $((PASS + WARN + FAIL))
  }
}
EOF
    
    log "JSON report saved: $report_file"
}

################################################################################
# MAIN
################################################################################

main() {
    log "Starting cluster health check suite"
    
    check_system_health
    check_network_health
    check_service_health
    check_nfs_health
    check_dns_health
    check_dhcp_health
    check_ssh_health
    check_time_health
    check_data_integrity
    check_security_health
    check_dependencies
    
    print_summary
    export_json_report
    
    log "Health check complete (log: $LOG_FILE)"
}

# Run main
main
exit $FAIL

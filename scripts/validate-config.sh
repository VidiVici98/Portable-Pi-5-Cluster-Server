#!/bin/bash

################################################################################
# Configuration Validator
# Purpose: Validate configuration files before applying them
# Usage: ./scripts/validate-config.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

print_status() {
    local status=$1
    local message=$2
    
    case $status in
        PASS)
            echo -e "${GREEN}✓${NC} $message"
            ((PASS++))
            ;;
        WARN)
            echo -e "${YELLOW}⚠${NC} $message"
            ((WARN++))
            ;;
        FAIL)
            echo -e "${RED}✗${NC} $message"
            ((FAIL++))
            ;;
        INFO)
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

validate_dnsmasq() {
    echo -e "\n${BLUE}=== DNSMASQ Configuration ===${NC}"
    
    local conf="${CONFIG_DIR}/network/dnsmasq.conf"
    
    if [ ! -f "$conf" ]; then
        print_status FAIL "dnsmasq.conf not found"
        return
    fi
    
    print_status PASS "dnsmasq.conf found"
    
    # Check for required settings
    if grep -q "^dhcp-range=" "$conf"; then
        local range=$(grep "^dhcp-range=" "$conf" | head -1)
        print_status INFO "DHCP range configured: $range"
    else
        print_status WARN "No DHCP range configured"
    fi
    
    if grep -q "^interface=" "$conf"; then
        print_status PASS "Interface configured"
    else
        print_status WARN "No interface specified"
    fi
    
    if grep -q "^dhcp-boot=" "$conf"; then
        print_status PASS "PXE boot configured"
    else
        print_status WARN "PXE boot not configured"
    fi
    
    if grep -q "^enable-tftp" "$conf"; then
        print_status PASS "TFTP enabled"
    else
        print_status WARN "TFTP not enabled"
    fi
    
    if grep -q "^tftp-root=" "$conf"; then
        print_status PASS "TFTP root configured"
    else
        print_status WARN "TFTP root not configured"
    fi
    
    # Check syntax (dnsmasq can do this)
    if command -v dnsmasq &>/dev/null; then
        if dnsmasq --test --conf-file="$conf" &>/dev/null 2>&1; then
            print_status PASS "dnsmasq syntax valid"
        else
            print_status FAIL "dnsmasq syntax error"
        fi
    fi
}

validate_nfs() {
    echo -e "\n${BLUE}=== NFS Configuration ===${NC}"
    
    local exports="${CONFIG_DIR}/nfs/exports"
    
    if [ ! -f "$exports" ]; then
        print_status FAIL "NFS exports file not found"
        return
    fi
    
    print_status PASS "NFS exports file found"
    
    local export_count=$(grep -v "^#" "$exports" | grep -v "^$" | wc -l)
    print_status INFO "Active exports: $export_count"
    
    # Validate export syntax
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        # Check basic syntax (path followed by options)
        if [[ "$line" =~ ^/.*\(.*\)$ ]]; then
            print_status PASS "Valid export syntax: $line"
        else
            print_status WARN "Questionable syntax: $line"
        fi
    done < "$exports"
}

validate_chrony() {
    echo -e "\n${BLUE}=== Chrony/NTP Configuration ===${NC}"
    
    local conf="${CONFIG_DIR}/ntp/chrony/chrony.conf"
    
    if [ ! -f "$conf" ]; then
        print_status FAIL "chrony.conf not found"
        return
    fi
    
    print_status PASS "chrony.conf found"
    
    # Check for time sources
    if grep -q "^pool\|^server\|^refclock" "$conf"; then
        print_status PASS "Time sources configured"
    else
        print_status WARN "No time sources configured"
    fi
    
    # Check for GPS
    if grep -q "refclock SHM" "$conf"; then
        print_status PASS "GPS time reference configured"
    else
        print_status WARN "No GPS time reference"
    fi
}

validate_hosts() {
    echo -e "\n${BLUE}=== Hosts Configuration ===${NC}"
    
    local hosts="${CONFIG_DIR}/network/hosts"
    
    if [ ! -f "$hosts" ]; then
        print_status FAIL "hosts file not found"
        return
    fi
    
    print_status PASS "hosts file found"
    
    # Check for node entries
    local node_count=$(grep -E "192\.168" "$hosts" | grep -v "^#" | wc -l)
    print_status INFO "Node entries: $node_count"
    
    # Validate IP format
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        
        if [[ "$line" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}[[:space:]]+ ]]; then
            print_status PASS "Valid IP entry: $line"
        fi
    done < "$hosts"
}

validate_directories() {
    echo -e "\n${BLUE}=== Directory Structure ===${NC}"
    
    local dirs=(
        "/srv/tftp"
        "/srv/nfs"
        "/srv/nfs/base_os"
    )
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            print_status PASS "Directory exists: $dir"
        else
            print_status WARN "Directory missing: $dir (needed for PXE boot)"
        fi
    done
}

main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║   Configuration Validator                                      ║
║   Validates configuration before applying to system            ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    validate_dnsmasq
    validate_nfs
    validate_chrony
    validate_hosts
    validate_directories
    
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo -e "  ${GREEN}PASS: $PASS${NC}"
    echo -e "  ${YELLOW}WARN: $WARN${NC}"
    echo -e "  ${RED}FAIL: $FAIL${NC}"
    
    if [ $FAIL -eq 0 ]; then
        echo -e "\n${GREEN}✓ All configurations valid${NC}\n"
        return 0
    else
        echo -e "\n${RED}✗ Configuration issues found${NC}\n"
        return 1
    fi
}

main "$@"

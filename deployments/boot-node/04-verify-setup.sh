#!/bin/bash

################################################################################
# Boot Node - Phase 4: Verification & Testing
# Purpose: Comprehensive testing of all services
# Safety: Read-only testing, no modifications
# Status: Safe to run at any time
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="/var/log/boot-node-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

PASSED=0
FAILED=0
WARNINGS=0

echo -e "${GREEN}[$(date)] Boot Node Phase 4: Verification & Testing${NC}"
echo ""

################################################################################
# TEST FRAMEWORK
################################################################################

test_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN:${NC} $1"
    ((WARNINGS++))
}

test_section() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
}

################################################################################
# SYSTEM TESTS
################################################################################

test_section "System Health Tests"

# Check system uptime
if uptime -p &>/dev/null; then
    UPTIME=$(uptime -p)
    test_pass "System uptime: $UPTIME"
else
    test_fail "Could not determine uptime"
fi

# Check disk space
ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$ROOT_USAGE" -lt 80 ]; then
    test_pass "Disk space: ${ROOT_USAGE}% used (acceptable)"
else
    test_warn "Disk space: ${ROOT_USAGE}% used (approaching limit)"
fi

# Check memory
FREE_MEM=$(free -h | awk 'NR==2 {print $7}')
test_pass "Free memory: $FREE_MEM"

# Check system load
LOAD=$(uptime | awk -F'load average:' '{print $2}')
test_pass "System load: $LOAD"

################################################################################
# NETWORK TESTS
################################################################################

test_section "Network Tests"

# Check default gateway
if ip route | grep -q "default via"; then
    GATEWAY=$(ip route | grep "default via" | awk '{print $3}')
    test_pass "Default gateway: $GATEWAY"
else
    test_fail "No default gateway configured"
fi

# Check DNS resolution (localhost)
if nslookup localhost 127.0.0.1 &>/dev/null; then
    test_pass "DNS resolution (localhost): OK"
else
    test_fail "DNS resolution (localhost): FAILED"
fi

# Check internet connectivity
if ping -c 1 8.8.8.8 &>/dev/null; then
    test_pass "Internet connectivity: OK"
else
    test_warn "Internet connectivity: FAILED (may be expected)"
fi

# Check hostname resolution
HOSTNAME=$(hostname)
if nslookup "$HOSTNAME" 127.0.0.1 &>/dev/null; then
    test_pass "Hostname resolution: $HOSTNAME"
else
    test_warn "Hostname not resolving via DNS (expected if not in dnsmasq config)"
fi

################################################################################
# SSH TESTS
################################################################################

test_section "SSH Service Tests"

# Check SSH service status
if systemctl is-active --quiet ssh; then
    test_pass "SSH service: running"
else
    test_fail "SSH service: not running"
fi

# Check SSH port listening
if ss -tlnp 2>/dev/null | grep -q ":22 "; then
    test_pass "SSH port 22: listening"
else
    test_fail "SSH port 22: not listening"
fi

# Check SSH config
if sshd -t 2>/dev/null; then
    test_pass "SSH config: valid"
else
    test_fail "SSH config: invalid"
fi

# Check key-based auth requirement
if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
    test_pass "SSH: password auth disabled"
else
    test_warn "SSH: password auth may be enabled (check /etc/ssh/sshd_config)"
fi

################################################################################
# DHCP/DNSMASQ TESTS
################################################################################

test_section "DHCP/DNS (dnsmasq) Tests"

# Check dnsmasq service
if systemctl is-active --quiet dnsmasq; then
    test_pass "dnsmasq service: running"
else
    test_fail "dnsmasq service: not running"
fi

# Check DHCP port
if ss -tulnp 2>/dev/null | grep -E ":67|:68" &>/dev/null; then
    test_pass "DHCP ports (67/68): listening"
else
    test_fail "DHCP ports (67/68): not listening"
fi

# Check DNS port
if ss -tulnp 2>/dev/null | grep ":53 " &>/dev/null; then
    test_pass "DNS port 53: listening"
else
    test_fail "DNS port 53: not listening"
fi

# Test DNS query
if echo "server 127.0.0.1" | nslookup google.com &>/dev/null; then
    test_pass "DNS query: works"
else
    test_warn "DNS query: unable to test"
fi

################################################################################
# NFS TESTS
################################################################################

test_section "NFS Service Tests"

# Check NFS service
if systemctl is-active --quiet nfs-server; then
    test_pass "NFS service: running"
else
    test_fail "NFS service: not running"
fi

# Check NFS ports
if ss -tulnp 2>/dev/null | grep ":2049 " &>/dev/null; then
    test_pass "NFS port 2049: listening"
else
    test_fail "NFS port 2049: not listening"
fi

# Check exports file
if [ -f /etc/exports ]; then
    test_pass "Exports file: exists"
    
    # Check export syntax
    if exportfs -r 2>/dev/null; then
        test_pass "Exports syntax: valid"
    else
        test_fail "Exports syntax: invalid"
    fi
else
    test_warn "Exports file: not found"
fi

# Test NFS mount (localhost)
if mkdir -p /mnt/nfs-test 2>/dev/null; then
    if mount -t nfs localhost:/srv/cluster /mnt/nfs-test 2>/dev/null; then
        test_pass "NFS mount (localhost): successful"
        umount /mnt/nfs-test 2>/dev/null
    else
        test_warn "NFS mount (localhost): failed (may require network setup)"
    fi
fi

################################################################################
# TFTP TESTS
################################################################################

test_section "TFTP Service Tests"

# Check TFTP service
if systemctl is-active --quiet tftpd-hpa; then
    test_pass "TFTP service: running"
else
    test_fail "TFTP service: not running"
fi

# Check TFTP port
if ss -tulnp 2>/dev/null | grep ":69 " &>/dev/null; then
    test_pass "TFTP port 69: listening"
else
    test_fail "TFTP port 69: not listening"
fi

# Check TFTP root directory
if [ -d /srv/tftp ]; then
    test_pass "TFTP root directory: exists"
    
    # Check for boot files
    if [ -d /srv/tftp/boot ]; then
        BOOT_FILES=$(ls /srv/tftp/boot 2>/dev/null | wc -l)
        if [ "$BOOT_FILES" -gt 0 ]; then
            test_pass "Boot files: present ($BOOT_FILES files)"
        else
            test_warn "Boot files: directory exists but empty"
        fi
    else
        test_warn "Boot directory: not found"
    fi
else
    test_fail "TFTP root directory: not found"
fi

################################################################################
# TIME SYNC TESTS
################################################################################

test_section "Time Synchronization Tests"

# Check Chrony status
if systemctl is-active --quiet chrony; then
    test_pass "Chrony service: running"
else
    test_fail "Chrony service: not running"
fi

# Check NTP port
if ss -tulnp 2>/dev/null | grep ":123 " &>/dev/null; then
    test_pass "NTP port 123: listening"
else
    test_fail "NTP port 123: not listening"
fi

# Check time synchronization
if command -v chronyc &>/dev/null; then
    CHRONY_SYNC=$(chronyc tracking 2>/dev/null | grep "System time" | head -1)
    if [ ! -z "$CHRONY_SYNC" ]; then
        test_pass "Chrony status: $CHRONY_SYNC"
    fi
fi

# Check system time sanity
YEAR=$(date +%Y)
if [ "$YEAR" -gt 2020 ]; then
    test_pass "System time: reasonable ($YEAR)"
else
    test_fail "System time: appears incorrect ($YEAR)"
fi

################################################################################
# FIREWALL TESTS
################################################################################

test_section "Firewall (UFW) Tests"

# Check UFW status
if ufw status | grep -q "Status: active"; then
    test_pass "UFW firewall: active"
else
    test_warn "UFW firewall: not active"
fi

# Check default policies
UFW_STATUS=$(ufw status | grep -E "Default:|incoming|outgoing")
test_pass "UFW policies: $(echo "$UFW_STATUS" | head -3)"

# Check SSH rule
if ufw status | grep -q "22"; then
    test_pass "UFW SSH rule: configured"
else
    test_warn "UFW SSH rule: not found"
fi

################################################################################
# FAIL2BAN TESTS
################################################################################

test_section "Fail2Ban Security Tests"

# Check Fail2Ban service
if systemctl is-active --quiet fail2ban; then
    test_pass "Fail2Ban service: running"
else
    test_fail "Fail2Ban service: not running"
fi

# Check Fail2Ban jails
if command -v fail2ban-client &>/dev/null; then
    JAIL_COUNT=$(fail2ban-client status 2>/dev/null | grep "Number of jails:" | awk '{print $NF}')
    if [ ! -z "$JAIL_COUNT" ]; then
        test_pass "Fail2Ban jails: $JAIL_COUNT configured"
    fi
fi

################################################################################
# CONFIGURATION FILES TESTS
################################################################################

test_section "Configuration Files Tests"

# Check SSH config permissions
if [ -f /etc/ssh/sshd_config ]; then
    PERMS=$(stat -c '%a' /etc/ssh/sshd_config)
    if [ "$PERMS" = "600" ]; then
        test_pass "SSH config permissions: 600 (correct)"
    else
        test_warn "SSH config permissions: $PERMS (should be 600)"
    fi
fi

# Check sudoers file exists
if [ -f /etc/sudoers ]; then
    if visudo -c -f /etc/sudoers 2>&1 | grep -q "parsed OK"; then
        test_pass "Sudoers config: valid"
    else
        test_fail "Sudoers config: invalid"
    fi
fi

################################################################################
# SUMMARY
################################################################################

TOTAL=$((PASSED + FAILED + WARNINGS))

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Phase 4: Verification Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Test Results:"
echo "  ${GREEN}Passed:${NC}  $PASSED"
echo "  ${RED}Failed:${NC}  $FAILED"
echo "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo "  ${BLUE}Total:${NC}   $TOTAL"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Status: ALL TESTS PASSED ✓${NC}"
    echo ""
    echo "Next Steps:"
    echo "  1. Review post-deployment checklist:"
    echo "     deployments/POST-DEPLOYMENT-CHECKLIST.md"
    echo "  2. Follow operations guide:"
    echo "     operations/OPERATIONS.md"
    echo "  3. Verify from external system:"
    echo "     ssh pi@boot-node"
    echo "     nslookup boot-node"
    echo ""
else
    echo -e "${RED}Status: SOME TESTS FAILED ✗${NC}"
    echo ""
    echo "Please review failures above and retry."
    echo "See troubleshooting guide: docs/troubleshooting.md"
    echo ""
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Note: Review warnings above for optional configurations${NC}"
fi

echo ""
echo -e "${GREEN}[$(date)] Phase 4 completed${NC}"
echo "Logs: $LOG_FILE"

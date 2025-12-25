#!/bin/bash

################################################################################
# Cluster Configuration Validation & Testing Framework
#
# Purpose: Comprehensive pre-deployment testing of all cluster configurations
# Tests configuration syntax, service connectivity, permissions, and functionality
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

# Config base paths
CONFIG_BASE="${1:-.}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

################################################################################
# FUNCTIONS
################################################################################

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_section() {
    echo -e "\n${CYAN}━━━ $1 ━━━${NC}\n"
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL++))
}

################################################################################
# MAIN VALIDATION
################################################################################

print_header "Cluster Configuration Validation & Testing"

################################################################################
# SECTION 1: CONFIG FILE EXISTENCE
################################################################################

print_section "1. Configuration Files"

check_config_file() {
    local file=$1
    local desc=$2
    
    if [ -f "$file" ]; then
        test_pass "$desc exists"
        return 0
    else
        test_fail "$desc missing: $file"
        return 1
    fi
}

# Boot node configs
check_config_file "config/boot/config.txt" "Boot config (config.txt)"
check_config_file "config/boot/cmdline.txt" "Boot cmdline"
check_config_file "config/network/dnsmasq.conf" "DHCP/DNS config"
check_config_file "config/nfs/exports" "NFS exports"
check_config_file "config/nfs/nfs.conf" "NFS configuration"
check_config_file "config/ntp/chrony/chrony.conf" "NTP config"
check_config_file "config/network/hostname" "Hostname config"

# Security configs
check_config_file "config/security/sshd_config" "SSH config"
check_config_file "config/security/fail2ban.conf" "Fail2Ban config"
check_config_file "config/security/firewall.ufw" "Firewall config"
check_config_file "config/security/sysctl.conf" "Kernel hardening"

################################################################################
# SECTION 2: SYNTAX VALIDATION
################################################################################

print_section "2. Configuration Syntax Validation"

validate_dnsmasq() {
    if command -v dnsmasq &>/dev/null; then
        if dnsmasq --test -C config/network/dnsmasq.conf &>/dev/null 2>&1; then
            test_pass "dnsmasq configuration syntax valid"
        else
            test_fail "dnsmasq configuration syntax invalid"
        fi
    else
        test_warn "dnsmasq not installed (can't validate)"
    fi
}

validate_nfs_exports() {
    if [ -f "config/nfs/exports" ]; then
        # Check for valid export syntax
        if grep -E "^/.*\s+[0-9]{1,3}\.[0-9]{1,3}\." config/nfs/exports &>/dev/null; then
            test_pass "NFS exports format valid"
        else
            test_warn "NFS exports format may need review"
        fi
    fi
}

validate_sshd_config() {
    if command -v sshd &>/dev/null; then
        if sshd -t -f config/security/sshd_config &>/dev/null 2>&1; then
            test_pass "SSH configuration syntax valid"
        else
            test_fail "SSH configuration syntax invalid"
        fi
    else
        test_warn "sshd not installed (can't validate)"
    fi
}

validate_chrony_config() {
    if [ -f "config/ntp/chrony/chrony.conf" ]; then
        # Basic syntax check
        if grep -E "^(server|pool|allow|deny)" config/ntp/chrony/chrony.conf &>/dev/null; then
            test_pass "Chrony configuration format looks valid"
        else
            test_warn "Chrony configuration may need review"
        fi
    fi
}

validate_dnsmasq
validate_nfs_exports
validate_sshd_config
validate_chrony_config

################################################################################
# SECTION 3: PERMISSION CHECKS
################################################################################

print_section "3. File Permissions & Ownership"

check_permissions() {
    local file=$1
    local expected=$2
    local desc=$3
    
    if [ -f "$file" ]; then
        local actual=$(stat -c '%a' "$file")
        if [ "$actual" = "$expected" ]; then
            test_pass "$desc has correct permissions ($expected)"
        else
            test_warn "$desc has permissions $actual (expected $expected)"
        fi
    fi
}

check_permissions "config/security/sshd_config" "600" "SSH config"
check_permissions "config/nfs/exports" "644" "NFS exports"
check_permissions "config/security/fail2ban.conf" "644" "Fail2Ban config"

################################################################################
# SECTION 4: CRITICAL CONFIG VALUES
################################################################################

print_section "4. Critical Configuration Values"

validate_dnsmasq_values() {
    if [ -f "config/network/dnsmasq.conf" ]; then
        # Check DHCP range is defined
        if grep -q "dhcp-range=" config/network/dnsmasq.conf; then
            test_pass "DHCP range configured"
        else
            test_fail "DHCP range not configured in dnsmasq"
        fi
        
        # Check TFTP is configured
        if grep -q "enable-tftp" config/network/dnsmasq.conf; then
            test_pass "TFTP server enabled in dnsmasq"
        else
            test_fail "TFTP server not enabled in dnsmasq"
        fi
    fi
}

validate_nfs_shares() {
    if [ -f "config/nfs/exports" ]; then
        # Check at least one export is configured
        if [ $(grep -v "^#" config/nfs/exports | grep -c "^/") -gt 0 ]; then
            test_pass "NFS shares configured"
            local share_count=$(grep -v "^#" config/nfs/exports | grep "^/" | wc -l)
            test_pass "  Found $share_count NFS share(s)"
        else
            test_fail "No NFS shares configured"
        fi
    fi
}

validate_ssh_hardening() {
    if [ -f "config/security/sshd_config" ]; then
        # Check key-based auth
        if grep -q "^PasswordAuthentication no" config/security/sshd_config; then
            test_pass "SSH password auth disabled"
        else
            test_warn "SSH password authentication may be enabled"
        fi
        
        # Check root login disabled
        if grep -q "^PermitRootLogin no" config/security/sshd_config; then
            test_pass "SSH root login disabled"
        else
            test_warn "SSH root login may be enabled"
        fi
    fi
}

validate_dnsmasq_values
validate_nfs_shares
validate_ssh_hardening

################################################################################
# SECTION 5: NETWORK CONFIGURATION
################################################################################

print_section "5. Network Configuration"

if [ -f "config/network/hostname" ]; then
    local hostname=$(cat config/network/hostname)
    if [[ $hostname =~ ^[a-z0-9\-]+$ ]]; then
        test_pass "Hostname valid: $hostname"
    else
        test_fail "Hostname invalid format: $hostname"
    fi
else
    test_warn "Hostname not configured in config/network/hostname"
fi

if [ -f "config/network/dnsmasq.conf" ]; then
    # Check DNS servers are configured
    if grep -q "^nameserver\|^server=" config/network/dnsmasq.conf; then
        test_pass "DNS servers configured"
    else
        test_warn "DNS servers may not be configured"
    fi
fi

################################################################################
# SECTION 6: DEPLOYMENT SCRIPTS
################################################################################

print_section "6. Deployment Scripts"

check_script() {
    local script=$1
    local desc=$2
    
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            test_pass "$desc exists and is executable"
            # Basic syntax check
            if bash -n "$script" 2>/dev/null; then
                test_pass "  $desc has valid bash syntax"
            else
                test_fail "  $desc has syntax errors"
            fi
        else
            test_fail "$desc exists but is not executable"
        fi
    else
        test_fail "$desc not found"
    fi
}

check_script "deployments/boot-node/01-system-setup.sh" "Boot phase 1"
check_script "deployments/boot-node/02-install-services.sh" "Boot phase 2"
check_script "deployments/boot-node/03-configure-services.sh" "Boot phase 3"
check_script "deployments/boot-node/04-verify-setup.sh" "Boot phase 4"

check_script "deployments/node-setup/01-isr-node-setup.sh" "ISR node phase 1"
check_script "deployments/node-setup/01-mesh-node-setup.sh" "Mesh node phase 1"
check_script "deployments/node-setup/01-vhf-node-setup.sh" "VHF node phase 1"

################################################################################
# SECTION 7: AUTOMATION SCRIPTS
################################################################################

print_section "7. Automation & Maintenance Scripts"

check_script "operations/backups/backup-daily.sh" "Backup script"
check_script "operations/maintenance/health-check.sh" "Health check"
check_script "scripts/rotate-ssh-keys.sh" "SSH key rotation"
check_script "scripts/cluster-status.sh" "Cluster status"

################################################################################
# SECTION 8: DOCUMENTATION
################################################################################

print_section "8. Documentation"

check_doc() {
    local doc=$1
    local desc=$2
    
    if [ -f "$doc" ]; then
        test_pass "$desc exists"
    else
        test_fail "$desc missing"
    fi
}

check_doc "docs/INDEX.md" "Documentation index"
check_doc "docs/QUICK-START.md" "Quick start guide"
check_doc "docs/SETUP.md" "Setup guide"
check_doc "docs/HARDWARE.md" "Hardware documentation"
check_doc "docs/TROUBLESHOOTING.md" "Troubleshooting guide"
check_doc "README.md" "Project README"

################################################################################
# SECTION 9: GIT & VERSION CONTROL
################################################################################

print_section "9. Git & Version Control"

if git rev-parse --git-dir > /dev/null 2>&1; then
    test_pass "Git repository initialized"
    
    # Check .gitignore
    if [ -f ".gitignore" ]; then
        if grep -q "config/secrets" .gitignore; then
            test_pass "Secrets directory properly ignored"
        else
            test_warn "Secrets may not be properly ignored in git"
        fi
    else
        test_fail ".gitignore not found"
    fi
else
    test_warn "Not in a git repository"
fi

################################################################################
# SECTION 10: DIRECTORY STRUCTURE
################################################################################

print_section "10. Required Directory Structure"

check_dir() {
    local dir=$1
    local desc=$2
    
    if [ -d "$dir" ]; then
        test_pass "$desc directory exists"
    else
        test_fail "$desc directory missing: $dir"
    fi
}

check_dir "config" "Config"
check_dir "deployments/boot-node" "Boot node deployments"
check_dir "deployments/node-setup" "Node setup deployments"
check_dir "operations" "Operations"
check_dir "scripts" "Scripts"
check_dir "docs" "Documentation"

################################################################################
# RESULTS SUMMARY
################################################################################

print_section "VALIDATION RESULTS"

TOTAL=$((PASS + WARN + FAIL))

echo -e "  ${GREEN}✓ PASS:${NC}  $PASS"
echo -e "  ${YELLOW}⚠ WARN:${NC}  $WARN"
echo -e "  ${RED}✗ FAIL:${NC}  $FAIL"
echo -e "  ─────────────"
echo -e "  Total: $TOTAL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All critical checks passed!${NC}"
    echo "   Ready for deployment"
    exit 0
else
    echo -e "${RED}❌ $FAIL critical issue(s) found${NC}"
    echo "   Please fix failures before deployment"
    exit 1
fi

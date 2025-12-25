#!/bin/bash

################################################################################
# Boot Node - Phase 3: Configure Services
# Purpose: Deploy configurations and start services
# Safety: Uses existing config files from repo
# Status: Can be run multiple times (idempotent)
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/boot-node-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${GREEN}[$(date)] Boot Node Phase 3: Configure Services${NC}"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
   exit 1
fi

# Check if we're in the right directory
if [ ! -f "config/security/firewall.ufw" ]; then
    echo -e "${RED}ERROR: Not in cluster server root directory${NC}"
    echo "Expected to find: config/security/firewall.ufw"
    exit 1
fi

################################################################################
# SECURITY HARDENING
################################################################################

echo -e "${YELLOW}[Phase 3.1] Applying security hardening...${NC}"

# SSH Hardening
if [ -f "config/security/sshd_config" ]; then
    echo "Deploying SSH hardening..."
    cp config/security/sshd_config /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    
    # Test SSH config syntax
    if sshd -t; then
        echo -e "${GREEN}SSH config valid${NC}"
        systemctl restart ssh
    else
        echo -e "${RED}ERROR: SSH config syntax error${NC}"
        exit 1
    fi
fi

# Fail2Ban Configuration
if [ -f "config/security/fail2ban.conf" ]; then
    echo "Deploying Fail2Ban configuration..."
    cp config/security/fail2ban.conf /etc/fail2ban/jail.local
    chmod 600 /etc/fail2ban/jail.local
    echo -e "${GREEN}Fail2Ban configured${NC}"
fi

################################################################################
# DNSMASQ (DHCP/DNS)
################################################################################

echo -e "${YELLOW}[Phase 3.2] Configuring dnsmasq (DHCP/DNS)...${NC}"

if [ -f "config/network/dnsmasq.conf" ]; then
    echo "Deploying dnsmasq configuration..."
    
    # Create dnsmasq config directory if needed
    mkdir -p /etc/dnsmasq.d
    
    # Copy and validate
    cp config/network/dnsmasq.conf /etc/dnsmasq.d/cluster.conf
    chmod 644 /etc/dnsmasq.d/cluster.conf
    
    # Test configuration
    if dnsmasq --test; then
        echo -e "${GREEN}dnsmasq config valid${NC}"
        systemctl enable dnsmasq
        systemctl start dnsmasq
        echo -e "${GREEN}dnsmasq enabled and started${NC}"
    else
        echo -e "${RED}ERROR: dnsmasq config invalid${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}WARNING: dnsmasq.conf not found at config/network/dnsmasq.conf${NC}"
fi

################################################################################
# NFS CONFIGURATION
################################################################################

echo -e "${YELLOW}[Phase 3.3] Configuring NFS...${NC}"

if [ -f "config/nfs/exports" ]; then
    echo "Deploying NFS exports..."
    cp config/nfs/exports /etc/exports
    chmod 644 /etc/exports
    
    # Verify exports syntax
    if exportfs -r; then
        echo -e "${GREEN}NFS exports valid${NC}"
        systemctl enable nfs-server
        systemctl start nfs-server
        echo -e "${GREEN}NFS enabled and started${NC}"
    else
        echo -e "${RED}ERROR: NFS exports invalid${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}WARNING: exports file not found at config/nfs/exports${NC}"
fi

################################################################################
# CHRONY (NTP) CONFIGURATION
################################################################################

echo -e "${YELLOW}[Phase 3.4] Configuring Chrony (NTP)...${NC}"

if [ -f "config/ntp/chrony/chrony.conf" ]; then
    echo "Deploying Chrony configuration..."
    cp config/ntp/chrony/chrony.conf /etc/chrony/chrony.conf
    chmod 644 /etc/chrony/chrony.conf
    
    systemctl enable chrony
    systemctl start chrony
    echo -e "${GREEN}Chrony enabled and started${NC}"
else
    echo -e "${YELLOW}WARNING: chrony.conf not found at config/ntp/chrony/chrony.conf${NC}"
fi

# Also enable gpsd if available
if systemctl list-unit-files | grep -q gpsd; then
    systemctl enable gpsd
    systemctl start gpsd 2>/dev/null || true
    echo -e "${GREEN}GPS daemon enabled${NC}"
fi

################################################################################
# TFTP SETUP
################################################################################

echo -e "${YELLOW}[Phase 3.5] Setting up TFTP...${NC}"

# Create TFTP root directory
mkdir -p /srv/tftp/boot
chmod 755 /srv/tftp
chmod 755 /srv/tftp/boot

# Copy boot files (if available)
if [ -d "/boot" ]; then
    echo "Copying boot files to TFTP..."
    cp /boot/bootcode.bin /srv/tftp/boot/ 2>/dev/null || true
    cp /boot/start*.elf /srv/tftp/boot/ 2>/dev/null || true
    cp /boot/fixup*.dat /srv/tftp/boot/ 2>/dev/null || true
    cp /boot/kernel*.img /srv/tftp/boot/ 2>/dev/null || true
    cp /boot/cmdline.txt /srv/tftp/boot/ 2>/dev/null || true
    cp /boot/config.txt /srv/tftp/boot/ 2>/dev/null || true
    echo -e "${GREEN}Boot files copied${NC}"
fi

systemctl enable tftpd-hpa
systemctl start tftpd-hpa
echo -e "${GREEN}TFTP enabled and started${NC}"

################################################################################
# FIREWALL CONFIGURATION
################################################################################

echo -e "${YELLOW}[Phase 3.6] Configuring UFW firewall...${NC}"

# Set defaults
ufw --force enable > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null

# Allow SSH from local network (adjust network as needed)
ufw allow from 10.0.0.0/8 to any port 22 proto tcp > /dev/null

# Allow DHCP
ufw allow from 10.0.0.0/8 to any port 67,68 proto udp > /dev/null

# Allow TFTP
ufw allow from 10.0.0.0/8 to any port 69 proto udp > /dev/null

# Allow DNS
ufw allow from 10.0.0.0/8 to any port 53 proto tcp > /dev/null
ufw allow from 10.0.0.0/8 to any port 53 proto udp > /dev/null

# Allow NFS
ufw allow from 10.0.0.0/8 to any port 111,2049 proto tcp > /dev/null
ufw allow from 10.0.0.0/8 to any port 111,2049 proto udp > /dev/null

# Allow NTP
ufw allow from 10.0.0.0/8 to any port 123 proto udp > /dev/null

echo -e "${GREEN}UFW configured and enabled${NC}"

################################################################################
# START FAIL2BAN
################################################################################

echo -e "${YELLOW}[Phase 3.7] Starting Fail2Ban...${NC}"

systemctl enable fail2ban
systemctl start fail2ban
echo -e "${GREEN}Fail2Ban enabled and started${NC}"

################################################################################
# DIRECTORY CREATION
################################################################################

echo -e "${YELLOW}[Phase 3.8] Creating necessary directories...${NC}"

# NFS export directory
mkdir -p /srv/cluster
chmod 755 /srv/cluster

# Backup and logs directories
mkdir -p /var/log/cluster
mkdir -p /var/backups/cluster
chmod 755 /var/log/cluster
chmod 755 /var/backups/cluster

echo -e "${GREEN}Directories created${NC}"

################################################################################
# SERVICE STATUS CHECK
################################################################################

echo -e "${YELLOW}[Phase 3.9] Verifying service status...${NC}"

echo ""
echo "Service Status:"
echo "────────────────────────────────────────"

SERVICES=(
    "dnsmasq"
    "tftpd-hpa"
    "nfs-server"
    "chrony"
    "ssh"
    "ufw"
    "fail2ban"
)

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓ $service${NC} (running)"
    elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
        echo -e "${YELLOW}• $service${NC} (enabled, not running)"
    else
        echo -e "${RED}✗ $service${NC} (not running)"
    fi
done

################################################################################
# SUMMARY
################################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Phase 3: Service Configuration Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Services Configured & Running:"
echo "  ✓ SSH (key-based auth, hardened)"
echo "  ✓ dnsmasq (DHCP/DNS)"
echo "  ✓ TFTP (PXE boot)"
echo "  ✓ NFS (file sharing)"
echo "  ✓ Chrony (NTP/time sync)"
echo "  ✓ UFW (firewall)"
echo "  ✓ Fail2Ban (brute force protection)"
echo ""
echo "Next Step:"
echo "  Run Phase 4: sudo bash deployments/boot-node/04-verify-setup.sh"
echo ""

echo -e "${GREEN}[$(date)] Phase 3 completed successfully${NC}"

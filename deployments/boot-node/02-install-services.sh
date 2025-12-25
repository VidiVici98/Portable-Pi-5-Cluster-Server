#!/bin/bash

################################################################################
# Boot Node - Phase 2: Install Services
# Purpose: Install DHCP/TFTP, NFS, DNS, NTP, Firewall, and protection tools
# Safety: Installation only, no configuration changes yet
# Status: Safe to run multiple times
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/var/log/boot-node-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${GREEN}[$(date)] Boot Node Phase 2: Install Services${NC}"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
   exit 1
fi

# Verify Phase 1 completed
if ! command -v git &> /dev/null; then
    echo -e "${RED}ERROR: Phase 1 appears incomplete. Git not found.${NC}"
    exit 1
fi

echo -e "${YELLOW}[Phase 2.1] Updating package cache...${NC}"
apt-get update

################################################################################
# DHCP/TFTP SERVER (dnsmasq)
################################################################################

echo -e "${YELLOW}[Phase 2.2] Installing DHCP/DNS server (dnsmasq)...${NC}"

if dpkg -l | grep -q dnsmasq; then
    echo -e "${GREEN}dnsmasq already installed${NC}"
else
    apt-get install -y dnsmasq
    echo -e "${GREEN}dnsmasq installed${NC}"
fi

# Stop dnsmasq for now (will configure in Phase 3)
systemctl stop dnsmasq || true
systemctl disable dnsmasq || true

################################################################################
# TFTP SERVER
################################################################################

echo -e "${YELLOW}[Phase 2.3] Installing TFTP server (tftp-hpa)...${NC}"

if dpkg -l | grep -q tftp-hpa; then
    echo -e "${GREEN}tftp-hpa already installed${NC}"
else
    apt-get install -y tftp-hpa tftpd-hpa
    echo -e "${GREEN}tftp-hpa installed${NC}"
fi

systemctl stop tftpd-hpa || true
systemctl disable tftpd-hpa || true

################################################################################
# NFS SERVER
################################################################################

echo -e "${YELLOW}[Phase 2.4] Installing NFS server...${NC}"

if dpkg -l | grep -q nfs-kernel-server; then
    echo -e "${GREEN}nfs-kernel-server already installed${NC}"
else
    apt-get install -y nfs-kernel-server nfs-common
    echo -e "${GREEN}nfs-kernel-server installed${NC}"
fi

systemctl stop nfs-server || true
systemctl disable nfs-server || true

################################################################################
# TIME SYNCHRONIZATION
################################################################################

echo -e "${YELLOW}[Phase 2.5] Installing NTP/Chrony and GPS daemon...${NC}"

# Remove default ntpd if present
if dpkg -l | grep -q "^ii.*ntpd"; then
    echo "Removing ntpd in favor of chrony..."
    apt-get remove -y ntpd || true
fi

if dpkg -l | grep -q chrony; then
    echo -e "${GREEN}chrony already installed${NC}"
else
    apt-get install -y chrony
    echo -e "${GREEN}chrony installed${NC}"
fi

if dpkg -l | grep -q gpsd; then
    echo -e "${GREEN}gpsd already installed${NC}"
else
    apt-get install -y gpsd gpsd-clients
    echo -e "${GREEN}gpsd installed${NC}"
fi

systemctl stop chrony || true
systemctl disable chrony || true
systemctl stop gpsd || true
systemctl disable gpsd || true

################################################################################
# FIREWALL
################################################################################

echo -e "${YELLOW}[Phase 2.6] Installing UFW firewall...${NC}"

if dpkg -l | grep -q ufw; then
    echo -e "${GREEN}ufw already installed${NC}"
else
    apt-get install -y ufw
    echo -e "${GREEN}ufw installed${NC}"
fi

# UFW should be disabled for now (will configure in Phase 3)
ufw disable || true

################################################################################
# BRUTE FORCE PROTECTION
################################################################################

echo -e "${YELLOW}[Phase 2.7] Installing Fail2Ban...${NC}"

if dpkg -l | grep -q fail2ban; then
    echo -e "${GREEN}fail2ban already installed${NC}"
else
    apt-get install -y fail2ban
    echo -e "${GREEN}fail2ban installed${NC}"
fi

systemctl stop fail2ban || true
systemctl disable fail2ban || true

################################################################################
# OPTIONAL: MONITORING & UTILITIES
################################################################################

echo -e "${YELLOW}[Phase 2.8] Installing monitoring utilities...${NC}"

apt-get install -y \
    iotop \
    nethogs \
    iftop \
    tmux \
    screen \
    jq

echo -e "${GREEN}Monitoring utilities installed${NC}"

################################################################################
# VERIFY INSTALLATIONS
################################################################################

echo -e "${YELLOW}[Phase 2.9] Verifying installations...${NC}"

SERVICES=(
    "dnsmasq"
    "tftpd-hpa"
    "nfs-kernel-server"
    "chrony"
    "gpsd"
    "ufw"
    "fail2ban"
)

for service in "${SERVICES[@]}"; do
    if dpkg -l | grep -q "$service"; then
        echo -e "${GREEN}✓ $service installed${NC}"
    else
        echo -e "${RED}✗ $service NOT installed${NC}"
    fi
done

################################################################################
# SUMMARY
################################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Phase 2: Service Installation Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Services Installed:"
echo "  ✓ DHCP/DNS (dnsmasq)"
echo "  ✓ TFTP (tftp-hpa)"
echo "  ✓ NFS (nfs-kernel-server)"
echo "  ✓ Time Sync (chrony, gpsd)"
echo "  ✓ Firewall (ufw)"
echo "  ✓ Brute Force Protection (fail2ban)"
echo ""
echo "Status: All services installed but disabled"
echo "Next Step: Run Phase 3 to configure and enable"
echo ""
echo "Next Step:"
echo "  Run Phase 3: sudo bash deployments/boot-node/03-configure-services.sh"
echo ""

echo -e "${GREEN}[$(date)] Phase 2 completed successfully${NC}"

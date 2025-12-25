#!/bin/bash

################################################################################
# Boot Node - Phase 1: System Setup
# Purpose: Configure base OS, updates, networking, and hostname
# Safety: Non-destructive, idempotent operations only
# Status: Safe to run multiple times
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/boot-node-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${GREEN}[$(date)] Boot Node Phase 1: System Setup${NC}"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
   exit 1
fi

# Verify we're on Raspberry Pi OS
if ! grep -q "Raspbian\|Raspberry Pi OS" /etc/os-release; then
    echo -e "${YELLOW}WARNING: Not running on Raspberry Pi OS. Continuing anyway...${NC}"
fi

################################################################################
# SYSTEM UPDATES
################################################################################

echo -e "${YELLOW}[Phase 1.1] Updating system packages...${NC}"
apt-get update
apt-get upgrade -y

# Install essential tools
echo -e "${YELLOW}[Phase 1.2] Installing essential packages...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    vim \
    nano \
    htop \
    net-tools \
    iputils-ping \
    dnsutils \
    openssh-server \
    openssh-client \
    sudo \
    systemd \
    ufw

################################################################################
# HOSTNAME & LOCALE
################################################################################

echo -e "${YELLOW}[Phase 1.3] Configuring hostname and locale...${NC}"

# Check if hostname needs to be set
CURRENT_HOSTNAME=$(hostname)
DESIRED_HOSTNAME="boot-node"

if [ "$CURRENT_HOSTNAME" != "$DESIRED_HOSTNAME" ]; then
    echo "Setting hostname to $DESIRED_HOSTNAME..."
    hostnamectl set-hostname "$DESIRED_HOSTNAME"
    echo -e "${GREEN}Hostname set to: $(hostname)${NC}"
else
    echo -e "${GREEN}Hostname already set to: $CURRENT_HOSTNAME${NC}"
fi

# Set timezone (adjust if needed)
if ! timedatectl | grep -q "Europe/London\|UTC"; then
    echo "Setting timezone to UTC..."
    timedatectl set-timezone UTC
fi

echo -e "${GREEN}Timezone: $(timedatectl | grep "Time zone")${NC}"

################################################################################
# NETWORK CONFIGURATION
################################################################################

echo -e "${YELLOW}[Phase 1.4] Configuring network...${NC}"

# Check if DHCP is enabled on eth0
if grep -q "interface eth0" /etc/dhcpcd.conf 2>/dev/null; then
    echo -e "${GREEN}DHCP configuration found${NC}"
else
    echo -e "${YELLOW}No static IP configured. Reviewing current network setup...${NC}"
    ip addr show
fi

# Verify network connectivity
echo -e "${YELLOW}Testing network connectivity...${NC}"
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}Internet connectivity verified${NC}"
else
    echo -e "${YELLOW}WARNING: No internet connectivity detected${NC}"
fi

################################################################################
# KERNEL PARAMETERS & SECURITY BASELINE
################################################################################

echo -e "${YELLOW}[Phase 1.5] Applying kernel security hardening...${NC}"

# Create sysctl hardening file if not exists
if [ ! -f /etc/sysctl.d/99-hardening.conf ]; then
    echo "Applying kernel hardening parameters..."
    cp config/security/sysctl.conf /etc/sysctl.d/99-hardening.conf
    sysctl -p /etc/sysctl.d/99-hardening.conf > /dev/null
    echo -e "${GREEN}Kernel hardening applied${NC}"
else
    echo -e "${GREEN}Kernel hardening already applied${NC}"
fi

################################################################################
# FILE SYSTEM CHECKS
################################################################################

echo -e "${YELLOW}[Phase 1.6] Checking file system...${NC}"

# Check root filesystem usage
ROOT_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$ROOT_USAGE" -gt 80 ]; then
    echo -e "${YELLOW}WARNING: Root filesystem is ${ROOT_USAGE}% full${NC}"
else
    echo -e "${GREEN}Root filesystem usage: ${ROOT_USAGE}%${NC}"
fi

# Check available inodes
INODE_USAGE=$(df -i / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$INODE_USAGE" -gt 90 ]; then
    echo -e "${YELLOW}WARNING: Inodes are ${INODE_USAGE}% full${NC}"
else
    echo -e "${GREEN}Inode usage: ${INODE_USAGE}%${NC}"
fi

################################################################################
# USER & PERMISSIONS
################################################################################

echo -e "${YELLOW}[Phase 1.7] Verifying user configuration...${NC}"

# Verify pi user exists
if id "pi" &>/dev/null; then
    echo -e "${GREEN}User 'pi' exists${NC}"
    
    # Verify pi user can sudo without password
    if grep -q "pi ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/*; then
        echo -e "${GREEN}Passwordless sudo configured for pi${NC}"
    else
        echo -e "${YELLOW}WARNING: Check sudo configuration for pi user${NC}"
    fi
else
    echo -e "${RED}ERROR: User 'pi' does not exist${NC}"
    exit 1
fi

################################################################################
# SYSTEM TIME
################################################################################

echo -e "${YELLOW}[Phase 1.8] Verifying system time...${NC}"

SYSTEM_TIME=$(date)
echo "System time: $SYSTEM_TIME"

# Check if time is reasonable (not year 2000)
YEAR=$(date +%Y)
if [ "$YEAR" -lt 2020 ]; then
    echo -e "${YELLOW}WARNING: System time appears incorrect: $SYSTEM_TIME${NC}"
else
    echo -e "${GREEN}System time verified${NC}"
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Phase 1: System Setup Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "System Information:"
echo "  Hostname: $(hostname)"
echo "  Kernel: $(uname -r)"
echo "  Memory: $(free -h | awk 'NR==2 {print $2}')"
echo "  CPU Cores: $(nproc)"
echo "  Uptime: $(uptime -p)"
echo ""
echo "Next Step:"
echo "  Run Phase 2: sudo bash deployments/boot-node/02-install-services.sh"
echo ""
echo "Logs available at: $LOG_FILE"
echo ""

echo -e "${GREEN}[$(date)] Phase 1 completed successfully${NC}"

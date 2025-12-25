#!/bin/bash

################################################################################
# Mesh Node Setup - Phase 1: System Configuration
# 
# Purpose: Configure Mesh node for LoRa and Reticulum mesh networking
#
# Mesh Node Functions:
#   - LoRa communication (long-range, low bandwidth)
#   - Reticulum mesh networking protocol
#   - MQTT message relay
#   - Mesh network coordination
#   - Integration with ISR and VHF nodes
#
# Date: December 25, 2025
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/var/log/mesh-node-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

log_info "=== Mesh Node Setup Phase 1: System Configuration ==="
log_info "Starting at $(date)"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with sudo"
    exit 1
fi

# Check disk space (require 2GB free)
DISK_FREE=$(df / | awk 'NR==2 {print $4}')
if [ "$DISK_FREE" -lt 2097152 ]; then
    log_error "Insufficient disk space (need 2GB, have $(( DISK_FREE / 1024 ))MB)"
    exit 1
fi

log_info "✓ Pre-flight checks passed"

################################################################################
# SYSTEM UPDATES
################################################################################

log_info "Updating system packages..."
apt-get update || log_error "apt-get update failed"
apt-get upgrade -y || log_error "apt-get upgrade failed"

log_info "✓ System packages updated"

################################################################################
# HOSTNAME & NETWORK CONFIGURATION
################################################################################

log_info "Configuring hostname and network..."

if ! grep -q "mesh-node" /etc/hostname; then
    echo "mesh-node" > /etc/hostname
    sed -i 's/raspberrypi/mesh-node/g' /etc/hosts
    hostname mesh-node
    log_info "✓ Hostname set to: mesh-node"
else
    log_info "✓ Hostname already configured: $(hostname)"
fi

if ping -c 1 8.8.8.8 &> /dev/null; then
    log_info "✓ Internet connectivity verified"
else
    log_warn "No internet connectivity detected (may need manual network config)"
fi

################################################################################
# TIMEZONE & LOCALE
################################################################################

log_info "Configuring timezone and locale..."

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
locale-gen en_US.UTF-8 &>/dev/null || true
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 &>/dev/null || true

if command -v timedatectl &> /dev/null; then
    timedatectl set-timezone UTC
fi

log_info "✓ Locale and timezone configured"

################################################################################
# ESSENTIAL TOOLS
################################################################################

log_info "Installing essential tools..."

TOOLS=(
    "curl wget git vim nano"
    "build-essential python3-pip python3-dev"
    "htop iotop nethogs"
    "jq tmux screen"
    "i2c-tools gpio"
)

for tool_group in "${TOOLS[@]}"; do
    apt-get install -y $tool_group 2>&1 | grep -i "already\|installed" || true
done

log_info "✓ Essential tools installed"

################################################################################
# MESH NETWORKING PACKAGES
################################################################################

log_info "Installing mesh networking packages..."

MESH_PACKAGES=(
    "mosquitto mosquitto-clients"          # MQTT message broker
    "python3-rpi.gpio"                     # GPIO control
    "python3-smbus"                        # I2C interface
    "imagemagick"                          # Image processing
    "sox ffmpeg"                           # Audio processing
    "vim-common"                           # Text editing
)

for pkg in "${MESH_PACKAGES[@]}"; do
    if ! apt-get install -y "$pkg" 2>&1 | grep -q "E: Unable"; then
        log_info "  ✓ $pkg installed"
    else
        log_warn "Could not install $pkg (may not be available)"
    fi
done

log_info "✓ Mesh packages installed"

################################################################################
# PYTHON MESH NETWORKING LIBRARIES
################################################################################

log_info "Installing Python mesh libraries..."

PYTHON_MESH_PACKAGES=(
    "paho-mqtt"                  # MQTT client
    "pyserial"                   # Serial communication (for LoRa HAT)
    "adafruit-circuitpython-busio"  # Bus communication
    "requests"                   # HTTP
)

for pkg in "${PYTHON_MESH_PACKAGES[@]}"; do
    pip3 install --upgrade "$pkg" 2>&1 | tail -1 || log_warn "pip install $pkg had issues"
done

log_info "✓ Python mesh libraries installed"

################################################################################
# RETICULUM (Mesh Networking Protocol)
################################################################################

log_info "Installing Reticulum mesh networking protocol..."

# Install Reticulum from pip
pip3 install --upgrade rns 2>&1 | tail -1 || log_warn "Reticulum install had issues"

# Create Reticulum config directory
mkdir -p /etc/reticulum
mkdir -p /var/log/reticulum

log_info "✓ Reticulum installed"

################################################################################
# STORAGE & DATA DIRECTORIES
################################################################################

log_info "Setting up data directories..."

mkdir -p /srv/mesh/data
mkdir -p /srv/mesh/cache
mkdir -p /srv/mesh/logs
mkdir -p /srv/mesh/configs

chmod 755 /srv/mesh
chmod 755 /srv/mesh/{data,cache,logs,configs}

log_info "✓ Data directories created: /srv/mesh/"

################################################################################
# GPIO & I2C CONFIGURATION
################################################################################

log_info "Configuring GPIO and I2C for LoRa HAT..."

# Enable I2C in /boot/config.txt
if ! grep -q "dtparam=i2c_arm=on" /boot/config.txt 2>/dev/null; then
    echo "dtparam=i2c_arm=on" >> /boot/config.txt
    log_info "✓ I2C enabled"
else
    log_info "✓ I2C already enabled"
fi

# Enable SPI (also needed for LoRa HAT)
if ! grep -q "dtparam=spi=on" /boot/config.txt 2>/dev/null; then
    echo "dtparam=spi=on" >> /boot/config.txt
    log_info "✓ SPI enabled"
else
    log_info "✓ SPI already enabled"
fi

# Note: Actual I2C/SPI will work after reboot
log_warn "I2C/SPI enabled in config - will be active after reboot"

################################################################################
# KERNEL HARDENING
################################################################################

log_info "Applying kernel security hardening..."

cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s)

{
    echo "# Kernel hardening - Mesh Node"
    echo "kernel.randomize_va_space = 2"
    echo "kernel.unprivileged_userns_clone = 0"
    echo "net.ipv4.ip_forward = 1"                # Enable IP forwarding for mesh
    echo "net.ipv4.conf.default.rp_filter = 0"   # Allow mesh traffic
    echo "net.ipv4.conf.all.rp_filter = 0"
    echo "net.ipv4.tcp_syncookies = 1"
    echo "net.ipv6.conf.all.forwarding = 1"
} >> /etc/sysctl.conf

sysctl -p > /dev/null 2>&1 || log_warn "sysctl reload had issues"

log_info "✓ Kernel hardening applied"

################################################################################
# LORA HAT SUPPORT
################################################################################

log_info "Configuring LoRa HAT support..."

# Create directory for LoRa configurations
mkdir -p /etc/lora

# LoRa parameters file
{
    echo "# LoRa HAT Configuration"
    echo "LORA_FREQUENCY=868000000      # 868 MHz (EU ISM band)"
    echo "LORA_BANDWIDTH=125000         # 125 kHz bandwidth"
    echo "LORA_SPREADING_FACTOR=7       # SF7 (balance speed/range)"
    echo "LORA_CODING_RATE=5            # CR 4/5"
    echo "LORA_PREAMBLE_LENGTH=8"
    echo "LORA_SYNC_WORD=0x34"
} > /etc/lora/lora.conf

chmod 644 /etc/lora/lora.conf

log_info "✓ LoRa configuration file created: /etc/lora/lora.conf"

################################################################################
# SSH CONFIGURATION
################################################################################

log_info "Hardening SSH..."

if [ -f "/home/jon/Portable-Pi-5-Cluster-Server/config/security/sshd_config" ]; then
    cp /home/jon/Portable-Pi-5-Cluster-Server/config/security/sshd_config /etc/ssh/sshd_config.new
    grep -q "Port 22" /etc/ssh/sshd_config.new || echo "Port 22" >> /etc/ssh/sshd_config.new
    mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    log_info "✓ SSH hardened"
else
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

if sshd -t; then
    log_info "✓ SSH configuration valid"
fi

################################################################################
# SUMMARY
################################################################################

log_info ""
log_info "=========================================="
log_info "Phase 1: System Configuration COMPLETE"
log_info "=========================================="
log_info "Node Name: mesh-node"
log_info "Hostname: $(hostname)"
log_info "IP Address: $(hostname -I | awk '{print $1}')"
log_info ""
log_info "Mesh Networking Tools Installed:"
log_info "  • Reticulum (mesh protocol)"
log_info "  • MQTT (message relay)"
log_info "  • LoRa HAT support"
log_info "  • GPIO/I2C/SPI drivers"
log_info ""
log_info "Data Directories: /srv/mesh/"
log_info "  • data/ - Mesh data"
log_info "  • cache/ - Cached data"
log_info "  • logs/ - Operation logs"
log_info "  • configs/ - Tool configurations"
log_info ""
log_info "LoRa Configuration: /etc/lora/lora.conf"
log_info "Reticulum Config: /etc/reticulum/"
log_info ""
log_info "⚠️  IMPORTANT: Reboot required for I2C/SPI/GPIO to be active"
log_info "   After reboot: sudo reboot"
log_info ""
log_info "Log file: $LOG_FILE"
log_info "=========================================="
log_info ""
log_info "✅ Phase 1 complete! Ready for Phase 2 (service installation)"
log_info "Next: bash deployments/node-setup/02-mesh-node-services.sh"
log_info ""
log_info "Completed at $(date)"

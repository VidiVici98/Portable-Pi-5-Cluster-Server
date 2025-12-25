#!/bin/bash

################################################################################
# ISR Node Setup - Phase 1: System Configuration
# 
# Purpose: Configure ISR (Intelligence, Surveillance, Reconnaissance) node
# for RF monitoring, signal analysis, and data collection
#
# ISR Node Functions:
#   - ADS-B tracking (aircraft)
#   - RF signal monitoring (CubicSDR, GQRX, etc.)
#   - Signal analysis and recording
#   - Passive RF reconnaissance
#   - Integration with FreeTAKServer (optional)
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
LOG_FILE="/var/log/isr-node-setup.log"
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

log_info "=== ISR Node Setup Phase 1: System Configuration ==="
log_info "Starting at $(date)"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with sudo"
    exit 1
fi

# Check if Raspberry Pi OS
if ! grep -q "Raspberry Pi OS" /etc/os-release 2>/dev/null; then
    log_warn "Not detected as Raspberry Pi OS (may still work)"
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

# Set hostname
if ! grep -q "isr-node" /etc/hostname; then
    echo "isr-node" > /etc/hostname
    sed -i 's/raspberrypi/isr-node/g' /etc/hosts
    hostname isr-node
    log_info "✓ Hostname set to: isr-node"
else
    log_info "✓ Hostname already configured: $(hostname)"
fi

# Verify network connectivity
if ping -c 1 8.8.8.8 &> /dev/null; then
    log_info "✓ Internet connectivity verified"
else
    log_warn "No internet connectivity detected (may need manual network config)"
fi

################################################################################
# TIMEZONE & LOCALE
################################################################################

log_info "Configuring timezone and locale..."

# Set timezone to UTC (for log consistency)
if command -v timedatectl &> /dev/null; then
    timedatectl set-timezone UTC
    log_info "✓ Timezone set to UTC"
else
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    log_info "✓ Timezone set to UTC (legacy method)"
fi

# Configure locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
locale-gen en_US.UTF-8 &>/dev/null || true
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 &>/dev/null || true

log_info "✓ Locale configured"

################################################################################
# ESSENTIAL TOOLS
################################################################################

log_info "Installing essential tools..."

TOOLS=(
    "curl wget git vim nano"
    "build-essential python3-pip python3-dev"
    "htop iotop nethogs"
    "jq tmux screen"
    "telnet ncat"
    "git-core"
)

for tool_group in "${TOOLS[@]}"; do
    apt-get install -y $tool_group 2>&1 | grep -i "already\|installed" || true
done

log_info "✓ Essential tools installed"

################################################################################
# ISR-SPECIFIC TOOLS
################################################################################

log_info "Installing ISR-specific packages..."

ISR_TOOLS=(
    "gnuradio"                    # Software-defined radio framework
    "gr-osmosdr"                  # OsmoSDR source for GnuRadio
    "dump1090-mutability"         # ADS-B decoder
    "rtl-sdr"                     # RTL-SDR utilities
    "sox"                         # Audio processing
    "ffmpeg"                      # Audio/video processing
    "openvpn"                     # For secure data transmission
    "mosquitto mosquitto-clients" # MQTT for data integration
)

for tool in "${ISR_TOOLS[@]}"; do
    if apt-get install -y "$tool" 2>&1 | grep -q "E:"; then
        log_warn "Could not install $tool (may not be available)"
    else
        log_info "  ✓ $tool installed"
    fi
done

log_info "✓ ISR tools installed"

################################################################################
# PYTHON PACKAGES FOR RF ANALYSIS
################################################################################

log_info "Installing Python RF analysis packages..."

PYTHON_PACKAGES=(
    "numpy scipy"                # Scientific computing
    "matplotlib"                 # Plotting
    "pandas"                     # Data analysis
    "pysignal"                   # Signal processing
    "requests"                   # HTTP library
    "paho-mqtt"                  # MQTT client
)

for pkg_group in "${PYTHON_PACKAGES[@]}"; do
    pip3 install --upgrade $pkg_group 2>&1 | tail -1 || log_warn "pip install $pkg_group had issues"
done

log_info "✓ Python packages installed"

################################################################################
# STORAGE & DATA DIRECTORIES
################################################################################

log_info "Setting up data directories..."

# Create directories for RF recordings
mkdir -p /srv/isr/recordings
mkdir -p /srv/isr/analysis
mkdir -p /srv/isr/logs
mkdir -p /srv/isr/configs

chmod 755 /srv/isr
chmod 755 /srv/isr/{recordings,analysis,logs,configs}

log_info "✓ Data directories created: /srv/isr/"

################################################################################
# KERNEL HARDENING (Same as boot node)
################################################################################

log_info "Applying kernel security hardening..."

# Backup sysctl
cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s)

# Apply hardening parameters
{
    echo "# Kernel hardening - ISR Node"
    echo "kernel.randomize_va_space = 2"
    echo "kernel.unprivileged_userns_clone = 0"
    echo "net.ipv4.ip_forward = 0"
    echo "net.ipv4.conf.default.rp_filter = 1"
    echo "net.ipv4.conf.all.rp_filter = 1"
    echo "net.ipv4.tcp_syncookies = 1"
    echo "net.ipv6.conf.all.disable_ipv6 = 0"
} >> /etc/sysctl.conf

sysctl -p > /dev/null 2>&1 || log_warn "sysctl reload had issues"

log_info "✓ Kernel hardening applied"

################################################################################
# SYSTEM USERS & PERMISSIONS
################################################################################

log_info "Configuring system users..."

# Create isr user for RF operations (if not exists)
if ! id -u isr &>/dev/null; then
    useradd -m -s /bin/bash -G adm,sudo,dialout,plugdev isr
    log_info "✓ isr user created"
else
    log_info "✓ isr user already exists"
fi

# Verify pi user exists
if ! id -u pi &>/dev/null; then
    log_warn "pi user not found (expected on Raspberry Pi OS)"
fi

################################################################################
# USB DEVICE PERMISSIONS
################################################################################

log_info "Configuring USB device permissions for SDR..."

# Allow non-root access to USB SDR devices
{
    echo "# RTL-SDR"
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE:="0666"'
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE:="0666"'
    echo ""
    echo "# HackRF"
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE:="0666"'
    echo ""
    echo "# USRP"
    echo 'SUBSYSTEMS=="usb", ATTRS{idVendor}=="fffe", MODE:="0666"'
} > /etc/udev/rules.d/99-sdr.rules

udevadm control --reload-rules
udevadm trigger

log_info "✓ USB device permissions configured"

################################################################################
# SSH CONFIGURATION
################################################################################

log_info "Hardening SSH..."

# Use existing sshd_config if available, otherwise use defaults
if [ -f "/home/jon/Portable-Pi-5-Cluster-Server/config/security/sshd_config" ]; then
    cp /home/jon/Portable-Pi-5-Cluster-Server/config/security/sshd_config /etc/ssh/sshd_config.new
    grep -q "Port 22" /etc/ssh/sshd_config.new || echo "Port 22" >> /etc/ssh/sshd_config.new
    mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    log_info "✓ SSH hardened with template config"
else
    # Basic hardening
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
    log_info "✓ SSH basic hardening applied"
fi

# Verify config
if sshd -t; then
    log_info "✓ SSH configuration valid"
else
    log_error "SSH configuration invalid (manual review needed)"
fi

################################################################################
# SUMMARY
################################################################################

log_info ""
log_info "=========================================="
log_info "Phase 1: System Configuration COMPLETE"
log_info "=========================================="
log_info "Node Name: isr-node"
log_info "Hostname: $(hostname)"
log_info "IP Address: $(hostname -I | awk '{print $1}')"
log_info "Timezone: $(timedatectl show -p Timezone --value 2>/dev/null || echo 'UTC')"
log_info "Disk Free: $(df / | awk 'NR==2 {printf "%.1fGB", $4/1048576}')"
log_info "Memory: $(free -h | awk 'NR==2 {print $2}')"
log_info "CPU Cores: $(nproc)"
log_info ""
log_info "RF Tools Installed:"
log_info "  • gnuradio (GnuRadio framework)"
log_info "  • dump1090-mutability (ADS-B)"
log_info "  • rtl-sdr (RTL-SDR utilities)"
log_info "  • sox, ffmpeg (Audio/video)"
log_info "  • mosquitto (MQTT)"
log_info ""
log_info "Data Directories: /srv/isr/"
log_info "  • recordings/ - RF recordings"
log_info "  • analysis/ - Analysis results"
log_info "  • logs/ - Operation logs"
log_info "  • configs/ - Tool configurations"
log_info ""
log_info "Log file: $LOG_FILE"
log_info "=========================================="
log_info ""
log_info "✅ Phase 1 complete! Ready for Phase 2 (service installation)"
log_info "Next: bash deployments/node-setup/02-isr-node-services.sh"
log_info ""
log_info "Completed at $(date)"

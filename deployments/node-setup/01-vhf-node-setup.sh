#!/bin/bash

################################################################################
# VHF Node Setup - Phase 1: System Configuration
# 
# Purpose: Configure VHF/UHF transceiver interface node
#
# VHF Node Functions:
#   - VHF/UHF amateur radio interface
#   - Digital modes (FLdigi, JS8Call, WSJT-X)
#   - Winlink integration
#   - Voice over IP (EchoLink optional)
#   - RF gateway between digital and internet
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
LOG_FILE="/var/log/vhf-node-setup.log"
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

log_info "=== VHF Node Setup Phase 1: System Configuration ==="
log_info "Starting at $(date)"

if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run with sudo"
    exit 1
fi

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

if ! grep -q "vhf-node" /etc/hostname; then
    echo "vhf-node" > /etc/hostname
    sed -i 's/raspberrypi/vhf-node/g' /etc/hosts
    hostname vhf-node
    log_info "✓ Hostname set to: vhf-node"
else
    log_info "✓ Hostname already configured: $(hostname)"
fi

if ping -c 1 8.8.8.8 &> /dev/null; then
    log_info "✓ Internet connectivity verified"
else
    log_warn "No internet connectivity detected"
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
    "alsa-utils pulseaudio"
    "sox ffmpeg"
)

for tool_group in "${TOOLS[@]}"; do
    apt-get install -y $tool_group 2>&1 | grep -i "already\|installed" || true
done

log_info "✓ Essential tools installed"

################################################################################
# AMATEUR RADIO SOFTWARE
################################################################################

log_info "Installing amateur radio software..."

RADIO_PACKAGES=(
    "fldigi"                  # Digital modes (RTTY, PSK31, MFSK, Olivia, etc.)
    "sox"                     # Sound processing
    "ffmpeg"                  # Audio/video codec
    "direwolf"                # APRS and AX.25 packet radio
    "gpsd"                    # GPS interface
)

for pkg in "${RADIO_PACKAGES[@]}"; do
    if ! apt-get install -y "$pkg" 2>&1 | grep -q "E: Unable"; then
        log_info "  ✓ $pkg installed"
    else
        log_warn "Could not install $pkg"
    fi
done

log_info "✓ Amateur radio software installed"

################################################################################
# DIGITAL MODE SOFTWARE (Python)
################################################################################

log_info "Installing Python amateur radio libraries..."

PYTHON_RADIO_PACKAGES=(
    "paho-mqtt"               # MQTT for integration
    "pyserial"                # Serial communication
    "requests"                # HTTP
    "numpy scipy"             # DSP
)

for pkg in "${PYTHON_RADIO_PACKAGES[@]}"; do
    pip3 install --upgrade "$pkg" 2>&1 | tail -1 || log_warn "pip install $pkg had issues"
done

log_info "✓ Python libraries installed"

################################################################################
# AUDIO CONFIGURATION
################################################################################

log_info "Configuring audio subsystem..."

# Add pi user to audio group
if id -u pi &>/dev/null; then
    usermod -aG audio pi
    log_info "✓ pi user added to audio group"
fi

# Create ALSA config for consistent audio
mkdir -p /etc/asound.d

# Configure PulseAudio
mkdir -p /etc/pulse
if [ ! -f /etc/pulse/daemon.conf ]; then
    cp /etc/pulse/daemon.conf.default /etc/pulse/daemon.conf
fi

log_info "✓ Audio subsystem configured"

################################################################################
# TRANSCEIVER INTERFACE
################################################################################

log_info "Setting up transceiver interface configuration..."

# Create directory for transceiver configs
mkdir -p /etc/transceiver

# Rig configuration template
{
    echo "# Transceiver Configuration (Icom IC-7100 example)"
    echo "RIG_MODEL=3020"           # Icom IC-7100"
    echo "RIG_PORT=/dev/ttyUSB0"    # Serial port"
    echo "RIG_SPEED=19200"
    echo "RIG_DATA_BITS=8"
    echo "RIG_STOP_BITS=1"
    echo "RIG_PARITY=none"
    echo ""
    echo "# Audio configuration"
    echo "AUDIO_INPUT=default"
    echo "AUDIO_OUTPUT=default"
    echo "AUDIO_SAMPLE_RATE=48000"
} > /etc/transceiver/rig.conf

log_info "✓ Transceiver configuration template created"

################################################################################
# DATA DIRECTORIES
################################################################################

log_info "Setting up data directories..."

mkdir -p /srv/vhf/logs
mkdir -p /srv/vhf/recordings
mkdir -p /srv/vhf/configs
mkdir -p /srv/vhf/mail          # For Winlink
mkdir -p /srv/vhf/cache

chmod 755 /srv/vhf
chmod 755 /srv/vhf/{logs,recordings,configs,mail,cache}

log_info "✓ Data directories created: /srv/vhf/"

################################################################################
# KERNEL HARDENING
################################################################################

log_info "Applying kernel security hardening..."

cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s)

{
    echo "# Kernel hardening - VHF Node"
    echo "kernel.randomize_va_space = 2"
    echo "kernel.unprivileged_userns_clone = 0"
    echo "net.ipv4.ip_forward = 0"
    echo "net.ipv4.conf.default.rp_filter = 1"
    echo "net.ipv4.conf.all.rp_filter = 1"
    echo "net.ipv4.tcp_syncookies = 1"
    echo "# Allow low-level audio access"
    echo "kernel.perf_event_paranoid = 1"
} >> /etc/sysctl.conf

sysctl -p > /dev/null 2>&1 || log_warn "sysctl reload had issues"

log_info "✓ Kernel hardening applied"

################################################################################
# SERIAL DEVICE PERMISSIONS
################################################################################

log_info "Configuring serial device permissions..."

# Allow access to serial ports (for transceiver)
{
    echo "# Serial devices (transceiver interface)"
    echo 'KERNEL=="ttyUSB*", MODE="0666", GROUP="dialout"'
    echo 'KERNEL=="ttyACM*", MODE="0666", GROUP="dialout"'
} > /etc/udev/rules.d/99-serial.rules

udevadm control --reload-rules
udevadm trigger

log_info "✓ Serial device permissions configured"

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
log_info "Node Name: vhf-node"
log_info "Hostname: $(hostname)"
log_info "IP Address: $(hostname -I | awk '{print $1}')"
log_info ""
log_info "Amateur Radio Software Installed:"
log_info "  • FLdigi (digital modes)"
log_info "  • Direwolf (APRS/packet)"
log_info "  • Audio subsystem (ALSA/PulseAudio)"
log_info "  • Serial device drivers"
log_info ""
log_info "Supported Digital Modes:"
log_info "  • RTTY, PSK31, MFSK, Olivia"
log_info "  • Hellschreiber, MT63, Dominoex"
log_info "  • Throb, Contestia, Opera"
log_info ""
log_info "Data Directories: /srv/vhf/"
log_info "  • logs/ - Operation logs"
log_info "  • recordings/ - Audio recordings"
log_info "  • configs/ - Application configs"
log_info "  • mail/ - Winlink messages"
log_info ""
log_info "Transceiver Config: /etc/transceiver/rig.conf"
log_info "USB Serial Devices: /dev/ttyUSB* (enabled)"
log_info ""
log_info "Log file: $LOG_FILE"
log_info "=========================================="
log_info ""
log_info "✅ Phase 1 complete! Ready for Phase 2 (service installation)"
log_info "Next: bash deployments/node-setup/02-vhf-node-setup.sh"
log_info ""
log_info "Completed at $(date)"

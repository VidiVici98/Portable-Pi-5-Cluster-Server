#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 1: Base System Bootstrap
#
# Purpose:
#   Prepare ISR node OS, security baseline, users, and filesystem layout.
#
# This phase intentionally DOES NOT install:
#   - dump1090 / dump978
#   - SDR applications
#   - Dashboard services
#
# Those are handled by dedicated scripts invoked by the orchestrator.
################################################################################

LOG_TAG="[ISR-SETUP]"
LOG_FILE="/var/log/isr-node-setup.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT
################################################################################

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }
log "Starting ISR Phase 1 bootstrap"

################################################################################
# SYSTEM UPDATE
################################################################################

log "Updating base system"
apt-get update -y
apt-get upgrade -y

################################################################################
# HOSTNAME
################################################################################

if [[ "$(hostname)" != "isr-node" ]]; then
  log "Setting hostname to isr-node"
  echo "isr-node" > /etc/hostname
  sed -i 's/127.0.1.1.*/127.0.1.1 isr-node/' /etc/hosts || true
  hostname isr-node
fi

################################################################################
# TIME / LOCALE
################################################################################

log "Configuring timezone and locale"
timedatectl set-timezone UTC || true
locale-gen en_US.UTF-8 || true
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true

################################################################################
# BASE PACKAGES (NO APPLICATIONS)
################################################################################

log "Installing base utilities"
apt-get install -y \
  curl wget git \
  vim nano \
  htop tmux screen \
  jq \
  usbutils \
  ca-certificates

################################################################################
# USERS & GROUPS
################################################################################

if ! id isr &>/dev/null; then
  log "Creating isr user"
  useradd -m -s /bin/bash -G sudo,dialout,plugdev isr
fi

################################################################################
# DIRECTORY LAYOUT
################################################################################

log "Creating ISR filesystem layout"
mkdir -p /srv/isr/{recordings,analysis,logs,configs}
chmod 755 /srv/isr
chmod 755 /srv/isr/*

################################################################################
# KERNEL HARDENING
################################################################################

log "Applying sysctl hardening"
cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s)

cat >> /etc/sysctl.conf <<'EOF'

# ISR Node Hardening
kernel.randomize_va_space = 2
kernel.unprivileged_userns_clone = 0
net.ipv4.ip_forward = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF

sysctl -p || true

################################################################################
# USB SDR RULES
################################################################################

log "Installing SDR udev rules"
cat > /etc/udev/rules.d/99-sdr.rules <<'EOF'
# RTL-SDR
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE="0666"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", MODE="0666"
# HackRF
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="6089", MODE="0666"
EOF

udevadm control --reload-rules
udevadm trigger

################################################################################
# SSH HARDENING (CONFIG STAGED, NOT HARD-CODED)
################################################################################

log "Hardening SSH"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
grep -q '^PubkeyAuthentication' /etc/ssh/sshd_config || \
  echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

sshd -t && systemctl reload ssh

################################################################################
# COMPLETE
################################################################################

log "ISR Phase 1 bootstrap complete"
log "Next steps:"
log " - install_adsb_uat.sh"
log " - ISR service deployment"
log " - Firewall application"

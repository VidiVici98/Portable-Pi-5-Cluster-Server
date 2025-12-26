#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 5: Security & Firewall
#
# Purpose:
#   Harden the ISR node, enable firewall, fail2ban, SSH hardening,
#   and expose only essential services for cluster and dashboard integration.
################################################################################

LOG_TAG="[ISR-SEC]"
LOG_FILE="/var/log/isr-node-security.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"; }

log "Starting ISR Phase 5 security hardening"

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }

# ---- Firewall rules ----
log "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing

# Allow ADS-B HTTP
ufw allow 80/tcp

# Allow UAT port
ufw allow 30978/tcp

# Allow MQTT
ufw allow 1883/tcp

# Allow SSH
ufw allow 22/tcp

ufw --force enable
log "✓ Firewall rules applied"

# ---- Fail2ban ----
log "Ensuring fail2ban is enabled..."
systemctl enable fail2ban
systemctl restart fail2ban
log "✓ Fail2ban active"

# ---- SSH Hardening ----
log "Applying SSH hardening..."
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
log "✓ SSH hardening applied"

log "ISR Phase 5 security complete"

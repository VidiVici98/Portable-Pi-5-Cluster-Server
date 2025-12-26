#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 3: Node Configuration
#
# Purpose:
#   Apply ISR-specific configuration for RF frameworks, ADS-B/UAT,
#   directories, overlays, and system integration.
################################################################################

LOG_TAG="[ISR-CONFIG]"
LOG_FILE="/var/log/isr-node-config.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

log "Starting ISR Phase 3 node configuration"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }

if ! id -u isr &>/dev/null; then
    log "ERROR: User 'isr' not found. Run Phase 1 first."
    exit 1
fi

################################################################################
# OVERLAY / CONFIGURATION FILES
################################################################################

log "Applying configuration overlays..."

CONFIG_BASE="/srv/isr/configs"
OVERLAY_DIR="/home/jon/Portable-Pi-5-Cluster-Server/config/overlays/isr-node"

# Ensure base config directories exist
mkdir -p "$CONFIG_BASE"
mkdir -p "$CONFIG_BASE/logs"
mkdir -p "$CONFIG_BASE/recordings"
mkdir -p "$CONFIG_BASE/analysis"

# Copy overlay configs if available
if [ -d "$OVERLAY_DIR" ]; then
    cp -r "$OVERLAY_DIR/"* "$CONFIG_BASE/"
    log "✓ Applied overlay configuration from $OVERLAY_DIR"
else
    log "WARN: Overlay directory $OVERLAY_DIR not found, skipping"
fi

################################################################################
# NTP CONFIGURATION
################################################################################

log "Configuring NTP for time sync..."

if command -v timedatectl &>/dev/null; then
    timedatectl set-ntp true
    log "✓ NTP enabled via timedatectl"
fi

# Copy chrony or ntpd config if exists
NTP_CONFIG_SRC="/home/jon/Portable-Pi-5-Cluster-Server/config/ntp/chrony/chrony.conf"
if [ -f "$NTP_CONFIG_SRC" ]; then
    cp "$NTP_CONFIG_SRC" /etc/chrony/chrony.conf
    systemctl restart chrony
    systemctl enable chrony
    log "✓ Chrony configuration applied"
else
    log "WARN: NTP config $NTP_CONFIG_SRC not found"
fi

################################################################################
# SYSTEMD SERVICE CONFIGURATION
################################################################################

log "Configuring ISR services..."

# dump1090
if [ -f "/etc/systemd/system/dump1090.service" ]; then
    systemctl daemon-reload
    systemctl enable dump1090
    systemctl restart dump1090
    log "✓ dump1090 service enabled and restarted"
else
    log "WARN: dump1090 systemd service not found"
fi

# dump978
if [ -f "/etc/systemd/system/dump978.service" ]; then
    systemctl daemon-reload
    systemctl enable dump978
    systemctl restart dump978
    log "✓ dump978 service enabled and restarted"
else
    log "WARN: dump978 systemd service not found"
fi

# Mosquitto
systemctl enable mosquitto
systemctl restart mosquitto
log "✓ Mosquitto service enabled and restarted"

################################################################################
# PERMISSIONS AND OWNERSHIP
################################################################################

log "Setting file and directory permissions..."

chown -R isr:isr /srv/isr
chmod -R 750 /srv/isr
chmod -R 755 /srv/isr/{recordings,analysis,logs}

log "✓ Permissions set for ISR directories"

################################################################################
# FIREWALL CONFIGURATION (PLACEHOLDER)
################################################################################

log "Phase 3 does not apply firewall yet — handled by deployment coordinator"

################################################################################
# BASIC HEALTH CHECKS
################################################################################

log "Performing basic post-config validation..."

command -v rtl_test >/dev/null || log "WARN: rtl_test not found"
command -v gnuradio-companion >/dev/null || log "WARN: gnuradio-companion missing"
systemctl is-active dump1090 >/dev/null || log "WARN: dump1090 not active"
systemctl is-active dump978 >/dev/null || log "WARN: dump978 not active"
systemctl is-active mosquitto >/dev/null || log "WARN: mosquitto not active"

################################################################################
# COMPLETE
################################################################################

log "ISR Phase 3 configuration complete"
log "Next steps:"
log " - Phase 4 verification (validate services and endpoints)"
log " - Cluster integration via deployment coordinator"

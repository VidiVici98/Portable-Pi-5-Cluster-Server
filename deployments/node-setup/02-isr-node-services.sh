#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 2: ISR Services & RF Frameworks
#
# Purpose:
#   Install ISR-related services and frameworks required for
#   RF monitoring, data transport, and downstream analysis.
#
# Explicitly EXCLUDES:
#   - ADS-B / UAT ingestion (handled separately)
#   - Web dashboards
#   - Firewall rules
################################################################################

LOG_TAG="[ISR-SVC]"
LOG_FILE="/var/log/isr-node-services.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT
################################################################################

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }
log "Starting ISR Phase 2 service installation"

################################################################################
# CORE RF FRAMEWORKS
################################################################################

log "Installing RF frameworks and utilities"

apt-get install -y \
  rtl-sdr \
  librtlsdr-dev \
  gnuradio \
  gr-osmosdr \
  soapysdr-tools \
  sox \
  ffmpeg

################################################################################
# MESSAGE TRANSPORT (MQTT)
################################################################################

log "Installing MQTT broker and client tools"

apt-get install -y \
  mosquitto \
  mosquitto-clients

systemctl enable mosquitto
systemctl restart mosquitto

################################################################################
# PYTHON RUNTIME (ISR ANALYSIS)
################################################################################

log "Installing Python runtime dependencies"

apt-get install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-numpy \
  python3-scipy \
  python3-matplotlib \
  python3-pandas

pip3 install --upgrade \
  requests \
  paho-mqtt \
  psutil

################################################################################
# RTL-SDR KERNEL PREP
################################################################################

log "Blacklisting DVB driver for RTL-SDR"

cat > /etc/modprobe.d/rtl-sdr-blacklist.conf <<'EOF'
blacklist dvb_usb_rtl28xxu
EOF

################################################################################
# ISR SERVICE USER CONTEXT
################################################################################

log "Ensuring isr user owns ISR directories"
chown -R isr:isr /srv/isr

################################################################################
# BASIC HEALTH CHECKS
################################################################################

log "Validating installations"

command -v rtl_test >/dev/null || log "WARN: rtl_test not found"
command -v gnuradio-companion >/dev/null || log "WARN: gnuradio not fully installed"
systemctl is-active mosquitto >/dev/null || log "WARN: mosquitto not active"

################################################################################
# COMPLETE
################################################################################

log "ISR Phase 2 services installed"
log "Next steps:"
log " - install_adsb_uat.sh (ADS-B / UAT ingestion)"
log " - Firewall rules application"
log " - Dashboard integration"

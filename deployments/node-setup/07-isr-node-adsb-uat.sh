#!/usr/bin/env bash
set -euo pipefail

############################################
# ADS-B / UAT INSTALL SCRIPT (ISR NODE)
#
# Purpose:
#   - Install and configure dump1090 (1090 MHz)
#   - Install and configure dump978 (978 MHz UAT)
#   - Expose JSON endpoints for central dashboard
#   - Prepares for dashboard integration
#
# Scope:
#   - ISR node only
#   - Non-interactive
#   - Orchestrator-safe
############################################

LOG_TAG="[ADSB-UAT]"
LOG_FILE="/var/log/install_adsb_uat.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

############################################
# STEP 1 — SANITY CHECKS
############################################

[[ "${EUID}" -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }
command -v apt-get >/dev/null || { log "ERROR: apt-get not found (Debian/Ubuntu required)"; exit 1; }
uname -s | grep -qi linux || { log "ERROR: Linux required"; exit 1; }

############################################
# STEP 2 — VARIABLES & PATHS
############################################

INSTALL_ROOT="/opt"
SRC_DUMP1090="${INSTALL_ROOT}/dump1090-src"
SRC_DUMP978="${INSTALL_ROOT}/dump978-src"

BIN_DUMP1090="/usr/local/bin/dump1090"
BIN_DUMP978="/usr/local/bin/dump978"

LIGHTTPD_CONF="/etc/lighttpd/conf-available/99-adsb.conf"

############################################
# STEP 3 — SYSTEM UPDATE & DEPENDENCIES
############################################

log "Updating package lists..."
apt-get update -y

log "Upgrading installed packages..."
apt-get upgrade -y

log "Installing required dependencies..."
apt-get install -y --no-install-recommends \
  git build-essential cmake pkg-config rtl-sdr librtlsdr-dev \
  lighttpd curl jq

############################################
# STEP 4 — RTL-SDR KERNEL MODULE BLACKLIST
############################################

log "Blacklisting DVB kernel module for RTL-SDR..."
cat >/etc/modprobe.d/rtl-sdr-blacklist.conf <<EOF
# Required for RTL-SDR access
blacklist dvb_usb_rtl28xxu
EOF

############################################
# STEP 5 — dump1090 (ADS-B 1090 MHz)
############################################

if [[ ! -x "${BIN_DUMP1090}" ]]; then
  log "Installing dump1090..."
  rm -rf "${SRC_DUMP1090}"
  git clone https://github.com/flightaware/dump1090.git "${SRC_DUMP1090}"
  pushd "${SRC_DUMP1090}" >/dev/null
  make
  make install
  popd >/dev/null
else
  log "dump1090 already installed, skipping build."
fi

############################################
# STEP 6 — dump978 (UAT 978 MHz)
############################################

if [[ ! -x "${BIN_DUMP978}" ]]; then
  log "Installing dump978..."
  rm -rf "${SRC_DUMP978}"
  git clone https://github.com/flightaware/dump978.git "${SRC_DUMP978}"
  mkdir -p "${SRC_DUMP978}/build"
  pushd "${SRC_DUMP978}/build" >/dev/null
  cmake ..
  make
  make install
  popd >/dev/null
else
  log "dump978 already installed, skipping build."
fi

############################################
# STEP 7 — LIGHTTPD CONFIGURATION
############################################

log "Configuring lighttpd for ADS-B/UAT endpoints..."
cat >"${LIGHTTPD_CONF}" <<EOF
server.modules += ( "mod_alias", "mod_setenv" )

alias.url += (
  "/dump1090/" => "/usr/local/share/dump1090/html/",
  "/dump978/"  => "/usr/local/share/dump978/html/"
)

setenv.add-response-header += (
  "Access-Control-Allow-Origin" => "*"
)
EOF

ln -sf "${LIGHTTPD_CONF}" /etc/lighttpd/conf-enabled/99-adsb.conf
systemctl enable lighttpd
systemctl restart lighttpd

############################################
# STEP 8 — SYSTEMD SERVICES
############################################

log "Creating systemd service for dump1090..."
cat >/etc/systemd/system/dump1090.service <<EOF
[Unit]
Description=ADS-B Receiver (dump1090)
After=network.target

[Service]
ExecStart=${BIN_DUMP1090} --net --quiet
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

log "Creating systemd service for dump978..."
cat >/etc/systemd/system/dump978.service <<EOF
[Unit]
Description=UAT Receiver (dump978)
After=network.target

[Service]
ExecStart=${BIN_DUMP978} --json-port 30978
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

############################################
# STEP 9 — ENABLE & START SERVICES
############################################

log "Reloading systemd and enabling services..."
systemctl daemon-reexec
systemctl daemon-reload

systemctl enable dump1090 dump978
systemctl restart dump1090 dump978

############################################
# STEP 10 — VERIFICATION
############################################

log "Verifying service states..."
for svc in dump1090 dump978 lighttpd; do
  if ! systemctl is-active --quiet $svc; then
    log "ERROR: $svc is not running"
    exit 1
  fi
done

############################################
# STEP 11 — DASHBOARD INTEGRATION NOTES
############################################

log "Preparing endpoints for dashboard integration..."
log "ADS-B JSON : http://<ISR_NODE_IP>/dump1090/data/aircraft.json"
log "UAT  JSON  : http://<ISR_NODE_IP>:30978/data/aircraft.json"
log "Ensure the dashboard can access these URLs and pull updates regularly."

############################################
# COMPLETE
############################################

log "ADS-B / UAT installation complete"
log "Reboot recommended before first SDR use."

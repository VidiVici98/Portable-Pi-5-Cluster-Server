#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node ADS-B / UAT Ingestion
#
# Purpose:
#   Install and configure ADS-B (1090 MHz) and UAT (978 MHz) receivers
#   on the ISR node. Integrates with Lighttpd for JSON output.
#
# Requirements:
#   Must be run as root
#   RTL-SDR USB devices connected
################################################################################

LOG_TAG="[ADSB-UAT]"
LOG_FILE="/var/log/install_adsb_uat.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"; }

log "Starting ADS-B / UAT installation"

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }

INSTALL_DIR="/opt"
DUMP1090_DIR="$INSTALL_DIR/dump1090"
DUMP978_DIR="$INSTALL_DIR/dump978"

# ---- System Update ----
log "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# ---- Core dependencies ----
log "Installing core dependencies..."
apt-get install -y git build-essential cmake pkg-config rtl-sdr librtlsdr-dev lighttpd curl jq

# ---- Blacklist DVB driver (required for RTL-SDR) ----
log "Blacklisting DVB kernel module..."
cat >/etc/modprobe.d/rtl-sdr-blacklist.conf <<EOF
blacklist dvb_usb_rtl28xxu
EOF

# ---- dump1090 Installation ----
if [[ ! -d "$DUMP1090_DIR" ]]; then
    log "Installing dump1090..."
    git clone https://github.com/flightaware/dump1090.git "$DUMP1090_DIR"
    cd "$DUMP1090_DIR"
    make
    make install
else
    log "dump1090 already installed"
fi

# ---- dump978 Installation ----
if [[ ! -d "$DUMP978_DIR" ]]; then
    log "Installing dump978..."
    git clone https://github.com/flightaware/dump978.git "$DUMP978_DIR"
    cd "$DUMP978_DIR"
    mkdir -p build
    cd build
    cmake ..
    make
    make install
else
    log "dump978 already installed"
fi

# ---- Lighttpd Configuration ----
log "Configuring Lighttpd for JSON access..."
cat >/etc/lighttpd/conf-available/99-adsb.conf <<EOF
server.modules += ( "mod_alias", "mod_setenv" )

alias.url += (
  "/dump1090/" => "/usr/local/share/dump1090/html/",
  "/dump978/"  => "/usr/local/share/dump978/html/"
)

setenv.add-response-header += (
  "Access-Control-Allow-Origin" => "*"
)
EOF

ln -sf /etc/lighttpd/conf-available/99-adsb.conf /etc/lighttpd/conf-enabled/
systemctl restart lighttpd
systemctl enable lighttpd

# ---- Systemd Services ----
log "Creating systemd services..."

# dump1090
cat >/etc/systemd/system/dump1090.service <<EOF
[Unit]
Description=ADS-B Receiver (dump1090)
After=network.target

[Service]
ExecStart=/usr/local/bin/dump1090 --net --quiet
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# dump978
cat >/etc/systemd/system/dump978.service <<EOF
[Unit]
Description=UAT Receiver (dump978)
After=network.target

[Service]
ExecStart=/usr/local/bin/dump978 --json-port 30978
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ---- Enable & start services ----
log "Enabling and starting ADS-B / UAT services..."
systemctl daemon-reload
systemctl enable dump1090 dump978
systemctl restart dump1090 dump978

# ---- Verification ----
log "Verifying services..."
systemctl is-active dump1090
systemctl is-active dump978
systemctl is-active lighttpd

log "ADS-B / UAT installation complete"
log "Endpoints:"
log "  ADS-B JSON : http://<ISR_IP>/dump1090/data/aircraft.json"
log "  UAT  JSON  : http://<ISR_IP>:30978/data/aircraft.json"
log "Reboot recommended before first use."

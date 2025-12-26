#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 4: Verification
#
# Purpose:
#   Validate ISR node installation, services, and endpoints.
#   Ensure ADS-B / UAT ingestion is running and RF frameworks are functional.
################################################################################

LOG_TAG="[ISR-VERIFY]"
LOG_FILE="/var/log/isr-node-verify.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

log "Starting ISR Phase 4 verification"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }

if ! id -u isr &>/dev/null; then
    log "ERROR: User 'isr' not found. Run Phase 1 first."
    exit 1
fi

################################################################################
# SERVICE STATUS CHECKS
################################################################################

log "Checking core ISR services..."

SERVICES=("dump1090" "dump978" "mosquitto")

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        log "✓ Service $svc is active"
    else
        log "WARN: Service $svc is NOT active"
    fi
done

################################################################################
# ENDPOINT VALIDATION
################################################################################

log "Validating ADS-B / UAT endpoints..."

DUMP1090_URL="http://localhost/dump1090/data/aircraft.json"
DUMP978_URL="http://localhost:30978/data/aircraft.json"

for url in "$DUMP1090_URL" "$DUMP978_URL"; do
    if curl --silent --fail "$url" >/dev/null; then
        log "✓ Endpoint reachable: $url"
    else
        log "WARN: Endpoint not responding: $url"
    fi
done

################################################################################
# RF HARDWARE CHECK
################################################################################

log "Testing RTL-SDR devices..."

if command -v rtl_test &>/dev/null; then
    rtl_test -t | tee -a "$LOG_FILE" || log "WARN: rtl_test failed or no SDR devices connected"
else
    log "WARN: rtl_test command not found"
fi

################################################################################
# GNURADIO CHECK
################################################################################

log "Testing GNURadio installation..."

if command -v gnuradio-companion &>/dev/null; then
    log "✓ GNURadio companion available"
else
    log "WARN: gnuradio-companion not found"
fi

################################################################################
# MQTT BROKER CHECK
################################################################################

log "Checking Mosquitto MQTT broker..."

if systemctl is-active --quiet mosquitto; then
    log "✓ Mosquitto broker running"
else
    log "WARN: Mosquitto broker not running"
fi

################################################################################
# SUMMARY
################################################################################

log "ISR Phase 4 verification complete"
log "Next steps:"
log " - Ensure cluster integration via deployment coordinator"
log " - Apply firewall & security hardening if not done"

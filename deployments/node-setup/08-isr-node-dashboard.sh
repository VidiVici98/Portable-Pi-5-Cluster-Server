#!/usr/bin/env bash
set -euo pipefail

################################################################################
# ISR Node Setup — Phase 08: ADS-B / UAT Dashboard Integration
#
# Purpose:
#   - Connect ISR node ADS-B and UAT feeds to the dashboard
#   - Support DEMO_MODE (offline development)
#   - Enable production mode (live JSON endpoints)
#   - Prepare stub page for tools.html dashboard
################################################################################

LOG_TAG="[ISR-DASH]"
LOG_FILE="/var/log/isr-node-dashboard.log"
mkdir -p "$(dirname "$LOG_FILE")"

DEMO_MODE=${DEMO_MODE:-true}  # Default to demo mode
DASHBOARD_DIR="/srv/isr/dashboard"
DEMO_DATA_DIR="$DASHBOARD_DIR/demo_data"
TOOLS_HTML="$DASHBOARD_DIR/templates/tools.html"

log() {
    echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT
################################################################################

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }
log "Starting ISR Phase 08: Dashboard Integration"

mkdir -p "$DASHBOARD_DIR"
mkdir -p "$DEMO_DATA_DIR"
mkdir -p "$(dirname "$TOOLS_HTML")"

################################################################################
# STEP 1 — DEMO DATA SETUP
################################################################################

if [ "$DEMO_MODE" = true ]; then
    log "Setting up demo JSON files for ADS-B and UAT"

    cat > "$DEMO_DATA_DIR/adsb_aircraft.json" <<'EOF'
{
  "aircraft": [
    {"hex":"A1B2C3","flight":"TEST01","lat":37.7749,"lon":-122.4194,"altitude":1200,"spd":250},
    {"hex":"D4E5F6","flight":"TEST02","lat":34.0522,"lon":-118.2437,"altitude":3000,"spd":300}
  ]
}
EOF

    cat > "$DEMO_DATA_DIR/uat_aircraft.json" <<'EOF'
{
  "aircraft": [
    {"hex":"U1V2W3","flight":"UAT01","lat":40.7128,"lon":-74.0060,"altitude":1500,"spd":200},
    {"hex":"X4Y5Z6","flight":"UAT02","lat":41.8781,"lon":-87.6298,"altitude":2800,"spd":220}
  ]
}
EOF

    log "Demo JSON files created in $DEMO_DATA_DIR"
fi

################################################################################
# STEP 2 — BACKEND API CONFIGURATION
################################################################################

API_PY="$DASHBOARD_DIR/app.py"

if [ ! -f "$API_PY" ]; then
    log "Creating app.py backend stub for dashboard integration"

    cat > "$API_PY" <<'EOF'
#!/usr/bin/env python3
import os
import json
from flask import Flask, jsonify

app = Flask(__name__)
DEMO_MODE = os.environ.get("DEMO_MODE", "true").lower() == "true"
DASHBOARD_DIR = os.path.dirname(os.path.abspath(__file__))
DEMO_DATA_DIR = os.path.join(DASHBOARD_DIR, "demo_data")

@app.route("/api/adsb")
def adsb():
    if DEMO_MODE:
        with open(os.path.join(DEMO_DATA_DIR, "adsb_aircraft.json")) as f:
            data = json.load(f)
    else:
        # In production, fetch from ISR node
        import requests
        resp = requests.get("http://127.0.0.1/dump1090/data/aircraft.json")
        data = resp.json()
    return jsonify(data)

@app.route("/api/uat")
def uat():
    if DEMO_MODE:
        with open(os.path.join(DEMO_DATA_DIR, "uat_aircraft.json")) as f:
            data = json.load(f)
    else:
        import requests
        resp = requests.get("http://127.0.0.1:30978/data/aircraft.json")
        data = resp.json()
    return jsonify(data)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
EOF

    chmod +x "$API_PY"
    log "app.py created at $API_PY"
fi

################################################################################
# STEP 3 — TOOLS.HTML STUB
################################################################################

if [ ! -f "$TOOLS_HTML" ]; then
    log "Creating tools.html stub for dashboard"

    cat > "$TOOLS_HTML" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>ISR Dashboard Tools</title>
</head>
<body>
    <h1>ISR Node Dashboard Tools</h1>
    <h2>ADS-B Aircraft</h2>
    <pre id="adsb"></pre>
    <h2>UAT Aircraft</h2>
    <pre id="uat"></pre>

    <script>
        async function fetchData(endpoint, elementId){
            const res = await fetch(endpoint);
            const data = await res.json();
            document.getElementById(elementId).textContent = JSON.stringify(data, null, 2);
        }
        fetchData("/api/adsb", "adsb");
        fetchData("/api/uat", "uat");
    </script>
</body>
</html>
EOF

    log "tools.html stub created at $TOOLS_HTML"
fi

################################################################################
# STEP 4 — SYSTEMD SERVICE FOR DASHBOARD
################################################################################

DASHBOARD_SERVICE="/etc/systemd/system/isr-dashboard.service"

if [ ! -f "$DASHBOARD_SERVICE" ]; then
    log "Creating systemd service for dashboard"

    cat > "$DASHBOARD_SERVICE" <<EOF
[Unit]
Description=ISR Dashboard Service
After=network.target

[Service]
User=isr
WorkingDirectory=$DASHBOARD_DIR
ExecStart=/usr/bin/env python3 $API_PY
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable isr-dashboard
    systemctl restart isr-dashboard
    log "Dashboard service enabled and started"
fi

################################################################################
# COMPLETE
################################################################################

log "ISR Phase 08 dashboard integration complete"
log "Access dashboard at http://<ISR_NODE_IP>:8080"
log "Demo mode is ${DEMO_MODE}"

#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Centralized Firewall Deployment Script
#
# Purpose:
#   Apply standardized UFW firewall rules from repo config
#   based on node role (boot / isr / mesh / vhf)
#
# Source of Truth:
#   config/security/firewall.ufw
################################################################################

LOG_TAG="[FIREWALL]"
LOG_FILE="/var/log/firewall-deploy.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
  echo "$(date '+%F %T') $LOG_TAG $*" | tee -a "$LOG_FILE"
}

[[ $EUID -eq 0 ]] || { log "ERROR: Must run as root"; exit 1; }

ROLE="${1:-}"

if [[ -z "$ROLE" ]]; then
  log "ERROR: Node role required (boot|isr|mesh|vhf)"
  exit 1
fi

CONFIG_SRC="/home/pi/Portable-Pi-5-Cluster-Server/config/security/firewall.ufw"

if [[ ! -f "$CONFIG_SRC" ]]; then
  log "ERROR: firewall.ufw not found at $CONFIG_SRC"
  exit 1
fi

log "Applying firewall for role: $ROLE"

################################################################################
# BASELINE RESET
################################################################################

log "Resetting UFW to clean state"
ufw --force reset

################################################################################
# BASELINE POLICIES
################################################################################

log "Applying baseline policies"
ufw default deny incoming
ufw default allow outgoing

################################################################################
# SSH (ALL NODES)
################################################################################

ufw allow from 192.168.0.0/16 to any port 22 proto tcp
log "SSH allowed from LAN"

################################################################################
# ROLE-SPECIFIC RULES
################################################################################

case "$ROLE" in
  boot)
    log "Applying BOOT node rules"

    # DHCP / TFTP
    ufw allow from 192.168.0.0/16 to any port 67 proto udp
    ufw allow from 192.168.0.0/16 to any port 69 proto udp

    # DNS
    ufw allow from 192.168.0.0/16 to any port 53

    # NFS
    ufw allow from 192.168.0.0/16 to any port 2049

    # Dashboard
    ufw allow from 192.168.0.0/16 to any port 5000 proto tcp
    ;;
  
  isr)
    log "Applying ISR node rules"

    # ADS-B / UAT
    ufw allow from 192.168.0.0/16 to any port 8080 proto tcp
    ufw allow from 192.168.0.0/16 to any port 30978 proto tcp

    # MQTT
    ufw allow from 192.168.0.0/16 to any port 1883 proto tcp
    ;;
  
  mesh)
    log "Applying MESH node rules"

    # Mesh protocols (example)
    ufw allow from 192.168.0.0/16 to any port 698 proto udp
    ufw allow from 192.168.0.0/16 to any port 4305 proto udp
    ;;
  
  vhf)
    log "Applying VHF node rules"

    # SDR / control (placeholder)
    ufw allow from 192.168.0.0/16 to any port 7355 proto tcp
    ;;
  
  *)
    log "ERROR: Unknown role: $ROLE"
    exit 1
    ;;
esac

################################################################################
# ENABLE & VERIFY
################################################################################

log "Enabling firewall"
ufw --force enable

log "Firewall status:"
ufw status verbose | tee -a "$LOG_FILE"

log "Firewall deployment complete for role: $ROLE"

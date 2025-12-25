#!/bin/bash

################################################################################
# Health Check Script
# Purpose: Daily system health and security monitoring
# Schedule: Can run hourly or daily to monitor cluster health
# Usage: ./operations/maintenance/health-check.sh [quiet]
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
QUIET=${1:-}  # Run silently if "quiet" is passed

# Logging
LOG_FILE="operations/logs/health-check.log"
mkdir -p operations/logs

# Function to log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to output (unless quiet mode)
output() {
    if [ -z "$QUIET" ]; then
        echo "$1"
    fi
    log "$1"
}

################################################################################
# SYSTEM HEALTH
################################################################################

check_system_health() {
    output ""
    output "${BLUE}=== System Health ===${NC}"
    
    # Memory
    MEM_TOTAL=$(free -h | awk 'NR==2 {print $2}')
    MEM_USED=$(free -h | awk 'NR==2 {print $3}')
    MEM_PERCENT=$(free | awk 'NR==2 {printf "%d", ($3/$2)*100}')
    
    if [ "$MEM_PERCENT" -gt 80 ]; then
        output "${RED}✗ Memory: ${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}% - HIGH)${NC}"
    elif [ "$MEM_PERCENT" -gt 60 ]; then
        output "${YELLOW}⚠ Memory: ${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}%)${NC}"
    else
        output "${GREEN}✓ Memory: ${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}%)${NC}"
    fi
    
    # Disk
    DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [ "$DISK_PERCENT" -gt 90 ]; then
        output "${RED}✗ Disk: ${DISK_PERCENT}% used (CRITICAL)${NC}"
    elif [ "$DISK_PERCENT" -gt 80 ]; then
        output "${YELLOW}⚠ Disk: ${DISK_PERCENT}% used (HIGH)${NC}"
    else
        output "${GREEN}✓ Disk: ${DISK_PERCENT}% used${NC}"
    fi
    
    # Load
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    CPU_COUNT=$(nproc)
    
    output "${GREEN}✓ Load: $LOAD (CPU cores: $CPU_COUNT)${NC}"
    
    # Temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP_C=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
        
        if [ "$TEMP_C" -gt 80 ]; then
            output "${RED}✗ Temperature: ${TEMP_C}°C (HIGH)${NC}"
        elif [ "$TEMP_C" -gt 70 ]; then
            output "${YELLOW}⚠ Temperature: ${TEMP_C}°C (ELEVATED)${NC}"
        else
            output "${GREEN}✓ Temperature: ${TEMP_C}°C${NC}"
        fi
    fi
}

################################################################################
# SERVICE STATUS
################################################################################

check_services() {
    output ""
    output "${BLUE}=== Service Status ===${NC}"
    
    SERVICES=(
        "ssh"
        "dnsmasq"
        "nfs-server"
        "tftpd-hpa"
        "chrony"
        "ufw"
        "fail2ban"
    )
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            output "${GREEN}✓ $service${NC} (running)"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            output "${YELLOW}⚠ $service${NC} (enabled, not running)"
        else
            output "${RED}✗ $service${NC} (not active)"
        fi
    done
}

################################################################################
# NETWORK STATUS
################################################################################

check_network() {
    output ""
    output "${BLUE}=== Network Status ===${NC}"
    
    # Check gateway
    if ip route | grep -q "default via"; then
        GATEWAY=$(ip route | grep "default via" | awk '{print $3}')
        
        if ping -c 1 "$GATEWAY" &>/dev/null; then
            output "${GREEN}✓ Gateway: $GATEWAY (reachable)${NC}"
        else
            output "${YELLOW}⚠ Gateway: $GATEWAY (not responding)${NC}"
        fi
    else
        output "${RED}✗ No default gateway${NC}"
    fi
    
    # Check DNS
    if nslookup localhost 127.0.0.1 &>/dev/null; then
        output "${GREEN}✓ DNS: localhost resolves${NC}"
    else
        output "${RED}✗ DNS: resolution failed${NC}"
    fi
    
    # Check IPv4/IPv6
    if ip -4 addr show | grep -q "inet "; then
        output "${GREEN}✓ IPv4: active${NC}"
    else
        output "${YELLOW}⚠ IPv4: not active${NC}"
    fi
}

################################################################################
# SECURITY STATUS
################################################################################

check_security() {
    output ""
    output "${BLUE}=== Security Status ===${NC}"
    
    # SSH key permissions
    if [ -f ~/.ssh/id_rsa ]; then
        PERMS=$(stat -c '%a' ~/.ssh/id_rsa 2>/dev/null || stat -f '%A' ~/.ssh/id_rsa 2>/dev/null)
        
        if [ "$PERMS" = "600" ] || [ "$PERMS" = "-rw-------" ]; then
            output "${GREEN}✓ SSH key permissions: correct (600)${NC}"
        else
            output "${RED}✗ SSH key permissions: $PERMS (should be 600)${NC}"
        fi
    fi
    
    # Firewall status
    if ufw status | grep -q "Status: active"; then
        output "${GREEN}✓ Firewall: active${NC}"
    else
        output "${YELLOW}⚠ Firewall: inactive${NC}"
    fi
    
    # Fail2Ban jails
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        JAILS=$(fail2ban-client status 2>/dev/null | grep "Number of jails:" | awk '{print $NF}')
        output "${GREEN}✓ Fail2Ban: $JAILS jail(s) active${NC}"
        
        # Check SSH jail specifically
        if fail2ban-client status sshd 2>/dev/null | grep -q "Currently banned:"; then
            BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned:" | awk '{print $NF}')
            if [ "$BANNED" -gt 0 ]; then
                output "${YELLOW}⚠ Fail2Ban SSH: $BANNED IP(s) currently banned${NC}"
            fi
        fi
    fi
    
    # Check for failed SSH attempts
    if command -v journalctl &>/dev/null; then
        FAILED_LOGINS=$(journalctl -u ssh -S "1 hour ago" 2>/dev/null | grep -c "Failed password" || echo 0)
        
        if [ "$FAILED_LOGINS" -gt 5 ]; then
            output "${YELLOW}⚠ SSH: $FAILED_LOGINS failed login attempts in last hour${NC}"
        elif [ "$FAILED_LOGINS" -gt 0 ]; then
            output "${GREEN}✓ SSH: $FAILED_LOGINS failed login attempt(s) detected${NC}"
        fi
    fi
}

################################################################################
# PORT STATUS
################################################################################

check_ports() {
    output ""
    output "${BLUE}=== Open Ports ===${NC}"
    
    PORTS=(
        "22:SSH"
        "53:DNS"
        "67:DHCP"
        "69:TFTP"
        "123:NTP"
        "2049:NFS"
    )
    
    for port_info in "${PORTS[@]}"; do
        PORT=$(echo "$port_info" | cut -d: -f1)
        NAME=$(echo "$port_info" | cut -d: -f2)
        
        if ss -tulnp 2>/dev/null | grep -E ":$PORT " &>/dev/null; then
            output "${GREEN}✓ Port $PORT/$NAME: listening${NC}"
        else
            output "${YELLOW}⚠ Port $PORT/$NAME: not listening${NC}"
        fi
    done
}

################################################################################
# LOG WARNINGS
################################################################################

check_logs() {
    output ""
    output "${BLUE}=== Recent Errors/Warnings ===${NC}"
    
    # Check for critical errors in last hour
    if command -v journalctl &>/dev/null; then
        ERROR_COUNT=$(journalctl -p err -S "1 hour ago" 2>/dev/null | wc -l)
        WARNING_COUNT=$(journalctl -p warning -S "1 hour ago" 2>/dev/null | wc -l)
        
        if [ "$ERROR_COUNT" -gt 0 ]; then
            output "${YELLOW}⚠ Errors in last hour: $ERROR_COUNT${NC}"
            log "Recent errors detected. Run: journalctl -p err -S '1 hour ago'"
        else
            output "${GREEN}✓ No errors in last hour${NC}"
        fi
        
        if [ "$WARNING_COUNT" -gt 5 ]; then
            output "${YELLOW}⚠ Warnings in last hour: $WARNING_COUNT${NC}"
        else
            output "${GREEN}✓ Warnings in last hour: $WARNING_COUNT${NC}"
        fi
    fi
}

################################################################################
# NFS STATUS
################################################################################

check_nfs() {
    output ""
    output "${BLUE}=== NFS Status ===${NC}"
    
    # Check NFS service
    if systemctl is-active --quiet nfs-server 2>/dev/null; then
        output "${GREEN}✓ NFS service: running${NC}"
        
        # Check exports
        EXPORT_COUNT=$(exportfs -s 2>/dev/null | wc -l)
        output "${GREEN}✓ NFS exports: $EXPORT_COUNT configured${NC}"
    else
        output "${YELLOW}⚠ NFS service: not running${NC}"
    fi
}

################################################################################
# BACKUP STATUS
################################################################################

check_backup() {
    output ""
    output "${BLUE}=== Backup Status ===${NC}"
    
    if [ -d "operations/backups" ]; then
        LATEST_BACKUP=$(ls -t operations/backups/*.tar.gz 2>/dev/null | head -1)
        
        if [ ! -z "$LATEST_BACKUP" ]; then
            BACKUP_AGE=$(($(date +%s) - $(stat -c %Y "$LATEST_BACKUP" 2>/dev/null || stat -f %m "$LATEST_BACKUP")))
            BACKUP_HOURS=$((BACKUP_AGE / 3600))
            BACKUP_SIZE=$(ls -lh "$LATEST_BACKUP" | awk '{print $5}')
            
            if [ "$BACKUP_HOURS" -lt 25 ]; then
                output "${GREEN}✓ Latest backup: $BACKUP_HOURS hours old (${BACKUP_SIZE})${NC}"
            else
                output "${YELLOW}⚠ Latest backup: $BACKUP_HOURS hours old (should be daily)${NC}"
            fi
        else
            output "${YELLOW}⚠ No backups found${NC}"
        fi
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################

if [ -z "$QUIET" ]; then
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo "${BLUE}Boot Node Health Check - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════${NC}"
fi

log "=== Health Check Started ==="

check_system_health
check_services
check_network
check_security
check_ports
check_nfs
check_backup
check_logs

if [ -z "$QUIET" ]; then
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo "${GREEN}Health check complete${NC}"
    echo "${BLUE}Log: $LOG_FILE${NC}"
    echo "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
fi

log "=== Health Check Completed ==="

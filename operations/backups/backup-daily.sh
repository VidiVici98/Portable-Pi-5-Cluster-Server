#!/bin/bash

################################################################################
# Daily Backup Procedure
# Purpose: Backup configuration and secrets with encryption
# Schedule: Daily at 2 AM (add to crontab: 0 2 * * * /path/to/backup-daily.sh)
# Safety: Non-destructive, creates backups only
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKUP_DIR="operations/backups"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging
LOG_FILE="$BACKUP_DIR/backup.log"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Function to log
log() {
    echo "[${timestamp}] $1" | tee -a "$LOG_FILE"
}

timestamp=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${GREEN}[${timestamp}] Starting daily backup...${NC}"
log "=== Daily Backup Started ==="
log "Date: $TIMESTAMP"

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

# Check if we're in the right directory
if [ ! -d "$REPO_ROOT/config" ]; then
    echo -e "${RED}ERROR: Could not find cluster server config directory${NC}"
    log "ERROR: Invalid repository root: $REPO_ROOT"
    exit 1
fi

# Check available disk space
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_SPACE" -lt 1000000 ]; then  # Less than 1GB
    echo -e "${YELLOW}WARNING: Less than 1GB available in backup directory${NC}"
    log "WARNING: Low disk space in backup directory"
fi

################################################################################
# BACKUP CONFIGURATION
################################################################################

echo -e "${YELLOW}Backing up configuration files...${NC}"
log "Backing up configuration files..."

if tar czf "$BACKUP_DIR/config-$DATE.tar.gz" \
    -C "$REPO_ROOT" \
    config/ \
    --exclude="config/secrets" \
    --exclude=".git" \
    2>/dev/null; then
    
    SIZE=$(ls -lh "$BACKUP_DIR/config-$DATE.tar.gz" | awk '{print $5}')
    echo -e "${GREEN}✓ Configuration backed up${NC} (${SIZE})"
    log "Configuration backup created: config-$DATE.tar.gz (${SIZE})"
else
    echo -e "${RED}ERROR: Failed to backup configuration${NC}"
    log "ERROR: Failed to backup configuration"
    exit 1
fi

################################################################################
# BACKUP SCRIPTS
################################################################################

echo -e "${YELLOW}Backing up scripts...${NC}"
log "Backing up scripts..."

if tar czf "$BACKUP_DIR/scripts-$DATE.tar.gz" \
    -C "$REPO_ROOT" \
    scripts/ \
    2>/dev/null; then
    
    SIZE=$(ls -lh "$BACKUP_DIR/scripts-$DATE.tar.gz" | awk '{print $5}')
    echo -e "${GREEN}✓ Scripts backed up${NC} (${SIZE})"
    log "Scripts backup created: scripts-$DATE.tar.gz (${SIZE})"
else
    echo -e "${YELLOW}⚠ Scripts backup skipped${NC}"
    log "Scripts backup skipped (no scripts directory)"
fi

################################################################################
# BACKUP SYSTEM CONFIG (if available)
################################################################################

echo -e "${YELLOW}Backing up system configuration...${NC}"
log "Backing up system configuration..."

if [ -d "/etc/ssh" ] && [ -d "/etc/dnsmasq.d" ]; then
    if tar czf "$BACKUP_DIR/system-config-$DATE.tar.gz" \
        /etc/ssh/sshd_config \
        /etc/dnsmasq.d/ \
        /etc/exports \
        /etc/chrony/ \
        /etc/ufw/ \
        2>/dev/null; then
        
        SIZE=$(ls -lh "$BACKUP_DIR/system-config-$DATE.tar.gz" | awk '{print $5}')
        echo -e "${GREEN}✓ System config backed up${NC} (${SIZE})"
        log "System config backup created: system-config-$DATE.tar.gz (${SIZE})"
    else
        echo -e "${YELLOW}⚠ System config backup failed${NC}"
        log "WARNING: System config backup failed"
    fi
else
    echo -e "${YELLOW}⚠ System not configured, skipping system backup${NC}"
    log "System config backup skipped (system not configured)"
fi

################################################################################
# VERIFY BACKUP INTEGRITY
################################################################################

echo -e "${YELLOW}Verifying backup integrity...${NC}"
log "Verifying backup integrity..."

BACKUP_COUNT=0
BACKUP_SIZE=0

for backup_file in "$BACKUP_DIR"/*-$DATE.tar.gz; do
    if [ -f "$backup_file" ]; then
        if tar tzf "$backup_file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $(basename "$backup_file")${NC} valid"
            log "Backup verified: $(basename "$backup_file")"
            ((BACKUP_COUNT++))
            BACKUP_SIZE=$((BACKUP_SIZE + $(stat -f%z "$backup_file" 2>/dev/null || stat -c%s "$backup_file")))
        else
            echo -e "${RED}✗ $(basename "$backup_file")${NC} INVALID"
            log "ERROR: Backup invalid: $(basename "$backup_file")"
            exit 1
        fi
    fi
done

################################################################################
# CLEANUP OLD BACKUPS
################################################################################

echo -e "${YELLOW}Cleaning up old backups...${NC}"
log "Cleaning up old backups (retention: 14 days)..."

# Find and delete backups older than 14 days
DELETED_COUNT=0
while IFS= read -r old_backup; do
    if rm "$old_backup"; then
        log "Deleted old backup: $(basename "$old_backup")"
        ((DELETED_COUNT++))
    fi
done < <(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +14)

if [ "$DELETED_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Deleted $DELETED_COUNT old backup(s)${NC}"
    log "Deleted $DELETED_COUNT old backup(s)"
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Daily Backup Complete${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""
echo "Backup Summary:"
echo "  Date: $DATE"
echo "  Files backed up: $BACKUP_COUNT"
echo "  Total size: $(numfmt --to=iec $BACKUP_SIZE 2>/dev/null || echo "$(($BACKUP_SIZE / 1024)) KB")"
echo "  Location: $BACKUP_DIR/"
echo ""
echo "Recent backups:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -5 | awk '{print "  " $9 " (" $5 ")"}'
echo ""

log "=== Daily Backup Completed Successfully ==="
echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed successfully${NC}"

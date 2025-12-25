#!/bin/bash

################################################################################
# Cluster Backup & Restore Manager
#
# Purpose: Comprehensive backup, restoration, and disaster recovery tool
# Handles config backups, system state snapshots, and full restoration
#
# Date: December 25, 2025
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directories
BACKUP_BASE="${BACKUP_BASE:-.operations/backups}"
BACKUP_DIR="$BACKUP_BASE/archive"
LOG_DIR="$BACKUP_BASE/logs"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/backup-restore-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# FUNCTIONS
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

################################################################################
# BACKUP FUNCTIONS
################################################################################

backup_configs() {
    log "Backing up configuration files..."
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/configs-$timestamp.tar.gz"
    
    if tar czf "$backup_file" \
        --exclude='secrets' \
        --exclude='.git' \
        --exclude='*.log' \
        config/ 2>&1 | tail -1; then
        
        success "Configs backed up: $backup_file"
        echo "$backup_file"
    else
        error "Failed to backup configs"
    fi
}

backup_system_state() {
    log "Backing up system state..."
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/system-state-$timestamp.tar.gz"
    
    # Backup critical system configs
    if tar czf "$backup_file" \
        /etc/hostname \
        /etc/hosts \
        /etc/ssh/sshd_config \
        /etc/dnsmasq.d/ \
        /etc/exports \
        /etc/ufw/ \
        /etc/fail2ban/ \
        /etc/sysctl.d/ \
        2>/dev/null; then
        
        success "System state backed up: $backup_file"
        echo "$backup_file"
    else
        warn "Some system files could not be backed up (may require root)"
    fi
}

backup_applications() {
    log "Backing up application data..."
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/applications-$timestamp.tar.gz"
    
    if tar czf "$backup_file" \
        --exclude='*.log' \
        /srv/ \
        2>/dev/null; then
        
        success "Application data backed up: $backup_file"
        echo "$backup_file"
    else
        warn "Some application data could not be backed up"
    fi
}

backup_database() {
    log "Backing up database (if exists)..."
    
    if [ -d "/var/lib/sqlite3" ] || [ -d "/var/lib/postgresql" ]; then
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local backup_file="$BACKUP_DIR/database-$timestamp.tar.gz"
        
        if tar czf "$backup_file" \
            /var/lib/sqlite3/ \
            /var/lib/postgresql/ \
            2>/dev/null; then
            
            success "Database backed up: $backup_file"
            echo "$backup_file"
        fi
    else
        log "No database found to backup"
    fi
}

create_full_backup() {
    log ""
    log "======================================"
    log "Creating Full System Backup"
    log "======================================"
    
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_manifest="$BACKUP_DIR/backup-manifest-$timestamp.txt"
    
    echo "Backup Manifest - $timestamp" > "$backup_manifest"
    echo "Hostname: $(hostname)" >> "$backup_manifest"
    echo "User: $(whoami)" >> "$backup_manifest"
    echo "Kernel: $(uname -r)" >> "$backup_manifest"
    echo "" >> "$backup_manifest"
    echo "Backup Components:" >> "$backup_manifest"
    
    # Run all backups and log to manifest
    backup_configs >> "$backup_manifest" 2>&1 || true
    backup_system_state >> "$backup_manifest" 2>&1 || true
    backup_applications >> "$backup_manifest" 2>&1 || true
    backup_database >> "$backup_manifest" 2>&1 || true
    
    success "Full backup complete!"
    log "Backup manifest: $backup_manifest"
    
    # List all backups
    log ""
    log "Backup files created:"
    ls -lh "$BACKUP_DIR"/ | tail -10
}

################################################################################
# RESTORE FUNCTIONS
################################################################################

list_backups() {
    echo -e "${BLUE}Available Backups:${NC}"
    echo ""
    ls -lh "$BACKUP_DIR"/ | grep -E "\.tar\.gz$" | tail -10 || echo "No backups found"
}

restore_configs() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
    fi
    
    log "Restoring configurations from: $backup_file"
    
    # Create backup of current config
    local current_backup="config-before-restore-$(date +%s).tar.gz"
    tar czf "$current_backup" config/ 2>/dev/null || true
    success "Current config backed up to: $current_backup"
    
    # Restore
    if tar xzf "$backup_file" -C .; then
        success "Configurations restored"
    else
        error "Failed to restore configurations"
    fi
}

restore_system_state() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
    fi
    
    if [ "$EUID" -ne 0 ]; then
        error "System state restoration requires root/sudo"
    fi
    
    log "Restoring system state from: $backup_file"
    
    # Restore to root
    if tar xzf "$backup_file" -C /; then
        success "System state restored"
        
        # Reload services if needed
        log "Reloading services..."
        systemctl daemon-reload 2>/dev/null || true
        
        success "Services reloaded"
    else
        error "Failed to restore system state"
    fi
}

restore_all() {
    log ""
    log "======================================"
    log "DISASTER RECOVERY: Full Restore"
    log "======================================"
    log ""
    
    list_backups
    
    echo -e "${YELLOW}⚠ WARNING: This will restore ALL configurations${NC}"
    read -p "Enter backup file basename to restore (e.g., 'configs-20251225-120000'): " backup_basename
    
    # Find matching backup files
    local config_backup="$BACKUP_DIR/${backup_basename}-configs*.tar.gz"
    local state_backup="$BACKUP_DIR/${backup_basename}-system-state*.tar.gz"
    local app_backup="$BACKUP_DIR/${backup_basename}-applications*.tar.gz"
    
    if [ -f "$config_backup" ]; then
        restore_configs "$config_backup"
    fi
    
    if [ -f "$state_backup" ] && [ "$EUID" -eq 0 ]; then
        restore_system_state "$state_backup"
    fi
    
    if [ -f "$app_backup" ]; then
        log "Application data restore available: $app_backup"
        read -p "Restore application data? (y/n): " restore_apps
        if [[ $restore_apps == "y" ]]; then
            if tar xzf "$app_backup" -C /; then
                success "Application data restored"
            fi
        fi
    fi
    
    success "Restore complete!"
}

################################################################################
# VERIFICATION & MAINTENANCE
################################################################################

verify_backup() {
    local backup_file=$1
    
    log "Verifying backup: $(basename $backup_file)"
    
    if tar tzf "$backup_file" &>/dev/null; then
        success "Backup integrity verified"
        
        # Show contents
        log ""
        log "Backup contents:"
        tar tzf "$backup_file" | head -20
        
        return 0
    else
        error "Backup is corrupted"
    fi
}

cleanup_old_backups() {
    log "Cleaning up backups older than $1 days..."
    
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime "+$1" -delete
    success "Cleanup complete"
}

show_backup_stats() {
    echo -e "${BLUE}Backup Statistics:${NC}"
    echo ""
    echo "Total backups: $(ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null | wc -l)"
    echo "Total size: $(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)"
    echo "Oldest backup: $(ls -1tr $BACKUP_DIR/*.tar.gz 2>/dev/null | head -1 | xargs basename)"
    echo "Newest backup: $(ls -1tr $BACKUP_DIR/*.tar.gz 2>/dev/null | tail -1 | xargs basename)"
}

################################################################################
# MAIN
################################################################################

print_usage() {
    cat << EOF
${BLUE}Cluster Backup & Restore Manager${NC}

Usage: $0 [command] [options]

Commands:
  create      Create full system backup
  backup      Create specific backup (configs, state, apps, db)
  list        List available backups
  restore     Interactive full restore
  verify      Verify backup integrity
  cleanup     Remove old backups
  stats       Show backup statistics

Examples:
  $0 create                   # Create full backup
  $0 list                     # List available backups
  $0 verify path/to/backup.tar.gz
  $0 cleanup 30               # Remove backups older than 30 days
  $0 stats                    # Show backup usage

EOF
    exit 1
}

if [ $# -lt 1 ]; then
    print_usage
fi

case "$1" in
    create)
        create_full_backup
        ;;
    backup)
        if [ -n "$2" ]; then
            case "$2" in
                configs) backup_configs ;;
                state) backup_system_state ;;
                apps) backup_applications ;;
                db) backup_database ;;
                *) error "Unknown backup type: $2" ;;
            esac
        else
            create_full_backup
        fi
        ;;
    list)
        list_backups
        ;;
    restore)
        if [ "$EUID" -ne 0 ]; then
            warn "Some restore operations require sudo"
        fi
        restore_all
        ;;
    verify)
        if [ -z "$2" ]; then
            error "Usage: $0 verify <backup-file>"
        fi
        verify_backup "$2"
        ;;
    cleanup)
        if [ -z "$2" ]; then
            error "Usage: $0 cleanup <days>"
        fi
        cleanup_old_backups "$2"
        ;;
    stats)
        show_backup_stats
        ;;
    *)
        error "Unknown command: $1"
        ;;
esac

log "Operation complete"

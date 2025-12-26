#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Automated Cluster Deployment Coordinator
#
# Purpose: End-to-end automated deployment of entire cluster
# Orchestrates boot node setup, validation, worker node deployment, security, 
# performance baseline, and backups.
#
# Date: December 25, 2025
################################################################################

# ------------------------------
# Colors
# ------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------
# Paths
# ------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")/deployments"
LOG_DIR="/var/log/deployment"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deployment-$(date +%Y%m%d-%H%M%S).log"

# ------------------------------
# Node Definitions
# ------------------------------
declare -A NODES=(
    [boot]="192.168.1.10"
    [isr]="192.168.1.20"
    [mesh]="192.168.1.30"
    [vhf]="192.168.1.40"
)

# ------------------------------
# Logging Functions
# ------------------------------
log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"; }
section() { echo -e "\n${BLUE}=== $* ===${NC}\n" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"; }
warning() { echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"; }
progress() { echo -e "${CYAN}→${NC} $*" | tee -a "$LOG_FILE"; }

# ------------------------------
# Pre-flight Checks
# ------------------------------
check_prerequisites() {
    section "Pre-Flight Checks"

    [[ $EUID -eq 0 ]] || warning "Not running as root - some operations may fail"

    local required_scripts=("validate-all-configs.sh" "performance-monitor.sh" \
        "health-check-all.sh" "cluster-orchestrator.sh")
    
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$SCRIPT_DIR/$script" ]; then
            error "Missing required script: $script"
            return 1
        else
            success "Found: $script"
        fi
    done

    if [ ! -d "$DEPLOY_DIR" ]; then
        error "Deployment directory missing: $DEPLOY_DIR"
        return 1
    else
        success "Deployment directory exists: $DEPLOY_DIR"
    fi

    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        success "Internet connectivity OK"
    else
        warning "No internet connectivity - offline mode"
    fi
}

# ------------------------------
# Configuration Validation
# ------------------------------
validate_configuration() {
    section "Configuration Validation"
    progress "Running comprehensive validation..."
    bash "$SCRIPT_DIR/validate-all-configs.sh" 2>&1 | tee -a "$LOG_FILE" && success "Config valid"
}

# ------------------------------
# Boot Node Deployment
# ------------------------------
deploy_boot_node() {
    local phase=${1:-all}
    section "Boot Node Deployment - Phase: $phase"

    for p in 1 2 3 4; do
        if [[ "$phase" == "$p" || "$phase" == "all" ]]; then
            local script="$DEPLOY_DIR/0${p}-boot-node-$(case $p in 1)setup;;2)services;;3)config;;4)verify;;esac.sh"
            if [ -f "$script" ]; then
                progress "Executing $script"
                bash "$script" 2>&1 | tee -a "$LOG_FILE"
                success "Boot node phase $p deployed"
            else
                warning "Boot node phase $p script missing: $script"
            fi
        fi
    done
}

# ------------------------------
# Worker Node Deployment
# ------------------------------
deploy_node_type() {
    local node=$1
    section "Deploying $node node"

    local script="$DEPLOY_DIR/node-setup/01-${node}-node-setup.sh"
    if [ -f "$script" ]; then
        progress "Executing $script"
        bash "$script" 2>&1 | tee -a "$LOG_FILE"
        success "$node node setup complete"
    else
        warning "Worker node script not found: $script"
    fi

    # Later phases (services/config/verify) can be added
}

# ------------------------------
# Firewall & Security
# ------------------------------
apply_security() {
    section "Security Hardening"
    progress "Applying firewall rules..."
    if [ -f "$SCRIPT_DIR/apply-firewall.sh" ]; then
        bash "$SCRIPT_DIR/apply-firewall.sh" "boot" 2>&1 | tee -a "$LOG_FILE"
        success "Firewall applied"
    fi

    progress "Enabling fail2ban..."
    if command -v fail2ban-client &>/dev/null; then
        systemctl enable fail2ban 2>&1 | tee -a "$LOG_FILE" || true
        success "Fail2ban enabled"
    fi
}

# ------------------------------
# Cluster Health
# ------------------------------
verify_cluster_health() {
    section "Cluster Health Verification"
    bash "$SCRIPT_DIR/health-check-all.sh" 2>&1 | tee -a "$LOG_FILE"
    success "Cluster health verified"
}

# ------------------------------
# Performance Baseline
# ------------------------------
establish_performance_baseline() {
    section "Performance Baseline"
    bash "$SCRIPT_DIR/performance-monitor.sh" analyze 2>&1 | tee -a "$LOG_FILE"
    success "Baseline performance metrics captured"
}

# ------------------------------
# Backup Configuration
# ------------------------------
create_initial_backup() {
    section "Initial Configuration Backup"
    if [ -f "$SCRIPT_DIR/../operations/backups/backup-restore-manager.sh" ]; then
        bash "$SCRIPT_DIR/../operations/backups/backup-restore-manager.sh" create 2>&1 | tee -a "$LOG_FILE"
        success "Backup created"
    else
        warning "Backup manager missing - skipping"
    fi
}

# ------------------------------
# Deployment Stages
# ------------------------------
full_deployment() {
    section "Full Cluster Deployment"
    stage_funcs=(deploy_boot_node deploy_node_type apply_security establish_performance_baseline create_initial_backup verify_cluster_health)

    check_prerequisites
    validate_configuration

    # Boot node
    deploy_boot_node "all"

    # Worker nodes
    for node in "isr" "mesh" "vhf"; do
        deploy_node_type "$node"
    done

    # Security
    apply_security

    # Performance
    establish_performance_baseline

    # Backup
    create_initial_backup

    # Health
    verify_cluster_health

    section "Deployment Complete"
    success "Full deployment finished successfully"
}

# ------------------------------
# Command-line / Interactive
# ------------------------------
print_usage() {
    cat << EOF
Cluster Deployment Coordinator

Usage: $0 [command]

Commands:
  full       Full cluster deployment
  boot       Boot node only
  validate   Pre-flight + config validation
  health     Cluster health check
  log        Tail deployment log
  help       Show this message

Interactive mode (default)
  $0         Show menu
EOF
}

show_menu() {
    echo ""
    echo -e "${CYAN}Cluster Deployment Coordinator${NC}"
    echo "================================"
    echo "1) Full cluster deployment"
    echo "2) Boot node only"
    echo "3) Validation and pre-flight checks"
    echo "4) Health check"
    echo "5) View deployment log"
    echo "6) Exit"
    echo ""
}

interactive_mode() {
    while true; do
        show_menu
        read -rp "Select option: " choice
        case "$choice" in
            1) full_deployment ;;
            2) deploy_boot_node "all" ;;
            3) check_prerequisites && validate_configuration ;;
            4) verify_cluster_health ;;
            5) tail -f "$LOG_FILE" ;;
            6) exit 0 ;;
            *) warning "Invalid choice" ;;
        esac
    done
}

main() {
    if [ $# -eq 0 ]; then
        interactive_mode
    else
        case "$1" in
            full) full_deployment ;;
            boot) deploy_boot_node "all" ;;
            validate) check_prerequisites && validate_configuration ;;
            health) verify_cluster_health ;;
            log) tail -f "$LOG_FILE" ;;
            help) print_usage ;;
            *) print_usage ;;
        esac
    fi
}

main "$@"

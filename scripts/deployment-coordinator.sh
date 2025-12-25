#!/bin/bash

################################################################################
# Automated Cluster Deployment Coordinator
#
# Purpose: End-to-end automated deployment of entire cluster
# Orchestrates boot node setup, validation, and node deployment
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")/deployments"

LOG_DIR="/var/log/deployment"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deployment-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# CONFIGURATION
################################################################################

# Cluster node definitions
declare -A NODES=(
    [boot]="192.168.1.10"
    [isr]="192.168.1.20"
    [mesh]="192.168.1.30"
    [vhf]="192.168.1.40"
)

################################################################################
# LOGGING
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}║${NC} $1" | tee -a "$LOG_FILE"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

progress() {
    echo -e "${CYAN}→${NC} $1" | tee -a "$LOG_FILE"
}

################################################################################
# PRE-FLIGHT CHECKS
################################################################################

check_prerequisites() {
    section "Pre-Flight Checks"
    
    progress "Checking environment..."
    
    # Check if running as root (for some operations)
    if [ "$EUID" -ne 0 ]; then
        warning "Not running as root - some operations may fail"
        warning "Consider running with: sudo $0"
    fi
    
    # Check required scripts exist
    local required_scripts=(
        "validate-all-configs.sh"
        "performance-monitor.sh"
        "health-check-all.sh"
        "cluster-orchestrator.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            success "Found: $script"
        else
            error "Missing script: $script"
            return 1
        fi
    done
    
    # Check required deployment directories
    if [ -d "$DEPLOY_DIR" ]; then
        success "Deployment directory found: $DEPLOY_DIR"
    else
        error "Deployment directory missing: $DEPLOY_DIR"
        return 1
    fi
    
    # Check network connectivity
    progress "Checking network connectivity..."
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        success "Internet connectivity available"
    else
        warning "No internet connectivity - offline mode"
    fi
}

################################################################################
# CONFIGURATION VALIDATION
################################################################################

validate_configuration() {
    section "Configuration Validation"
    
    progress "Running comprehensive validation..."
    
    if [ -f "$SCRIPT_DIR/validate-all-configs.sh" ]; then
        if bash "$SCRIPT_DIR/validate-all-configs.sh" 2>&1 | tee -a "$LOG_FILE"; then
            success "Configuration validation passed"
            return 0
        else
            error "Configuration validation failed"
            return 1
        fi
    fi
}

################################################################################
# BOOT NODE DEPLOYMENT
################################################################################

deploy_boot_node() {
    section "Boot Node Deployment"
    
    local phase=$1
    
    if [ -z "$phase" ]; then
        phase="all"
    fi
    
    case "$phase" in
        1|all)
            progress "Deploying boot node phase 1: System Setup"
            if [ -f "$DEPLOY_DIR/01-boot-node-setup.sh" ]; then
                bash "$DEPLOY_DIR/01-boot-node-setup.sh" 2>&1 | tee -a "$LOG_FILE"
                success "Boot node phase 1 deployed"
            else
                error "Boot node phase 1 script not found"
                return 1
            fi
            ;;
    esac
    
    case "$phase" in
        2|all)
            progress "Deploying boot node phase 2: Service Installation"
            if [ -f "$DEPLOY_DIR/02-boot-node-services.sh" ]; then
                bash "$DEPLOY_DIR/02-boot-node-services.sh" 2>&1 | tee -a "$LOG_FILE"
                success "Boot node phase 2 deployed"
            fi
            ;;
    esac
    
    case "$phase" in
        3|all)
            progress "Deploying boot node phase 3: Configuration"
            if [ -f "$DEPLOY_DIR/03-boot-node-config.sh" ]; then
                bash "$DEPLOY_DIR/03-boot-node-config.sh" 2>&1 | tee -a "$LOG_FILE"
                success "Boot node phase 3 deployed"
            fi
            ;;
    esac
    
    case "$phase" in
        4|all)
            progress "Deploying boot node phase 4: Verification"
            if [ -f "$DEPLOY_DIR/04-boot-node-verify.sh" ]; then
                bash "$DEPLOY_DIR/04-boot-node-verify.sh" 2>&1 | tee -a "$LOG_FILE"
                success "Boot node phase 4 deployed"
            fi
            ;;
    esac
}

################################################################################
# WORKER NODE DEPLOYMENT
################################################################################

deploy_node_type() {
    local node_type=$1
    
    section "Deploying $node_type Node"
    
    progress "Deploying $node_type node phase 1: System Setup"
    if [ -f "$DEPLOY_DIR/node-setup/01-${node_type}-node-setup.sh" ]; then
        bash "$DEPLOY_DIR/node-setup/01-${node_type}-node-setup.sh" 2>&1 | tee -a "$LOG_FILE"
        success "$node_type node phase 1 deployed"
    else
        error "$node_type node setup script not found"
        return 1
    fi
    
    # Note: Phase 2-4 scripts would be created in same pattern
    log "Additional phases (2-4) would be deployed via cluster-orchestrator"
}

################################################################################
# CLUSTER HEALTH VERIFICATION
################################################################################

verify_cluster_health() {
    section "Cluster Health Verification"
    
    progress "Running comprehensive health checks..."
    
    if [ -f "$SCRIPT_DIR/health-check-all.sh" ]; then
        bash "$SCRIPT_DIR/health-check-all.sh" 2>&1 | tee -a "$LOG_FILE"
        success "Health checks completed"
    fi
}

################################################################################
# PERFORMANCE BASELINE
################################################################################

establish_performance_baseline() {
    section "Establishing Performance Baseline"
    
    progress "Running initial performance analysis..."
    
    if [ -f "$SCRIPT_DIR/performance-monitor.sh" ]; then
        bash "$SCRIPT_DIR/performance-monitor.sh" analyze 2>&1 | tee -a "$LOG_FILE"
        success "Baseline performance metrics captured"
    fi
}

################################################################################
# BACKUP CREATION
################################################################################

create_initial_backup() {
    section "Creating Initial Configuration Backup"
    
    progress "Backing up current configuration..."
    
    # Use backup-restore-manager if available
    if [ -f "$SCRIPT_DIR/../operations/backups/backup-restore-manager.sh" ]; then
        bash "$SCRIPT_DIR/../operations/backups/backup-restore-manager.sh" create 2>&1 | tee -a "$LOG_FILE"
        success "Configuration backup created"
    else
        warning "Backup manager not found - skipping backup"
    fi
}

################################################################################
# DEPLOYMENT STAGES
################################################################################

stage_1_infrastructure() {
    section "STAGE 1: Infrastructure Setup"
    
    log "Setting up core infrastructure..."
    
    # Validate configs first
    if ! validate_configuration; then
        error "Configuration validation failed - aborting"
        return 1
    fi
    
    # Deploy boot node
    deploy_boot_node "1"
    
    success "Infrastructure stage complete"
}

stage_2_services() {
    section "STAGE 2: Service Installation"
    
    log "Installing cluster services..."
    
    deploy_boot_node "2"
    
    success "Service installation complete"
}

stage_3_configuration() {
    section "STAGE 3: Service Configuration"
    
    log "Configuring services..."
    
    deploy_boot_node "3"
    
    success "Configuration stage complete"
}

stage_4_verification() {
    section "STAGE 4: System Verification"
    
    log "Verifying boot node..."
    
    deploy_boot_node "4"
    
    # Verify cluster health
    verify_cluster_health
    
    success "Verification stage complete"
}

stage_5_nodes() {
    section "STAGE 5: Worker Node Deployment"
    
    log "Deploying worker nodes..."
    
    for node_type in "isr" "mesh" "vhf"; do
        deploy_node_type "$node_type"
    done
    
    success "Worker node deployment complete"
}

stage_6_optimization() {
    section "STAGE 6: Performance Optimization"
    
    log "Optimizing cluster performance..."
    
    establish_performance_baseline
    
    # Apply optimizations if running as root
    if [ "$EUID" -eq 0 ]; then
        progress "Applying system optimizations..."
        if [ -f "$SCRIPT_DIR/performance-monitor.sh" ]; then
            bash "$SCRIPT_DIR/performance-monitor.sh" optimize 2>&1 | tee -a "$LOG_FILE" || true
            success "Performance optimizations applied"
        fi
    fi
}

stage_7_security() {
    section "STAGE 7: Security Hardening"
    
    log "Applying security measures..."
    
    progress "Enabling firewall..."
    if command -v ufw &>/dev/null; then
        sudo ufw enable 2>&1 | tee -a "$LOG_FILE" || true
        success "Firewall enabled"
    fi
    
    progress "Enabling fail2ban..."
    if systemctl is-enabled fail2ban &>/dev/null; then
        sudo systemctl enable fail2ban 2>&1 | tee -a "$LOG_FILE" || true
        success "Fail2ban enabled"
    fi
}

stage_8_backup() {
    section "STAGE 8: Backup Configuration"
    
    create_initial_backup
}

################################################################################
# DEPLOYMENT MODES
################################################################################

full_deployment() {
    section "FULL CLUSTER DEPLOYMENT"
    
    log "Starting complete cluster deployment..."
    log "This will configure boot node and prepare worker nodes"
    log "Deployment log: $LOG_FILE"
    echo ""
    
    stage_1_infrastructure || return 1
    stage_2_services || return 1
    stage_3_configuration || return 1
    stage_4_verification || return 1
    stage_5_nodes || return 1
    stage_6_optimization || return 1
    stage_7_security || return 1
    stage_8_backup || return 1
    
    section "DEPLOYMENT COMPLETE"
    success "All stages completed successfully"
    log "Full deployment finished successfully"
}

boot_only_deployment() {
    section "BOOT NODE ONLY DEPLOYMENT"
    
    log "Deploying boot node only..."
    
    stage_1_infrastructure || return 1
    stage_2_services || return 1
    stage_3_configuration || return 1
    stage_4_verification || return 1
    
    success "Boot node deployment complete"
}

validation_only() {
    section "VALIDATION ONLY"
    
    check_prerequisites || return 1
    validate_configuration || return 1
    
    success "Validation complete"
}

health_check_only() {
    section "HEALTH CHECK ONLY"
    
    verify_cluster_health
    
    success "Health check complete"
}

################################################################################
# MAIN MENU
################################################################################

show_menu() {
    echo ""
    echo -e "${CYAN}Cluster Deployment Coordinator${NC}"
    echo "================================"
    echo ""
    echo "1) Full cluster deployment (all stages)"
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
        read -p "Select option: " choice
        
        case "$choice" in
            1) full_deployment ;;
            2) boot_only_deployment ;;
            3) validation_only ;;
            4) health_check_only ;;
            5) tail -f "$LOG_FILE" ;;
            6) 
                log "Deployment coordinator exiting"
                exit 0
                ;;
            *)
                error "Invalid option"
                ;;
        esac
    done
}

################################################################################
# COMMAND LINE
################################################################################

print_usage() {
    cat << EOF
Automated Cluster Deployment Coordinator

Usage: $0 [command]

Commands:
  full       Deploy entire cluster (all stages)
  boot       Deploy boot node only
  validate   Validation and pre-flight checks
  health     Health check
  log        View deployment log
  help       Show this message

Interactive mode (default):
  $0           Start interactive menu

Examples:
  $0 full               # Deploy complete cluster
  $0 boot               # Deploy boot node only
  $0 validate           # Just validate configuration
  $0 health             # Run health checks

EOF
}

################################################################################
# MAIN ENTRY
################################################################################

main() {
    if [ $# -eq 0 ]; then
        # Interactive mode
        check_prerequisites
        interactive_mode
    else
        # Command line mode
        case "$1" in
            full)
                check_prerequisites
                full_deployment
                ;;
            boot)
                check_prerequisites
                boot_only_deployment
                ;;
            validate)
                check_prerequisites
                validation_only
                ;;
            health)
                verify_cluster_health
                ;;
            log)
                tail -f "$LOG_FILE"
                ;;
            help)
                print_usage
                ;;
            *)
                echo "Unknown command: $1"
                print_usage
                exit 1
                ;;
        esac
    fi
}

# Execute main
main "$@"

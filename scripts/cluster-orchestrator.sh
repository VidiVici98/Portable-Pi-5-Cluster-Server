#!/bin/bash

################################################################################
# Cluster Multi-Node Management Tool
#
# Purpose: Orchestrate operations across entire cluster (boot, ISR, mesh, VHF)
# Execute commands, deploy updates, and manage configuration across all nodes
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

# Node definitions
declare -A NODES=(
    ["boot"]="192.168.1.10"
    ["isr"]="192.168.1.20"
    ["mesh"]="192.168.1.30"
    ["vhf"]="192.168.1.40"
)

declare -A NODE_USERS=(
    ["boot"]="pi"
    ["isr"]="pi"
    ["mesh"]="pi"
    ["vhf"]="pi"
)

LOG_DIR="/var/log/cluster-mgmt"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/orchestration-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# LOGGING & OUTPUT
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}═══ $1 ═══${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

################################################################################
# NODE COMMUNICATION
################################################################################

ssh_node() {
    local node=$1
    local cmd=$2
    local user="${NODE_USERS[$node]}"
    local ip="${NODES[$node]}"
    
    if [ -z "$ip" ]; then
        error "Unknown node: $node"
        return 1
    fi
    
    # SSH with strict host key checking disabled (for lab environment)
    ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=5 \
        "$user@$ip" "$cmd" 2>/dev/null
}

ping_node() {
    local node=$1
    local ip="${NODES[$node]}"
    
    if ping -c 1 -W 2 "$ip" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

scp_to_node() {
    local node=$1
    local local_file=$2
    local remote_path=$3
    local user="${NODE_USERS[$node]}"
    local ip="${NODES[$node]}"
    
    scp -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$local_file" "$user@$ip:$remote_path" 2>/dev/null
}

################################################################################
# NODE STATUS
################################################################################

check_node_health() {
    local node=$1
    
    if ! ping_node "$node"; then
        error "  $node: UNREACHABLE"
        return 1
    fi
    
    local uptime=$(ssh_node "$node" "uptime -p" 2>/dev/null)
    local disk=$(ssh_node "$node" "df / | tail -1 | awk '{printf \"%.0f%%\", 100-\$5}'" 2>/dev/null)
    local memory=$(ssh_node "$node" "free | grep Mem | awk '{printf \"%.0f%%\", \$3/\$2*100}'" 2>/dev/null)
    local load=$(ssh_node "$node" "cat /proc/loadavg | awk '{print \$1}'" 2>/dev/null)
    
    echo "  $node:"
    echo "    Status: UP"
    echo "    Uptime: $uptime"
    echo "    Memory: ${memory}%"
    echo "    Disk: ${disk}%"
    echo "    Load: ${load}"
}

################################################################################
# DEPLOYMENT OPERATIONS
################################################################################

deploy_phase_to_boot() {
    local phase=$1
    
    section "Deploying Phase $phase to boot node"
    
    if ! ping_node "boot"; then
        error "Boot node unreachable"
        return 1
    fi
    
    # Copy deployment script
    scp_to_node "boot" "deployments/boot-node/0${phase}-*.sh" "/tmp/"
    
    # Execute
    log "Running phase $phase on boot node..."
    ssh_node "boot" "sudo bash /tmp/0${phase}-*.sh"
    
    success "Phase $phase deployment complete"
}

deploy_to_node_type() {
    local node_type=$1  # isr, mesh, vhf
    
    section "Deploying to $node_type node"
    
    if ! ping_node "$node_type"; then
        error "$node_type node unreachable"
        return 1
    fi
    
    # Copy deployment script
    scp_to_node "$node_type" "deployments/node-setup/01-${node_type}-node-setup.sh" "/tmp/"
    
    # Execute
    log "Running phase 1 on $node_type node..."
    ssh_node "$node_type" "sudo bash /tmp/01-${node_type}-node-setup.sh"
    
    success "$node_type node deployment complete"
}

################################################################################
# PARALLEL OPERATIONS
################################################################################

parallel_execute() {
    local cmd=$1
    
    section "Executing command across all nodes: $cmd"
    
    # Array to store PIDs
    declare -A pids
    
    # Start all commands in parallel
    for node in "${!NODES[@]}"; do
        (
            if ssh_node "$node" "$cmd" &>/dev/null; then
                success "$node: Command successful"
            else
                warn "$node: Command failed"
            fi
        ) &
        pids[$node]=$!
    done
    
    # Wait for all to complete
    local failed=0
    for node in "${!pids[@]}"; do
        if ! wait ${pids[$node]}; then
            ((failed++))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        success "All nodes executed successfully"
    else
        warn "$failed node(s) had failures"
    fi
}

parallel_update() {
    section "Updating all nodes"
    
    parallel_execute "sudo apt-get update && sudo apt-get upgrade -y"
}

parallel_health_check() {
    section "Health check on all nodes"
    
    for node in "${!NODES[@]}"; do
        check_node_health "$node" || true
    done
}

################################################################################
# CONFIGURATION MANAGEMENT
################################################################################

push_config() {
    local config_file=$1
    
    section "Pushing configuration to all nodes: $config_file"
    
    if [ ! -f "$config_file" ]; then
        error "Config file not found: $config_file"
        return 1
    fi
    
    for node in "${!NODES[@]}"; do
        log "Pushing to $node..."
        scp_to_node "$node" "$config_file" "/tmp/$(basename $config_file)"
    done
    
    success "Configuration pushed to all nodes"
}

sync_scripts() {
    section "Syncing scripts to all nodes"
    
    for node in "${!NODES[@]}"; do
        log "Syncing scripts to $node..."
        ssh_node "$node" "cd ~ && git pull" || warn "Git pull failed on $node"
    done
    
    success "Scripts synced"
}

################################################################################
# MONITORING & DIAGNOSTICS
################################################################################

generate_cluster_report() {
    section "Generating Cluster Status Report"
    
    local report_file="$LOG_DIR/cluster-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Cluster Status Report - $(date)"
        echo "================================"
        echo ""
        
        for node in "${!NODES[@]}"; do
            echo "Node: $node (${NODES[$node]})"
            check_node_health "$node" 2>/dev/null || echo "  Status: OFFLINE"
            echo ""
        done
        
        echo "Services Status:"
        echo "================================"
        for node in "${!NODES[@]}"; do
            if ping_node "$node"; then
                echo "$node services:"
                ssh_node "$node" "systemctl status ssh dnsmasq nfs-kernel-server 2>/dev/null | grep 'active'" || true
                echo ""
            fi
        done
        
    } > "$report_file"
    
    success "Report generated: $report_file"
    cat "$report_file"
}

collect_logs() {
    local log_type=${1:-"all"}
    
    section "Collecting logs from cluster ($log_type)"
    
    local collect_dir="$LOG_DIR/collected-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$collect_dir"
    
    for node in "${!NODES[@]}"; do
        if ping_node "$node"; then
            log "Collecting logs from $node..."
            mkdir -p "$collect_dir/$node"
            
            case "$log_type" in
                all)
                    ssh_node "$node" "tar czf - /var/log/ 2>/dev/null" > "$collect_dir/$node/logs.tar.gz"
                    ;;
                system)
                    ssh_node "$node" "sudo journalctl -n 1000 > /tmp/system.log" && \
                    scp_to_node "$node" "/tmp/system.log" "$collect_dir/$node/"
                    ;;
                deployment)
                    ssh_node "$node" "cat /var/log/*setup.log > /tmp/setup.log 2>/dev/null" && \
                    scp_to_node "$node" "/tmp/setup.log" "$collect_dir/$node/"
                    ;;
            esac
        fi
    done
    
    success "Logs collected to: $collect_dir"
}

################################################################################
# MAINTENANCE TASKS
################################################################################

perform_maintenance() {
    section "Performing Cluster Maintenance"
    
    log "Synchronizing time across cluster..."
    parallel_execute "sudo systemctl restart systemd-timesyncd || true"
    
    log "Clearing package caches..."
    parallel_execute "sudo apt-get clean && sudo apt-get autoclean"
    
    log "Rotating logs..."
    parallel_execute "sudo logrotate -f /etc/logrotate.conf"
    
    success "Maintenance complete"
}

reboot_all_nodes() {
    section "⚠️  REBOOTING ALL CLUSTER NODES ⚠️"
    
    read -p "Are you sure? This will disrupt all services (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        error "Reboot cancelled"
        return
    fi
    
    for node in "${!NODES[@]}"; do
        log "Rebooting $node..."
        ssh_node "$node" "sudo reboot" &
    done
    
    log "Reboots initiated. Waiting 60 seconds for shutdown..."
    sleep 60
    
    log "Checking node status..."
    sleep 30
    
    for node in "${!NODES[@]}"; do
        if ping_node "$node"; then
            success "$node is back online"
        else
            warn "$node still offline"
        fi
    done
}

################################################################################
# MAIN MENU
################################################################################

print_menu() {
    echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Cluster Multi-Node Management Tool  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
    
    echo "Node Status:"
    for node in "${!NODES[@]}"; do
        if ping_node "$node" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $node (${NODES[$node]})"
        else
            echo -e "  ${RED}✗${NC} $node (${NODES[$node]})"
        fi
    done
    
    echo -e "\n${BLUE}Commands:${NC}"
    echo "  status          Show cluster status"
    echo "  health          Health check all nodes"
    echo "  report          Generate cluster report"
    echo ""
    echo "  deploy-boot N   Deploy phase N (1-4) to boot node"
    echo "  deploy-TYPE     Deploy TYPE node (isr/mesh/vhf)"
    echo ""
    echo "  exec CMD        Execute command on all nodes"
    echo "  update          Update all nodes"
    echo "  sync            Sync scripts from git"
    echo ""
    echo "  collect-logs    Collect logs from all nodes"
    echo "  maintenance     Run maintenance tasks"
    echo "  reboot          Reboot all nodes"
    echo ""
    echo "  logs            View orchestration logs"
    echo "  help            Show this menu"
    echo "  exit            Exit"
    echo ""
}

print_usage() {
    cat << EOF
Cluster Management Tool

Usage: $0 [command] [options]

Commands:
  status              Show cluster node status
  health              Perform health check on all nodes
  report              Generate cluster status report
  
  deploy-boot N       Deploy boot node phase N (1-4)
  deploy-isr          Deploy ISR node
  deploy-mesh         Deploy Mesh node
  deploy-vhf          Deploy VHF node
  
  exec CMD            Execute command on all nodes
  update              Update all nodes
  sync                Sync scripts from git
  
  collect-logs TYPE   Collect logs (all/system/deployment)
  maintenance         Run maintenance tasks
  reboot              Reboot all nodes
  
  logs                Show orchestration logs
  interactive         Interactive menu mode

Examples:
  $0 status
  $0 health
  $0 deploy-boot 1
  $0 exec "sudo systemctl status ssh"
  $0 collect-logs all

EOF
}

################################################################################
# MAIN
################################################################################

if [ $# -lt 1 ]; then
    # Interactive mode
    while true; do
        print_menu
        read -p "Enter command: " cmd
        
        case "$cmd" in
            status|health|report|logs|help|exit)
                "$cmd"
                ;;
            deploy-boot|deploy-isr|deploy-mesh|deploy-vhf)
                node_type=$(echo "$cmd" | cut -d'-' -f2)
                if [[ $node_type == "boot" ]]; then
                    read -p "Enter phase (1-4): " phase
                    deploy_phase_to_boot "$phase"
                else
                    deploy_to_node_type "$node_type"
                fi
                ;;
            update|sync|maintenance|reboot)
                "parallel_$cmd" 2>/dev/null || "$cmd"
                ;;
            *)
                echo "Unknown command: $cmd"
                ;;
        esac
    done
else
    # Command line mode
    case "$1" in
        status|health)
            section "Cluster Status"
            for node in "${!NODES[@]}"; do
                check_node_health "$node"
            done
            ;;
        report)
            generate_cluster_report
            ;;
        deploy-boot)
            deploy_phase_to_boot "$2"
            ;;
        deploy-isr|deploy-mesh|deploy-vhf)
            deploy_to_node_type "${1#deploy-}"
            ;;
        exec)
            parallel_execute "$2"
            ;;
        update)
            parallel_update
            ;;
        sync)
            sync_scripts
            ;;
        collect-logs)
            collect_logs "$2"
            ;;
        maintenance)
            perform_maintenance
            ;;
        reboot)
            reboot_all_nodes
            ;;
        logs)
            tail -100 "$LOG_FILE"
            ;;
        interactive)
            exec "$0"
            ;;
        *)
            print_usage
            ;;
    esac
fi

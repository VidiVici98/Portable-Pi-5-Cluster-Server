#!/bin/bash

################################################################################
# Cluster Performance Monitoring & Optimization Tool
#
# Purpose: Monitor performance metrics and auto-tune cluster for optimization
# Analyzes CPU, memory, I/O, and network performance with recommendations
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

LOG_DIR="/var/log/performance"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/performance-$(date +%Y%m%d-%H%M%S).log"

################################################################################
# LOGGING
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

section() {
    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}═══ $1 ═══${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

metric() {
    echo -e "${CYAN}$1:${NC} $2" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}" | tee -a "$LOG_FILE"
}

critical() {
    echo -e "${RED}✗ $1${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓ $1${NC}" | tee -a "$LOG_FILE"
}

################################################################################
# CPU MONITORING & OPTIMIZATION
################################################################################

analyze_cpu_performance() {
    section "CPU Performance Analysis"
    
    local cores=$(nproc)
    local model=$(grep -m1 "^model name" /proc/cpuinfo | cut -d: -f2 | xargs)
    local freq=$(grep -m1 "^cpu MHz" /proc/cpuinfo | cut -d: -f2 | xargs)
    
    metric "CPU Cores" "$cores"
    metric "CPU Model" "$model"
    metric "Current Frequency" "${freq} MHz"
    
    # Check load
    local load=$(cat /proc/loadavg | awk '{print $1}')
    local threshold=$(echo "$cores * 0.8" | bc)
    
    metric "Load Average" "$load"
    metric "Recommended Max" "$threshold"
    
    if (( $(echo "$load > $threshold" | bc -l) )); then
        warning "CPU load is high ($load > $threshold)"
        return 1
    else
        success "CPU load within normal range"
        return 0
    fi
}

optimize_cpu_scaling() {
    section "CPU Frequency Scaling Optimization"
    
    if command -v cpufreq-info &>/dev/null; then
        log "Current frequency scaling:"
        cpufreq-info || true
        
        log ""
        log "Recommended: Set to 'powersave' for reduced power, 'performance' for full speed"
        log "Current is optimal for balanced operation"
    else
        log "CPU frequency scaling tools not installed"
    fi
}

################################################################################
# MEMORY MONITORING & OPTIMIZATION
################################################################################

analyze_memory_performance() {
    section "Memory Performance Analysis"
    
    local mem_total=$(free -b | grep Mem | awk '{print $2}')
    local mem_used=$(free -b | grep Mem | awk '{print $3}')
    local mem_free=$(free -b | grep Mem | awk '{print $4}')
    local mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)
    
    metric "Total Memory" "$(numfmt --to=iec-i --suffix=B $mem_total 2>/dev/null || echo $(($mem_total / 1048576))MB)"
    metric "Used Memory" "$(numfmt --to=iec-i --suffix=B $mem_used 2>/dev/null || echo $(($mem_used / 1048576))MB)"
    metric "Free Memory" "$(numfmt --to=iec-i --suffix=B $mem_free 2>/dev/null || echo $(($mem_free / 1048576))MB)"
    metric "Usage Percentage" "${mem_percent}%"
    
    # Check for swap usage
    local swap_used=$(free -b | grep Swap | awk '{print $3}')
    if [ "$swap_used" -gt 0 ]; then
        warning "Swap is being used: $(($swap_used / 1048576))MB"
        warning "High swap usage reduces performance"
    else
        success "No swap usage (good)"
    fi
    
    # Recommendations
    if (( $(echo "$mem_percent > 85" | bc -l) )); then
        critical "Memory usage is high (${mem_percent}%)"
        return 1
    else
        success "Memory usage is normal"
        return 0
    fi
}

optimize_memory() {
    section "Memory Optimization"
    
    if [ "$EUID" -ne 0 ]; then
        warning "Some optimizations require root"
        return
    fi
    
    log "Applying memory optimization:"
    
    # Drop caches (safe operation)
    log "  Dropping page caches..."
    sync
    echo 1 > /proc/sys/vm/drop_caches
    success "Page caches dropped"
    
    # Tune swappiness
    if [ -f /proc/sys/vm/swappiness ]; then
        log "  Setting swappiness to 10 (prefer RAM over swap)..."
        echo 10 > /proc/sys/vm/swappiness
        success "Swappiness optimized"
    fi
    
    # Tune overcommit
    log "  Optimizing memory overcommit..."
    echo 1 > /proc/sys/vm/overcommit_memory
    success "Memory overcommit optimized"
}

################################################################################
# DISK I/O MONITORING & OPTIMIZATION
################################################################################

analyze_disk_io() {
    section "Disk I/O Performance"
    
    if command -v iostat &>/dev/null; then
        log "Disk I/O Statistics (requires sysstat)"
        iostat -x 1 2 | tail -15 || true
    fi
    
    log ""
    log "Disk Space Usage:"
    df -h | grep -E "^/dev"
    
    # Check for SSD vs HDD
    if lsblk -d -o NAME,ROTA | grep -q " 0$"; then
        success "SSD detected (good for NFS)"
    else
        warning "HDD detected (consider SSD for better performance)"
    fi
    
    # Check for fragmentation (ext4)
    for fs in $(mount | grep ext4 | awk '{print $1}'); do
        if command -v e4defrag &>/dev/null; then
            log "Checking fragmentation on $fs..."
            e4defrag -c "$fs" 2>/dev/null || true
        fi
    done
}

optimize_disk_io() {
    section "Disk I/O Optimization"
    
    if [ "$EUID" -ne 0 ]; then
        warning "Disk optimization requires root"
        return
    fi
    
    log "Applying I/O scheduler optimization:"
    
    # Set scheduler to CFQ for better interactive performance
    for device in $(lsblk -nd -o NAME | head -5); do
        if [ -f "/sys/block/$device/queue/scheduler" ]; then
            # Check if device has CFQ available
            if grep -q cfq "/sys/block/$device/queue/scheduler"; then
                echo cfq > "/sys/block/$device/queue/scheduler"
                log "  Set $device scheduler to CFQ"
            fi
        fi
    done
    
    success "I/O scheduler optimized"
}

################################################################################
# NETWORK PERFORMANCE
################################################################################

analyze_network_performance() {
    section "Network Performance"
    
    log "Interface Statistics:"
    netstat -i 2>/dev/null || ip -s link show
    
    log ""
    log "Network Connectivity:"
    
    # Test to gateway
    local gateway=$(ip route | grep default | awk '{print $3}')
    if ping -c 1 -W 2 "$gateway" &>/dev/null; then
        success "Gateway reachable: $gateway"
    else
        warning "Gateway unreachable: $gateway"
    fi
    
    # Test DNS
    if nslookup google.com &>/dev/null; then
        success "DNS resolution working"
    else
        warning "DNS resolution failing"
    fi
    
    # Check MTU
    local mtu=$(ip link show | grep "mtu" | head -1 | grep -oP '(?<=mtu )\d+')
    metric "MTU Size" "$mtu"
    
    if [ "$mtu" -lt 1500 ]; then
        warning "MTU is low (consider increasing to 1500)"
    fi
}

optimize_network() {
    section "Network Optimization"
    
    if [ "$EUID" -ne 0 ]; then
        warning "Network optimization requires root"
        return
    fi
    
    log "Applying network optimizations:"
    
    {
        echo "# Network optimization for NFS and clustering"
        echo "net.core.rmem_max = 134217728"
        echo "net.core.wmem_max = 134217728"
        echo "net.ipv4.tcp_rmem = 4096 87380 67108864"
        echo "net.ipv4.tcp_wmem = 4096 65536 67108864"
        echo "net.core.netdev_max_backlog = 5000"
    } >> /etc/sysctl.conf
    
    sysctl -p > /dev/null 2>&1
    success "Network buffers optimized for NFS"
}

################################################################################
# TEMPERATURE MONITORING
################################################################################

monitor_temperature() {
    section "Thermal Status"
    
    if command -v vcgencmd &>/dev/null; then
        local cpu_temp=$(vcgencmd measure_temp | grep -oP '\d+\.\d+')
        metric "CPU Temperature" "${cpu_temp}°C"
        
        if (( $(echo "$cpu_temp > 80" | bc -l) )); then
            critical "CPU temperature is high!"
        elif (( $(echo "$cpu_temp > 70" | bc -l) )); then
            warning "CPU temperature is elevated"
        else
            success "CPU temperature is normal"
        fi
    fi
    
    # Check throttling
    if [ -f /sys/class/thermal/cooling_device0/cur_state ]; then
        local throttle=$(cat /sys/class/thermal/cooling_device0/cur_state)
        if [ "$throttle" -gt 0 ]; then
            warning "CPU throttling active (level $throttle)"
        fi
    fi
}

################################################################################
# SERVICE PERFORMANCE
################################################################################

analyze_service_performance() {
    section "Service Performance Analysis"
    
    # Check NFS performance
    if systemctl is-active --quiet nfs-server; then
        log "NFS Server Performance:"
        nfsstat -s 2>/dev/null | head -20 || log "  nfsstat not available"
    fi
    
    # Check DNS performance
    if systemctl is-active --quiet dnsmasq; then
        log "DNS Performance:"
        # Measure DNS query time
        local dns_time=$( { time nslookup google.com 127.0.0.1 &>/dev/null; } 2>&1 | grep real | awk '{print $2}')
        metric "DNS Query Time" "$dns_time"
    fi
}

################################################################################
# REPORT GENERATION
################################################################################

generate_performance_report() {
    section "Generating Comprehensive Performance Report"
    
    local report="$LOG_DIR/perf-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Cluster Performance Report"
        echo "Generated: $(date)"
        echo "================================"
        echo ""
        
        analyze_cpu_performance
        analyze_memory_performance
        analyze_disk_io
        analyze_network_performance
        monitor_temperature
        analyze_service_performance
        
    } > "$report" 2>&1
    
    success "Report generated: $report"
}

################################################################################
# RECOMMENDATIONS ENGINE
################################################################################

generate_recommendations() {
    section "Performance Recommendations"
    
    local recommendations=0
    
    # CPU recommendations
    if [ $(cat /proc/cpuinfo | grep -c "processor") -lt 2 ]; then
        warning "Single-core system detected - consider upgrading to multi-core"
        ((recommendations++))
    fi
    
    # Memory recommendations
    local mem_percent=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
    if [ "$mem_percent" -gt 80 ]; then
        warning "High memory usage - consider adding more RAM or optimizing services"
        ((recommendations++))
    fi
    
    # Disk recommendations
    local disk_percent=$(df / | tail -1 | awk '{print $5}' | cut -d% -f1)
    if [ "$disk_percent" -gt 85 ]; then
        critical "Disk space low - delete old logs or add storage"
        ((recommendations++))
    fi
    
    # Network recommendations
    if [ -f /proc/sys/net/ipv4/tcp_window_scaling ] && ! grep -q 1 /proc/sys/net/ipv4/tcp_window_scaling; then
        warning "TCP window scaling disabled - enable for better WAN performance"
        ((recommendations++))
    fi
    
    if [ $recommendations -eq 0 ]; then
        success "No critical recommendations"
    else
        log ""
        log "Found $recommendations optimization opportunities"
    fi
}

################################################################################
# CONTINUOUS MONITORING
################################################################################

start_continuous_monitoring() {
    local interval=${1:-300}  # Default 5 minutes
    
    section "Starting Continuous Monitoring (interval: ${interval}s)"
    
    while true; do
        log ""
        log "Monitoring cycle at $(date)"
        
        analyze_cpu_performance || true
        analyze_memory_performance || true
        analyze_network_performance || true
        monitor_temperature
        
        log "Waiting ${interval}s until next cycle..."
        sleep "$interval"
    done
}

################################################################################
# MAIN
################################################################################

print_usage() {
    cat << EOF
Cluster Performance Monitoring & Optimization

Usage: $0 [command] [options]

Commands:
  analyze     Analyze all performance metrics
  cpu         Analyze CPU performance
  memory      Analyze memory performance
  disk        Analyze disk I/O performance
  network     Analyze network performance
  thermal     Monitor CPU temperature
  services    Analyze service performance
  
  optimize    Apply all optimizations (requires root)
  tune-cpu    Optimize CPU settings
  tune-mem    Optimize memory settings
  tune-io     Optimize disk I/O
  tune-net    Optimize network
  
  report      Generate comprehensive performance report
  recommend   Generate optimization recommendations
  monitor     Start continuous monitoring (ctrl+c to stop)
  
  help        Show this usage message

Examples:
  $0 analyze                    # Full analysis
  $0 optimize                   # Apply all optimizations
  $0 monitor 60                 # Monitor every 60 seconds
  $0 report                     # Generate PDF report

EOF
}

if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi

case "$1" in
    analyze)
        analyze_cpu_performance
        analyze_memory_performance
        analyze_disk_io
        analyze_network_performance
        monitor_temperature
        analyze_service_performance
        ;;
    cpu)
        analyze_cpu_performance
        ;;
    memory)
        analyze_memory_performance
        ;;
    disk)
        analyze_disk_io
        ;;
    network)
        analyze_network_performance
        ;;
    thermal)
        monitor_temperature
        ;;
    services)
        analyze_service_performance
        ;;
    optimize)
        optimize_memory
        optimize_disk_io
        optimize_network
        success "All optimizations applied"
        ;;
    tune-cpu)
        optimize_cpu_scaling
        ;;
    tune-mem)
        optimize_memory
        ;;
    tune-io)
        optimize_disk_io
        ;;
    tune-net)
        optimize_network
        ;;
    report)
        generate_performance_report
        ;;
    recommend)
        generate_recommendations
        ;;
    monitor)
        start_continuous_monitoring "${2:-300}"
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

log "Operation complete (log: $LOG_FILE)"

# Infrastructure Operations Guide

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Daily, weekly, and monthly operational procedures

## Overview

This guide provides step-by-step procedures for operating and maintaining the Portable Pi 5 Cluster Server. Follow these procedures to keep the system healthy, secure, and performant.

**Quick Links:**
- [Daily Operations](#daily-operations)
- [Weekly Maintenance](#weekly-maintenance)
- [Monthly Health Check](#monthly-health-check)
- [Troubleshooting](#troubleshooting)
- [Escalation Procedures](#escalation-procedures)

---

## Daily Operations

### Morning System Check (10 min)

Every morning, verify the system is operational:

```bash
# SSH to boot node
ssh pi@boot-node

# Check overall status
make status

# Look for warnings
make status | grep -i "warning\|error\|critical"
```

**What to Check:**

1. **Boot Node Online**
   ```bash
   ping boot-node
   # Should see: 64 bytes from boot-node: icmp_seq=1 ttl=64 time=X.XXms
   ```

2. **Services Running**
   ```bash
   sudo systemctl status dnsmasq nfs-server ssh
   # All should show: active (running)
   ```

3. **Disk Space**
   ```bash
   df -h | grep -E "^/|^boot"
   # Root should be < 80% used
   # Boot should have space for new kernels
   ```

4. **Memory Usage**
   ```bash
   free -h
   # Available should be > 500MB
   ```

5. **Network Status**
   ```bash
   ip addr show
   # Primary interface should have IP address
   ```

6. **Time Synchronization**
   ```bash
   timedatectl status
   # Should show "synchronized: yes"
   ```

**If any issues detected:** See [Troubleshooting](#troubleshooting)

### Monitoring Alerts (Continuous)

If monitoring is active:
- [ ] Check alert dashboard hourly
- [ ] Respond to critical alerts within 5 minutes
- [ ] Respond to warnings within 30 minutes
- [ ] Log all alerts and responses

### System Log Review (5 min, 2x daily)

```bash
# Review recent errors (last 1 hour)
sudo journalctl -p err -S "1 hour ago"

# Look for patterns
sudo journalctl -p warning -S "24 hours ago" | tail -20

# Check SSH access
sudo journalctl -u ssh -n 10
```

**Normal patterns to expect:**
- Occasional DNS queries
- SSH connection/disconnection
- NFS mount activity
- NTP synchronization

**Concerning patterns:**
- Repeated failed SSH attempts
- NFS I/O errors
- Memory allocation failures
- Kernel panic messages

---

## Weekly Maintenance

### Full System Health Check (30 min, Tuesday 2 PM)

Run comprehensive diagnostics:

```bash
# Full validation
make test

# Detailed status report
make status-full > status-$(date +%Y%m%d).log

# Check all services
sudo systemctl list-units --type=service --state=running

# Verify configuration
./scripts/validate-config.sh -v
```

### Backup Verification (10 min, Wednesday 3 PM)

Ensure backups are working:

```bash
# Check backup job status
ls -lh operations/backups/ | tail -5

# Verify backup integrity
./operations/backups/verify-backup.sh

# Check backup size (should be reasonable)
du -sh operations/backups/

# Oldest backup should be < 2 weeks
find operations/backups -type f -mtime +14 -exec ls -l {} \;
```

**Expected backup size:** 2-5 GB  
**Backup frequency:** Daily  
**Retention:** 14+ days

### Security Scan (15 min, Thursday 10 AM)

Check for security issues:

```bash
# Verify firewall rules
sudo ufw status verbose

# Check failed login attempts
sudo grep "Failed password" /var/log/auth.log | tail -10

# Verify no world-readable secrets
find config/secrets -type f -perm /077

# Check sudo access
sudo grep COMMAND /var/log/sudo.log | tail -20

# Verify SSH key permissions
ls -la ~/.ssh/
# Should show: -rw------- 600 for id_rsa
```

### Network Performance Check (10 min, Friday 11 AM)

Baseline network performance:

```bash
# Test DNS resolution time
time nslookup cluster.local

# Check NFS mount latency
mount | grep nfs

# Measure network throughput (if available)
iperf3 -c remote-node -t 10

# Check for packet loss
ping -c 100 gateway | grep -E "packets|loss"

# Verify network interfaces
ip -s link show | grep -E "RX|TX|errors"
```

### Configuration Backup (5 min, Sunday 1 PM)

```bash
# Backup current configuration
tar czf config-backup-$(date +%Y%m%d).tar.gz config/

# Move to backup location
mv config-backup-*.tar.gz operations/backups/

# Verify archive integrity
tar tzf operations/backups/config-backup-*.tar.gz | head

# Log the backup
echo "Configuration backed up on $(date)" >> operations/logs/maintenance.log
```

---

## Monthly Health Check

### Full System Audit (1-2 hours, First Monday of month)

Comprehensive system assessment:

#### 1. Security Audit (30 min)

```bash
# Check for security updates
sudo apt update
sudo apt list --upgradable

# Verify security settings
grep -r "^[^#]" /etc/ssh/sshd_config | head -20

# Check user accounts
awk -F: '($3>=1000 && $3<65534) || $3==0 || $3==1' /etc/passwd

# Verify disk encryption (if applicable)
sudo cryptsetup status /dev/mapper/*

# Analyze auth logs for attacks
sudo journalctl -u ssh --since "30 days ago" | grep -i "failed\|attack"
```

#### 2. Performance Analysis (20 min)

```bash
# Generate performance report
vmstat 5 12  # CPU/disk I/O

# Check memory pressure
cat /proc/pressure/memory

# Analyze system load over month
uptime

# Check disk performance
iostat -x 1 5

# Network statistics
ethtool -S eth0 | grep -E "errors|dropped"
```

#### 3. Configuration Review (15 min)

```bash
# Review all configuration changes
git log --oneline -20

# Verify no uncommitted changes
git status

# Check for deprecated settings
grep -r "deprecated\|obsolete" /etc/ 2>/dev/null

# Audit sudoers file
sudo visudo -c && echo "OK"
```

#### 4. Capacity Planning (10 min)

```bash
# Disk capacity trend
df -h | head -1 && df -h | grep -E "^/"

# Memory utilization trend
# (if you've been tracking: cat operations/logs/memory-trend.log)

# Network utilization trend
# (if you've been tracking: cat operations/logs/bandwidth-trend.log)

# Forecast when capacity will be exceeded
echo "Disk space: $(df -h / | tail -1 | awk '{print $5}')"
```

### Dependency and Service Review (30 min)

```bash
# Verify all critical services are monitored
ps aux | grep -E "dnsmasq|nfs|ssh|chrony"

# Check for orphaned processes
ps aux | grep -v "pi\|root\|daemon" | grep -v "^USER"

# Review systemd service status
sudo systemctl list-units --type=service --all | grep -E "dnsmasq|nfs|ssh|chrony|ufw"

# Check service dependencies
systemctl list-dependencies --all
```

### Documentation Update (20 min)

```bash
# Update IP address table
# Edit: docs/network-config.md

# Update service topology
# Edit: docs/service-topology.md

# Review and update runbooks
ls -la operations/procedures/

# Verify contact information is current
grep -r "contact\|phone\|email" docs/ config/ | grep -v ".git"
```

### Archive Old Logs (10 min)

```bash
# Compress old logs
find operations/logs -name "*.log" -mtime +30 -exec gzip {} \;

# Archive to backup location
tar czf logs-archive-$(date +%Y%m).tar.gz operations/logs/*.gz

# Move to long-term storage
mv logs-archive-*.tar.gz operations/backups/archive/

# Verify archive
tar tzf operations/backups/archive/logs-archive-*.tar.gz | head
```

---

## Scheduled Tasks via Cron

Add to crontab for automation:

```bash
# Edit crontab
sudo crontab -e

# Add entries:

# Daily status check at 8 AM
0 8 * * * /usr/local/bin/cluster-status.sh > /var/log/cluster-status.log 2>&1

# Daily backup at 2 AM
0 2 * * * /home/pi/operations/backups/backup-daily.sh

# Weekly configuration validation at 10 AM Wednesday
0 10 * * 3 /home/pi/scripts/validate-config.sh > /var/log/validate.log 2>&1

# Monthly health check at 10 AM on the 1st
0 10 1 * * /home/pi/operations/health-check.sh

# Hourly monitoring check
0 * * * * /usr/local/bin/health-check.sh

# View crontab
sudo crontab -l
```

---

## Troubleshooting

### Service Not Responding

```bash
# 1. Check service status
sudo systemctl status service-name

# 2. View recent logs
sudo journalctl -u service-name -n 50 -p warning

# 3. Restart service
sudo systemctl restart service-name

# 4. Verify port is listening
sudo ss -tlnp | grep service-name

# 5. Check logs again
sudo journalctl -u service-name -f  # Follow in real-time
```

### High Disk Usage

```bash
# Find largest files/directories
du -sh /* | sort -h | tail -10

# Check specific directory
du -sh config/ deployments/ operations/

# Identify old/unused files
find . -type f -mtime +90 -exec ls -lh {} \;

# Clean up old logs
sudo find /var/log -type f -name "*.log.*" -delete

# Check backup size
du -sh operations/backups/
```

### Network Connectivity Issues

```bash
# Test connectivity
ping gateway
ping 8.8.8.8
ping boot-node

# Check interfaces
ip link show
ip addr show

# Verify routing
ip route show

# Test DNS
nslookup boot-node
nslookup google.com

# Check port connectivity
telnet boot-node 22
telnet boot-node 53
```

### SSH Access Issues

```bash
# Test SSH verbosely
ssh -vvv pi@boot-node

# Check SSH service
sudo systemctl status ssh
sudo systemctl restart ssh

# Verify SSH key permissions
ls -la ~/.ssh/id_rsa

# Check authorized_keys
cat ~/.ssh/authorized_keys

# Review SSH logs
sudo journalctl -u ssh -n 20
```

### NFS Mount Issues

```bash
# List available exports
showmount -e boot-node

# Test mount manually
sudo mkdir -p /mnt/test
sudo mount -t nfs boot-node:/export /mnt/test
df /mnt/test

# Check NFS service
sudo systemctl status nfs-server
sudo systemctl restart nfs-server

# Verify NFS port listening
sudo ss -tlnp | grep nfs

# Review NFS logs
sudo journalctl -u nfs | tail -20
```

---

## Escalation Procedures

### Low Priority Issues (Response: 24 hours)

- Configuration warnings
- Non-critical service degradation
- Performance below baseline but operational
- Minor log warnings

**Action:** Log issue, plan fix for next maintenance window

### Medium Priority Issues (Response: 4 hours)

- Single critical service down (but not affecting operations)
- Data corruption risk
- Security warning (not critical)
- Performance 50% below baseline

**Action:** Contact on-call, implement temporary workaround

### High Priority Issues (Response: 1 hour)

- Critical service down affecting operations
- Data loss in progress
- Security vulnerability exploited
- Complete system failure

**Action:** Declare emergency, activate recovery procedures

### Critical Issues (Response: Immediate)

- Complete cluster failure
- Data destruction in progress
- Security breach confirmed
- Physical hardware failure

**Action:** Activate disaster recovery, notify all stakeholders

---

## Contact Information

**On-Call Engineer:** [Name] [Phone] [Email]  
**Backup Engineer:** [Name] [Phone] [Email]  
**System Owner:** [Name] [Phone] [Email]  
**Escalation Manager:** [Name] [Phone] [Email]  

---

## Related Documents

- [SECURITY-BASELINE.md](../SECURITY-BASELINE.md)
- [GIT-WORKFLOW.md](../GIT-WORKFLOW.md)
- [FOLDER-STRUCTURE.md](../FOLDER-STRUCTURE.md)
- [troubleshooting.md](../docs/troubleshooting.md)
- [quick-start.md](../docs/quick-start.md)

---

**Last Updated:** December 25, 2025  
**Next Review Date:** January 25, 2026  
**Maintained By:** [Your Name]

# Cluster Deployment Guide

**Quick Start to Production in 4 Steps**

---

## ⚡ 30-Second Setup

```bash
cd ~/Portable-Pi-5-Cluster-Server

# Option 1: Interactive (guided) deployment
sudo ./scripts/deployment-coordinator.sh

# Option 2: Automated full deployment
sudo ./scripts/deployment-coordinator.sh full
```

---

## 📋 Pre-Deployment Checklist

Before starting deployment:

- [ ] Raspberry Pi 5 with Raspberry Pi OS installed
- [ ] All 4 nodes connected to network (or can PXE boot)
- [ ] SSH access enabled on boot node
- [ ] Stable 5V power supply for all nodes
- [ ] Sufficient disk space (2GB+ root, 10GB+ /srv)
- [ ] Read `docs/quick-start.md` for hardware setup

---

## 🚀 Full Deployment (Choose One)

### Option A: Interactive Menu (Recommended for First-Time)

```bash
sudo ./scripts/deployment-coordinator.sh
```

Follow the prompts:
1. Pre-flight checks
2. Validate configuration  
3. Boot node setup (choose stage)
4. Worker nodes (choose deployment)
5. Health verification

**Duration:** ~20-30 minutes depending on internet speed

### Option B: Fully Automated

```bash
sudo ./scripts/deployment-coordinator.sh full
```

Runs all 8 stages automatically:
1. ✓ Pre-flight checks
2. ✓ Configuration validation
3. ✓ Boot node phase 1 (system setup)
4. ✓ Boot node phase 2 (services)
5. ✓ Boot node phase 3 (config)
6. ✓ Boot node phase 4 (verify)
7. ✓ Worker node setup (ISR/Mesh/VHF)
8. ✓ Optimization & security

**Duration:** ~45 minutes

### Option C: Boot Node Only

```bash
sudo ./scripts/deployment-coordinator.sh boot
```

Just sets up the boot node (DHCP, DNS, NFS, time sync).  
Use this to test infrastructure before adding worker nodes.

**Duration:** ~10 minutes

---

## 🔍 Verification & Monitoring

After deployment, verify everything is working:

### Quick Health Check
```bash
./scripts/health-check-all.sh
```

Shows:
- System health (disk, memory, load, temperature)
- Network connectivity (DNS, gateway, IP)
- Service status (SSH, DNS, NFS, NTP)
- Security status (firewall, fail2ban)
- Data integrity checks

**Output:** Pass/Warn/Fail for each check

### Cluster Status Report
```bash
./scripts/cluster-orchestrator.sh report
```

Shows all 4 nodes:
- Uptime
- Disk usage
- Memory usage
- CPU load

### Performance Analysis
```bash
./scripts/performance-monitor.sh analyze
```

Shows:
- CPU metrics (cores, frequency, load)
- Memory stats (total, used, free)
- Disk I/O performance
- Network health
- Thermal status

### Continuous Monitoring
```bash
./scripts/performance-monitor.sh monitor 300
```

Runs continuous monitoring every 5 minutes (press Ctrl+C to stop).

---

## 📦 Backup & Recovery

### Create Backup
```bash
./operations/backups/backup-restore-manager.sh create
```

Creates complete backup of:
- Configuration files
- System state
- Application data
- Database

Stored in: `/var/backups/cluster-backups/`

### List Backups
```bash
./operations/backups/backup-restore-manager.sh list
```

### Verify Backup Integrity
```bash
./operations/backups/backup-restore-manager.sh verify
```

### Restore from Backup
```bash
sudo ./operations/backups/backup-restore-manager.sh restore
```

Interactive restore menu - choose which backup to restore.

### Cleanup Old Backups
```bash
./operations/backups/backup-restore-manager.sh cleanup 7
```

Removes backups older than 7 days.

---

## 🔧 Advanced Operations

### Validate Configuration
```bash
./scripts/validate-all-configs.sh
```

Pre-deployment validation - runs 80+ checks:
- Config file syntax
- Required files present
- Correct permissions
- Valid config values

### Deploy to Specific Node
```bash
./scripts/cluster-orchestrator.sh deploy-isr
./scripts/cluster-orchestrator.sh deploy-mesh
./scripts/cluster-orchestrator.sh deploy-vhf
```

### Parallel Operations on All Nodes
```bash
# Update all nodes
./scripts/cluster-orchestrator.sh update-all

# Time sync all nodes
./scripts/cluster-orchestrator.sh sync-time

# Collect logs from all nodes
./scripts/cluster-orchestrator.sh collect-logs all

# Health check all nodes
./scripts/cluster-orchestrator.sh health-all
```

### Orchestrated Cluster Reboot
```bash
sudo ./scripts/cluster-orchestrator.sh reboot-all
```

Reboots all nodes in sequence with verification.

### System Optimization
```bash
sudo ./scripts/performance-monitor.sh optimize
```

Applies performance optimizations:
- Memory management (swappiness, overcommit)
- I/O scheduling
- Network buffer tuning

---

## 📊 Deployment Stages Explained

### Stage 1: Infrastructure Setup
- Package updates
- Basic system configuration
- Boot node Phase 1

**Status:** Ready ✓

### Stage 2: Service Installation
- Install DHCP/DNS (dnsmasq)
- Install NFS server
- Install TFTP server
- Install NTP/Chrony
- Boot node Phase 2

**Status:** Ready ✓

### Stage 3: Configuration
- Load config files from `config/` directory
- Configure DHCP ranges
- Configure DNS zones
- Configure NFS exports
- Configure time sync
- Boot node Phase 3

**Status:** Ready ✓

### Stage 4: Verification
- Test all services
- Verify network connectivity
- Validate config syntax
- Boot node Phase 4

**Status:** Ready ✓

### Stage 5: Worker Nodes
- ISR node setup (RF monitoring, GnuRadio, dump1090)
- Mesh node setup (Reticulum, LoRa, MQTT)
- VHF node setup (FLdigi, Direwolf, audio)

**Status:** Ready ✓

### Stage 6: Optimization
- Establish performance baseline
- Apply system optimizations
- Tune CPU, memory, I/O, network

**Status:** Ready ✓

### Stage 7: Security
- Enable firewall (ufw)
- Enable fail2ban
- Harden SSH
- Set kernel parameters

**Status:** Ready ✓

### Stage 8: Backup
- Create initial configuration backup
- Store manifest

**Status:** Ready ✓

---

## 🆘 Troubleshooting

### Deployment Fails at Validation
```bash
# Check what's wrong
./scripts/validate-all-configs.sh

# Review any warnings
# Fix issues manually or check docs/troubleshooting.md
```

### Nodes Won't Connect to Network
```bash
# Check DHCP is working
cat /var/lib/misc/dnsmasq.leases

# Check DNS resolution
nslookup 8.8.8.8

# Verify NFS export
showmount -e localhost
```

### Performance is Slow
```bash
# Analyze bottleneck
./scripts/performance-monitor.sh analyze

# Get optimization recommendations
./scripts/performance-monitor.sh recommend

# Apply optimizations
sudo ./scripts/performance-monitor.sh optimize
```

### Need to Check Logs
```bash
# Boot node deployment log
tail -f /var/log/deployment/*.log

# Health check details
cat /var/log/health-checks/*.log

# Performance analysis
cat /var/log/performance/*.log

# Cluster management
cat /var/log/cluster-mgmt/*.log
```

### Want to Start Over
```bash
# Restore from backup
sudo ./operations/backups/backup-restore-manager.sh restore

# Or backup and start fresh
./operations/backups/backup-restore-manager.sh create
# Then redeploy
sudo ./scripts/deployment-coordinator.sh full
```

---

## 📝 Configuration Files

All configuration files are in `config/` directory:

```
config/
├── boot/              # Raspberry Pi boot config
│   ├── cmdline.txt    # Kernel command line
│   └── config.txt     # Device configuration
├── network/           # Network configuration
│   ├── dnsmasq.conf   # DHCP/DNS
│   ├── hostname       # System hostname
│   └── hosts          # Static hostname mapping
├── nfs/               # NFS server
│   ├── exports        # NFS share definitions
│   └── fstab          # Mount points
└── ntp/               # Time synchronization
    ├── chrony.conf    # Chrony time sync
    └── gpsd          # GPS daemon config
```

Modify these files before first deployment to customize:
- DHCP IP range
- DNS server addresses
- NFS mount paths
- NTP servers
- System hostname

---

## 🎯 Common Next Steps

### After Basic Deployment
1. Verify all nodes are accessible
2. Check health status
3. Establish performance baseline
4. Create first backup

### To Monitor Nodes
1. Run continuous health checks
2. Set up performance monitoring
3. Configure log rotation
4. Review logs regularly

### To Add New Nodes
1. Physical setup with Raspberry Pi OS
2. SSH key setup for authentication
3. Run node-specific setup script
4. Verify with health checks
5. Add to cluster-orchestrator.sh node list

### To Customize Configuration
1. Edit files in `config/` directory
2. Validate with `validate-all-configs.sh`
3. Test deployment on single node first
4. Use `cluster-orchestrator.sh` to push to all nodes

---

## 📞 Support Resources

- **Quick Start:** `docs/quick-start.md`
- **Troubleshooting:** `docs/troubleshooting.md`
- **Hardware Guide:** `docs/hardware.md`
- **Full Documentation:** `docs/INDEX.md`
- **Implementation Details:** `IMPLEMENTATION-SUMMARY.md`

---

## ✅ Post-Deployment Checklist

After successful deployment:

- [ ] All health checks passing
- [ ] All 4 nodes responding to ping
- [ ] NFS mounts working
- [ ] DNS resolution working
- [ ] Time sync verified
- [ ] Firewall enabled
- [ ] Initial backup created
- [ ] Performance baseline established
- [ ] Cluster report generated
- [ ] Documentation reviewed

---

## 🔐 Security Best Practices

After deployment:

1. **Change SSH Port** (in production)
   ```bash
   sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
   ```

2. **Enable Firewall Rules**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 53/udp
   sudo ufw allow 111/tcp
   sudo ufw allow 2049/tcp
   ```

3. **Set Up SSH Keys** (remove password auth)
   ```bash
   ssh-keygen -t ed25519
   ssh-copy-id -i ~/.ssh/id_ed25519.pub user@node
   ```

4. **Regular Backups**
   ```bash
   # Daily backup via cron
   0 2 * * * /path/to/backup-restore-manager.sh create
   ```

5. **Review Security Status**
   ```bash
   ./scripts/health-check-all.sh  # Check security sections
   ```

---

**Last Updated:** December 25, 2025  
**Status:** Production Ready ✅  
**Estimated Setup Time:** 30-60 minutes

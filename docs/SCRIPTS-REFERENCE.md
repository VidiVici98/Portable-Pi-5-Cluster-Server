# Deployment & Automation Scripts - Quick Reference

**Date Created:** December 25, 2025  
**Purpose:** Executable scripts for safe boot node deployment and daily operations

---

## Phase A: Boot Node Deployment Scripts

These scripts deploy the boot node in 4 safe, sequential phases. Each can be run independently.

### Usage
```bash
# Run all 4 phases in order
cd /path/to/cluster/server
sudo bash deployments/boot-node/01-system-setup.sh
sudo bash deployments/boot-node/02-install-services.sh
sudo bash deployments/boot-node/03-configure-services.sh
sudo bash deployments/boot-node/04-verify-setup.sh
```

### Phase 1: System Setup (01-system-setup.sh)
**What it does:**
- Updates system packages
- Installs essential tools (curl, wget, git, vim, build-essential, etc.)
- Sets hostname to `boot-node`
- Configures locale and timezone (UTC)
- Applies kernel security hardening
- Verifies system readiness

**Time:** ~10-15 minutes  
**Safety:** Non-destructive, can run multiple times  
**Requires:** Root/sudo access

**Run it:**
```bash
sudo bash deployments/boot-node/01-system-setup.sh
```

### Phase 2: Install Services (02-install-services.sh)
**What it does:**
- Installs DHCP/DNS server (dnsmasq)
- Installs TFTP server (tftp-hpa)
- Installs NFS server (nfs-kernel-server)
- Installs time sync (chrony, gpsd)
- Installs firewall (ufw)
- Installs brute force protection (fail2ban)
- Installs monitoring utilities (htop, iotop, nethogs, etc.)

**Time:** ~5-10 minutes  
**Safety:** Installation only, services not yet enabled  
**Requires:** Root/sudo access, internet

**Run it:**
```bash
sudo bash deployments/boot-node/02-install-services.sh
```

### Phase 3: Configure Services (03-configure-services.sh)
**What it does:**
- Deploys SSH hardening (from `config/security/sshd_config`)
- Deploysbrute force protection (from `config/security/fail2ban.conf`)
- Configures DHCP/DNS (from `config/network/dnsmasq.conf`)
- Configures NFS (from `config/nfs/exports`)
- Configures NTP/time sync (from `config/ntp/chrony/chrony.conf`)
- Sets up TFTP boot files
- Configures UFW firewall rules
- Starts all services

**Time:** ~5 minutes  
**Safety:** Uses existing configs, idempotent (safe to re-run)  
**Requires:** Root/sudo access, existing config files

**Run it:**
```bash
sudo bash deployments/boot-node/03-configure-services.sh
```

### Phase 4: Verify Setup (04-verify-setup.sh)
**What it does:**
- Tests system health (memory, disk, load, temp)
- Verifies all services are running
- Tests network connectivity
- Tests SSH access
- Tests DHCP/DNS
- Tests NFS
- Tests TFTP
- Tests NTP time sync
- Verifies firewall is active
- Checks security configurations
- Generates comprehensive test report

**Time:** ~2-5 minutes  
**Safety:** Read-only testing, no modifications  
**Requires:** Root/sudo access for some tests

**Run it:**
```bash
sudo bash deployments/boot-node/04-verify-setup.sh
```

**Exit code meanings:**
- `0` = All tests passed ✓
- `1` = One or more tests failed ✗

---

## Phase C: Automation Scripts

These are utility scripts for daily operations.

### Backup Script (operations/backups/backup-daily.sh)

**Purpose:** Automated backup of configuration and system state

**What it does:**
- Backs up `config/` directory (excluding secrets)
- Backs up `scripts/` directory
- Backs up system configurations (/etc/ssh, /etc/dnsmasq.d, etc.)
- Compresses all to tar.gz files
- Verifies backup integrity
- Cleans up backups older than 14 days
- Logs all actions

**Time:** ~2-5 minutes  
**Safety:** Non-destructive, creates backups only

**Run manually:**
```bash
bash operations/backups/backup-daily.sh
```

**Schedule daily at 2 AM:**
```bash
# Add to root crontab:
sudo crontab -e

# Add this line:
0 2 * * * /path/to/cluster/server/operations/backups/backup-daily.sh
```

**Backup location:**
```
operations/backups/
├── config-20251225.tar.gz
├── scripts-20251225.tar.gz
└── system-config-20251225.tar.gz
```

---

### Health Check Script (operations/maintenance/health-check.sh)

**Purpose:** Monitor system health and security status

**What it checks:**
- System health (memory, disk, CPU load, temperature)
- Service status (all 7 critical services)
- Network connectivity and DNS
- Security (SSH keys, firewall, Fail2Ban, failed logins)
- Open ports (SSH, DNS, DHCP, TFTP, NTP, NFS)
- Recent errors and warnings
- NFS export status
- Backup freshness

**Time:** ~30 seconds  
**Safety:** Read-only, no modifications

**Run with output:**
```bash
bash operations/maintenance/health-check.sh
```

**Run silently (for cron):**
```bash
bash operations/maintenance/health-check.sh quiet
```

**Schedule hourly:**
```bash
# Add to root crontab:
sudo crontab -e

# Add this line (run every hour):
0 * * * * /path/to/cluster/server/operations/maintenance/health-check.sh quiet
```

**Output includes:**
- ✓ (green) = working correctly
- ⚠ (yellow) = warning, needs attention
- ✗ (red) = failure, needs immediate action

**Logs:**
```
operations/logs/health-check.log  # Detailed logs from all runs
```

---

### SSH Key Rotation (scripts/rotate-ssh-keys.sh)

**Purpose:** Safely rotate SSH keys without breaking access

**What it does:**
- Backs up existing keys
- Generates new ED25519 SSH key
- Tests new key works
- Adds new key to authorized_keys
- Optionally removes old keys
- Logs rotation event
- Documents key history

**Time:** ~1 minute  
**Safety:** Non-destructive, all old keys backed up

**Run it:**
```bash
sudo bash scripts/rotate-ssh-keys.sh
```

**Interactive prompts:**
- Will show new public key
- Will ask if you want to remove old keys (defaults to "no" if no response)

**Key locations:**
```
config/secrets/ssh/
├── id_rsa                          # Private key (KEEP SECURE)
├── id_rsa.pub                      # Public key
├── .backup/
│   ├── id_rsa.20251225-120000.bak
│   └── id_rsa.pub.20251225-120000.bak
└── .rotation-history               # Record of rotations
```

**Rotate SSH keys quarterly or when:**
- Team member leaves
- Key may be compromised
- Scheduled maintenance
- Security policy requires it

---

## Cron Schedule Recommendations

Add to root crontab for full automation:

```bash
# Edit crontab
sudo crontab -e

# Add these lines:

# Daily backup at 2 AM
0 2 * * * /home/jon/Portable-Pi-5-Cluster-Server/operations/backups/backup-daily.sh >> /var/log/cluster-cron.log 2>&1

# Hourly health check (silent)
0 * * * * /home/jon/Portable-Pi-5-Cluster-Server/operations/maintenance/health-check.sh quiet >> /var/log/cluster-cron.log 2>&1

# Daily detailed health check at 8 AM
0 8 * * * /home/jon/Portable-Pi-5-Cluster-Server/operations/maintenance/health-check.sh >> /var/log/cluster-health.log 2>&1
```

View current crontab:
```bash
sudo crontab -l
```

View cron logs:
```bash
sudo tail -f /var/log/cluster-cron.log
```

---

## Safety Principles

All scripts follow these safety principles:

✅ **Non-Destructive**
- No production data is deleted or modified
- All changes use existing configs in the repo
- Old files are backed up before modification

✅ **Idempotent**
- Safe to run multiple times
- Won't break if run twice in a row
- State is preserved

✅ **Logged**
- All actions logged to files
- Timestamps on every log entry
- Useful for debugging and audits

✅ **Tested**
- Verification steps included
- Tests run automatically in Phase 4
- Failure modes caught and reported

✅ **Reversible**
- Everything is in git (except secrets)
- Backups stored separately
- Old versions available in git history

---

## Troubleshooting Scripts

### If Phase 1 fails:
```bash
# Check what went wrong
tail -20 /var/log/boot-node-setup.log

# Re-run to continue
sudo bash deployments/boot-node/01-system-setup.sh
```

### If Phase 3 fails:
```bash
# Verify config files exist
ls -la config/network/dnsmasq.conf
ls -la config/nfs/exports
ls -la config/ntp/chrony/chrony.conf

# Check the error in logs
tail -50 /var/log/boot-node-setup.log

# Fix the issue and re-run
sudo bash deployments/boot-node/03-configure-services.sh
```

### If Phase 4 reports failures:
```bash
# Read the failures carefully
# Most include instructions for fixing

# Common issues:
# - Services not running: check logs with journalctl
#   journalctl -u dnsmasq -n 20
# 
# - Ports not listening: check firewall
#   sudo ufw status
#   
# - DNS not resolving: check dnsmasq config
#   sudo dnsmasq --test

# Re-run health check
sudo bash deployments/boot-node/04-verify-setup.sh
```

---

## Next Steps

After deploying with scripts A:

1. **Verify deployment** using Phase 4
2. **Follow operations manual** (operations/OPERATIONS.md)
3. **Set up automation** using scripts C (backup, health-check)
4. **Test from external system:**
   ```bash
   ssh pi@boot-node
   nslookup boot-node
   mount -t nfs boot-node:/srv/cluster /mnt/test
   ```
5. **Document any customizations** to git

---

## File Locations

| Script | Location | Purpose |
|--------|----------|---------|
| Phase 1 | `deployments/boot-node/01-system-setup.sh` | System prep |
| Phase 2 | `deployments/boot-node/02-install-services.sh` | Install packages |
| Phase 3 | `deployments/boot-node/03-configure-services.sh` | Configure & start |
| Phase 4 | `deployments/boot-node/04-verify-setup.sh` | Test & verify |
| Backup | `operations/backups/backup-daily.sh` | Daily backup |
| Health | `operations/maintenance/health-check.sh` | Health monitoring |
| SSH Rotate | `scripts/rotate-ssh-keys.sh` | Key management |

---

**All scripts are version-controlled and can be modified as needed for your environment.**

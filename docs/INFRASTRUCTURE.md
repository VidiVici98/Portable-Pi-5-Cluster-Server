# Infrastructure Setup & Reference

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Complete infrastructure setup and architecture guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Setup](#component-setup)
3. [Configuration Management](#configuration-management)
4. [Deployment Workflow](#deployment-workflow)
5. [Operations & Monitoring](#operations--monitoring)
6. [Security Implementation](#security-implementation)
7. [Disaster Recovery](#disaster-recovery)
8. [Quick Reference](#quick-reference)

---

## Architecture Overview

### System Design

```
┌─────────────────────────────────────────────────────────────┐
│                    Portable Pi 5 Cluster                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Boot Node (Primary)                     │   │
│  │  ┌────────────────────────────────────────────┐     │   │
│  │  │ DHCP/TFTP/DNS (dnsmasq)                   │     │   │
│  │  │ NFS Server                                │     │   │
│  │  │ Time Server (chrony/GPS)                  │     │   │
│  │  │ Cluster Monitor                           │     │   │
│  │  └────────────────────────────────────────────┘     │   │
│  │                                                       │   │
│  │  Config: config/overlays/boot-node/                 │   │
│  └──────────────────────────────────────────────────────┘   │
│           │              │              │                    │
│           ▼              ▼              ▼                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐          │
│  │ ISR Node    │  │ Mesh Node   │  │ VHF Node    │          │
│  │ (Compute)   │  │ (Routing)   │  │ (Radio)     │          │
│  │ NFS Client  │  │ NFS Client  │  │ NFS Client  │          │
│  └─────────────┘  └─────────────┘  └─────────────┘          │
│                                                               │
└─────────────────────────────────────────────────────────────┘

Network: 10.0.0.0/8 (primary), 192.168.0.0/16 (secondary)
Services: DHCP (67/68), TFTP (69), DNS (53), NFS (2049), SSH (22), NTP (123)
```

### Key Components

| Component | Purpose | Port | Configuration |
|-----------|---------|------|-----------------|
| DHCP | Node IP allocation | 67/68 | `dnsmasq.conf` |
| TFTP | Network boot | 69 | `tftp-hpa` |
| DNS | Name resolution | 53 | `dnsmasq.conf` |
| NFS | Shared storage | 2049 | `exports` |
| SSH | Remote access | 22 | `sshd_config` |
| NTP | Time sync | 123 | `chrony.conf` |
| GPS | Time reference | Serial | `gpsd` |
| UFW | Firewall | N/A | `firewall.ufw` |

---

## Component Setup

### Phase 1: Boot Node Foundation

**1. System Preparation**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install core packages
sudo apt install -y curl wget git build-essential

# Configure hostname
sudo hostnamectl set-hostname boot-node
sudo hostnamectl set-location "Emergency Comms"

# Configure static IP
sudo nano /etc/dhcpcd.conf
# Add: interface eth0
#      static ip_address=10.0.0.1/24
#      static routers=10.0.0.1
#      static domain_name_servers=10.0.0.1
```

**2. DHCP Server (dnsmasq)**

```bash
# Install dnsmasq
sudo apt install -y dnsmasq

# Copy configuration
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.d/cluster.conf

# Verify configuration
sudo dnsmasq --test

# Start service
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

# Test DHCP
sudo dhclient -v eth0  # Request lease
```

**3. TFTP Server**

```bash
# Install tftp-hpa
sudo apt install -y tftp-hpa tftpd-hpa

# Create boot directory
sudo mkdir -p /srv/tftp/boot
sudo chmod 777 /srv/tftp

# Copy boot files
sudo cp /boot/bootcode.bin /srv/tftp/boot/
sudo cp /boot/start*.elf /srv/tftp/boot/
sudo cp /boot/fixup*.dat /srv/tftp/boot/
sudo cp /boot/kernel*.img /srv/tftp/boot/
sudo cp /boot/cmdline.txt /srv/tftp/boot/
sudo cp /boot/config.txt /srv/tftp/boot/

# Start service
sudo systemctl enable tftpd-hpa
sudo systemctl start tftpd-hpa

# Test TFTP
tftp boot-node <<EOF
get boot/bootcode.bin
quit
EOF
```

**4. NFS Server**

```bash
# Install NFS
sudo apt install -y nfs-kernel-server

# Copy configuration
sudo cp config/nfs/exports /etc/exports

# Create export directory
sudo mkdir -p /srv/cluster
sudo chmod 755 /srv/cluster

# Apply exports
sudo exportfs -a
sudo exportfs -v  # Verify

# Start service
sudo systemctl enable nfs-server
sudo systemctl start nfs-server

# Test mount from localhost
sudo mkdir -p /mnt/test
sudo mount -t nfs localhost:/srv/cluster /mnt/test
df /mnt/test
sudo umount /mnt/test
```

**5. DNS Server**

```bash
# dnsmasq provides DNS (already installed)

# Verify DNS working
nslookup boot-node 127.0.0.1
nslookup 8.8.8.8 127.0.0.1  # External query

# Test from other system
nslookup boot-node 10.0.0.1
```

**6. Time Server (chrony + GPS)**

```bash
# Install chrony
sudo apt install -y chrony

# Install GPS daemon
sudo apt install -y gpsd gpsd-clients

# Copy configuration
sudo cp config/ntp/chrony/chrony.conf /etc/chrony/chrony.conf

# Start services
sudo systemctl enable chrony gpsd
sudo systemctl start chrony gpsd

# Verify sync
chronyc tracking
ntpdate -q 10.0.0.1  # Test from remote node
```

### Phase 2: Security Hardening

**1. Firewall (UFW)**

```bash
# Install UFW
sudo apt install -y ufw

# Copy configuration
sudo cp config/security/firewall.ufw /etc/ufw/ufw.conf

# Configure rules (from firewall.ufw comments)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from local network
sudo ufw allow from 10.0.0.0/8 to any port 22 proto tcp

# Allow DHCP/TFTP/DNS from local network
sudo ufw allow from 10.0.0.0/8 to any port 67 proto udp
sudo ufw allow from 10.0.0.0/8 to any port 68 proto udp
sudo ufw allow from 10.0.0.0/8 to any port 69 proto udp
sudo ufw allow from 10.0.0.0/8 to any port 53

# Allow NFS from local network
sudo ufw allow from 10.0.0.0/8 to any port 111 proto tcp
sudo ufw allow from 10.0.0.0/8 to any port 2049 proto tcp

# Allow NTP
sudo ufw allow from 10.0.0.0/8 to any port 123 proto udp

# Enable firewall
sudo ufw enable

# Verify rules
sudo ufw status verbose
```

**2. SSH Hardening**

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_rsa -N ""

# Copy hardened SSH config
sudo cp config/security/sshd_config /etc/ssh/sshd_config
sudo chown root:root /etc/ssh/sshd_config
sudo chmod 600 /etc/ssh/sshd_config

# Add public key to authorized_keys
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Test SSH config
sudo sshd -t

# Restart SSH
sudo systemctl restart ssh

# Test login
ssh -i ~/.ssh/id_rsa pi@localhost "echo Connected"
```

**3. Fail2Ban**

```bash
# Install Fail2Ban
sudo apt install -y fail2ban

# Copy configuration
sudo cp config/security/fail2ban.conf /etc/fail2ban/jail.local
sudo chown root:root /etc/fail2ban/jail.local
sudo chmod 600 /etc/fail2ban/jail.local

# Start service
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verify
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

**4. Kernel Hardening**

```bash
# Copy sysctl configuration
sudo cp config/security/sysctl.conf /etc/sysctl.d/99-hardening.conf
sudo chown root:root /etc/sysctl.d/99-hardening.conf
sudo chmod 644 /etc/sysctl.d/99-hardening.conf

# Apply settings
sudo sysctl -p /etc/sysctl.d/99-hardening.conf

# Verify key settings
sysctl net.ipv4.ip_forward
sysctl kernel.randomize_va_space
sysctl net.ipv4.tcp_syncookies
```

**5. Sudoers Configuration**

```bash
# Copy sudoers file
sudo cp config/security/sudoers /etc/sudoers.d/cluster
sudo chown root:root /etc/sudoers.d/cluster
sudo chmod 440 /etc/sudoers.d/cluster

# Verify syntax
sudo visudo -c

# Test sudo access
sudo -l
```

### Phase 3: Secrets & Backup

**1. Generate Secrets**

```bash
# Create secrets directory (if not exists)
mkdir -p config/secrets/ssh config/secrets/tls config/secrets/api

# Generate SSH keypair
ssh-keygen -t ed25519 -f config/secrets/ssh/id_rsa -N ""

# Generate TLS certificate (self-signed)
openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout config/secrets/tls/server.key \
  -out config/secrets/tls/server.crt

# Set permissions
chmod 600 config/secrets/ssh/id_rsa
chmod 600 config/secrets/tls/server.key
chmod 644 config/secrets/tls/server.crt

# Create API credentials file
cat > config/secrets/api/credentials.conf << 'EOF'
# API Credentials
# NEVER commit to git
RADIO_API_KEY="set-your-api-key"
RADIO_API_SECRET="set-your-api-secret"
EOF
chmod 600 config/secrets/api/credentials.conf

# Copy to system location
sudo cp config/secrets/ssh/id_rsa ~/.ssh/
sudo cp config/secrets/tls/* /etc/ssl/certs/
```

**2. Setup Backups**

```bash
# Create backup directory
mkdir -p operations/backups operations/logs

# Create backup script
cat > operations/backups/backup-daily.sh << 'EOF'
#!/bin/bash
# Daily backup of critical configuration

BACKUP_DIR="operations/backups"
DATE=$(date +%Y%m%d)

# Backup configuration
tar czf "$BACKUP_DIR/config-$DATE.tar.gz" config/ --exclude="config/secrets"

# Backup secrets (encrypted)
tar czf - config/secrets | gpg --encrypt --trust-model always \
  --recipient your-gpg-key > "$BACKUP_DIR/secrets-$DATE.tar.gz.gpg"

# Log backup
echo "Backup completed at $(date)" >> operations/logs/backup.log

# Cleanup old backups (keep 14 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +14 -delete
EOF

chmod +x operations/backups/backup-daily.sh

# Add to crontab
sudo crontab -e
# Add: 0 2 * * * /home/pi/operations/backups/backup-daily.sh
```

---

## Configuration Management

### Template System

The configuration system uses a **template → overlay → deployed** workflow:

```
config/templates/              # Base templates with placeholders
  ├── dnsmasq.conf.template    # Base DHCP/DNS config
  ├── exports.template         # Base NFS exports
  ├── chrony.conf.template     # Base NTP config
  └── ...

config/overlays/               # Node-specific customizations
  ├── boot-node/               # Boot node overrides
  │   ├── dnsmasq.conf
  │   ├── exports
  │   └── chrony.conf
  ├── isr-node/                # ISR node overrides
  ├── mesh-node/               # Mesh node overrides
  └── vhf-node/                # VHF node overrides

Deployed to:
  /etc/dnsmasq.d/
  /etc/exports
  /etc/chrony/
  /etc/ssh/
  etc.
```

### Configuration Workflow

**1. Create Base Template**
```bash
# Start with template
cp config/templates/dnsmasq.conf.template config/templates/dnsmasq.conf

# Add placeholders
# DHCP range: {{DHCP_START}} - {{DHCP_END}}
# DNS server: {{DNS_IP}}
```

**2. Create Node Overlay**
```bash
# Copy to overlay directory
cp config/templates/dnsmasq.conf config/overlays/boot-node/dnsmasq.conf

# Substitute values
sed -i 's/{{DHCP_START}}/10.0.0.100/g' config/overlays/boot-node/dnsmasq.conf
sed -i 's/{{DHCP_END}}/10.0.0.200/g' config/overlays/boot-node/dnsmasq.conf
```

**3. Deploy to System**
```bash
# Copy overlay to system location
sudo cp config/overlays/boot-node/dnsmasq.conf /etc/dnsmasq.d/cluster.conf

# Verify
sudo dnsmasq --test
```

**4. Test**
```bash
# Validate
./scripts/validate-config.sh
```

**5. Commit**
```bash
# Version control
git add config/overlays/boot-node/dnsmasq.conf
git commit -m "conf: update DHCP range for boot node"
```

---

## Deployment Workflow

### Step-by-Step Deployment

**1. Pre-Deployment (See: [PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md))**

```bash
# Verify all prerequisites
make test
./scripts/validate-config.sh

# Backup current state
tar czf backup-$(date +%Y%m%d).tar.gz config/ operations/
```

**2. System Setup (30 min)**

```bash
# Follow: deployments/boot-node/01-system-setup.sh
# - Update system
# - Install core packages
# - Configure hostname
# - Set static IP
# - Configure timezone
```

**3. Service Installation (20 min)**

```bash
# Follow: deployments/boot-node/02-install-services.sh
# - Install dnsmasq
# - Install nfs-kernel-server
# - Install chrony
# - Install gpsd
# - Install ufw
# - Install fail2ban
```

**4. Configuration (15 min)**

```bash
# Follow: deployments/boot-node/03-configure-services.sh
# - Deploy configuration files
# - Create directories
# - Set permissions
# - Start services
# - Verify functionality
```

**5. Validation (10 min)**

```bash
# Follow: deployments/boot-node/04-verify-setup.sh
# - Test DHCP
# - Test TFTP
# - Test DNS
# - Test NFS
# - Test SSH
# - Test time sync
# - Check security
```

**6. Post-Deployment (See: [POST-DEPLOYMENT-CHECKLIST.md](deployments/POST-DEPLOYMENT-CHECKLIST.md))**

```bash
# Verify all systems operational
make status

# Perform acceptance tests
./scripts/validate-config.sh

# Commit deployment
git add .
git commit -m "deploy: boot node operational"
```

---

## Operations & Monitoring

### Daily Operations

See [operations/OPERATIONS.md](operations/OPERATIONS.md) for:
- Morning system check (10 min)
- Monitoring alerts (continuous)
- Log review (5 min, 2x daily)

### Backup Procedures

**Automatic Backups:**
```bash
# crontab: 0 2 * * * /home/pi/operations/backups/backup-daily.sh

# Includes:
# - Configuration files
# - Secrets (encrypted)
# - System state
# - Logs
```

**Manual Backup:**
```bash
./operations/backups/backup-daily.sh
```

**Restore from Backup:**
```bash
./operations/recovery/restore-from-backup.sh
```

### Monitoring

**System Status:**
```bash
make status          # Quick status
make status-full     # Detailed status
make test           # Comprehensive test
```

**Service Monitoring:**
```bash
sudo systemctl status dnsmasq nfs-server ssh chrony ufw
```

**Log Monitoring:**
```bash
sudo journalctl -f  # Follow all logs
sudo journalctl -u ssh -f  # Follow SSH logs
sudo journalctl -p err -f  # Follow errors only
```

---

## Security Implementation

### Security Checklist

1. ✅ **SSH Hardening** - Key-based auth only, no root access
2. ✅ **Firewall** - UFW enabled with restricted rules
3. ✅ **Brute Force Protection** - Fail2Ban configured
4. ✅ **Kernel Hardening** - sysctl parameters applied
5. ✅ **Secrets Management** - Credentials in git-ignored directory
6. ✅ **Audit Logging** - All changes logged
7. ✅ **Regular Updates** - Security updates applied

### Security Maintenance

**Weekly:**
```bash
# Check failed login attempts
sudo grep "Failed password" /var/log/auth.log | wc -l

# Verify no world-readable secrets
find config/secrets -type f -perm /077
```

**Monthly:**
```bash
# Check for security updates
sudo apt update && sudo apt list --upgradable

# Review firewall rules
sudo ufw status verbose

# Audit sudoers
sudo visudo -c
```

**Quarterly:**
```bash
# Rotate SSH keys
./operations/maintenance/rotate-ssh-keys.sh

# Rotate certificates
./operations/maintenance/rotate-certificates.sh

# Review user access
awk -F: '($3>=1000)' /etc/passwd
```

---

## Disaster Recovery

### Backup & Recovery Strategy

**Backup Location:** `operations/backups/`  
**Backup Frequency:** Daily (2 AM)  
**Retention:** 14+ days  
**Encryption:** AES-256 (GPG)

### Recovery Procedures

**Complete System Failure:**
```bash
# 1. Boot from fresh Raspberry Pi OS
# 2. Clone git repository
git clone https://github.com/yourname/Portable-Pi-5-Cluster-Server.git

# 3. Run restore script
./operations/recovery/restore-from-backup.sh

# 4. Verify restoration
make test

# 5. Restore secrets
# (Manual process - secrets not in backup repo)
```

**Partial Recovery:**
```bash
# Restore configuration only
tar xzf operations/backups/config-20251225.tar.gz

# Restore secrets
gpg --decrypt operations/backups/secrets-20251225.tar.gz.gpg | tar xz

# Apply configuration
./deployments/boot-node/03-configure-services.sh
```

**Data Loss Recovery:**
```bash
# Check available backups
ls -lh operations/backups/

# Restore data from backup
./operations/recovery/restore-from-backup.sh

# Verify data integrity
./scripts/validate-config.sh
```

---

## Quick Reference

### Common Commands

```bash
# Status
make status              # Quick status
make test               # Full test
make clean              # Clean artifacts

# Operations
sudo systemctl status dnsmasq nfs-server ssh chrony ufw
sudo journalctl -f -u ssh -p err
sudo tail -f /var/log/syslog

# Configuration
./scripts/validate-config.sh
git status
git log --oneline

# Backup
./operations/backups/backup-daily.sh
./operations/recovery/restore-from-backup.sh

# Security
sudo ufw status
sudo fail2ban-client status
sudo journalctl -u fail2ban -f
```

### Troubleshooting Quick Links

| Problem | Solution |
|---------|----------|
| DHCP not working | Check dnsmasq service, verify port 67 open |
| NFS mount fails | Check nfs-server service, verify exports |
| SSH not connecting | Check SSH service, verify firewall rules |
| Time not syncing | Check chrony service, verify NTP server |
| No internet | Check network interface, verify routing |

---

## Related Documentation

- [SECURITY-BASELINE.md](SECURITY-BASELINE.md)
- [FOLDER-STRUCTURE.md](FOLDER-STRUCTURE.md)
- [GIT-WORKFLOW.md](GIT-WORKFLOW.md)
- [operations/OPERATIONS.md](operations/OPERATIONS.md)
- [config/secrets/README.md](config/secrets/README.md)
- [docs/quick-start.md](docs/quick-start.md)
- [docs/troubleshooting.md](docs/troubleshooting.md)

---

**Last Updated:** December 25, 2025  
**Next Review:** January 25, 2026  
**Maintained By:** Your Name

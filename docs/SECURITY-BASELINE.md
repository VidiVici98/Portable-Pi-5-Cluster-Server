# Security Baseline Standards

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Define minimum security standards for all cluster nodes

## Security Framework

This document defines the baseline security standards that every node in the cluster must meet. These are implemented incrementally without breaking existing systems.

## 1. SSH Security

### Hardened SSH Configuration

**File:** `config/security/ssh_hardening.conf`

Policy:
- ✅ Password authentication DISABLED
- ✅ Public key authentication ENABLED
- ✅ Root login DISABLED
- ✅ X11 forwarding DISABLED
- ✅ Protocol version 2 only
- ✅ Strong ciphers only
- ✅ Rate limiting enabled

**Minimum Requirements:**
```bash
PermitRootLogin no                          # No root SSH
PasswordAuthentication no                   # Keys only
PubkeyAuthentication yes                    # Keys required
X11Forwarding no                            # Disable X11
X11UseLocalhost yes
AllowUsers pi                               # Specific users only
Protocol 2
StrictModes yes
MaxAuthTries 3                              # Rate limit
ClientAliveInterval 300
ClientAliveCountMax 2                       # Timeout idle sessions
```

**Implementation:**
```bash
# 1. Generate SSH keys (if needed)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# 2. Deploy key to nodes
ssh-copy-id -i ~/.ssh/id_ed25519.pub pi@192.168.1.20

# 3. Apply hardening (on each node)
sudo cp config/security/ssh_hardening.conf /etc/ssh/sshd_config.d/hardening.conf
sudo systemctl restart ssh

# 4. Verify (do NOT lock yourself out)
ssh -T pi@192.168.1.20 "echo OK"  # Must work before disconnect
```

### SSH Key Management

**Location:** `config/secrets/ssh-keys/`

**Policy:**
- ✅ Private keys in `config/secrets/` (not in git)
- ✅ Public keys in `deployments/` (can be in git)
- ✅ Keys are node-specific where possible
- ✅ Keys rotated annually
- ✅ Key backup encrypted

**Storage:**
```bash
config/secrets/ssh-keys/
├── README.md                    # How to manage keys
├── cluster-deploy (private)     # Deployment key (secrets/)
├── cluster-deploy.pub (public)  # Public key (can commit)
└── node-specific/              # Per-node keys
```

---

## 2. Firewall Configuration

### UFW Baseline

**File:** `config/security/firewall.ufw`

**Default Policy:**
- Incoming: DENY
- Outgoing: ALLOW
- Routed: DENY

**Allowed Ports by Node:**

**Boot Node:**
```bash
22/tcp      # SSH (administrative access)
53/tcp      # DNS queries
53/udp      # DNS queries
67/udp      # DHCP
69/udp      # TFTP (PXE boot)
111/tcp     # NFS portmapper
111/udp     # NFS portmapper
2049/tcp    # NFS
2049/udp    # NFS
```

**ISR Node:**
```bash
22/tcp      # SSH
```

**Mesh Node:**
```bash
22/tcp      # SSH
4242/udp    # LoRa default
```

**VHF Node:**
```bash
22/tcp      # SSH
```

**Implementation:**
```bash
# 1. Enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny routed

# 2. Allow SSH (BEFORE enabling, or lock yourself out!)
sudo ufw allow 22/tcp

# 3. Allow node-specific ports
# For boot node:
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/udp
sudo ufw allow 69/udp
sudo ufw allow 111/tcp
sudo ufw allow 111/udp
sudo ufw allow 2049/tcp
sudo ufw allow 2049/udp

# 4. Enable (point of no return, ensure SSH works!)
sudo ufw enable

# 5. Verify
sudo ufw status verbose
```

---

## 3. Service Hardening

### Services by Default: DISABLED

**Only run what you need:**

```bash
# Boot Node: Enabled
- dnsmasq (DHCP/DNS/TFTP)
- nfs-server (File sharing)
- ssh (Remote access)
- chrony (Time sync)

# All Nodes: Disabled by default
- avahi-daemon (mDNS - enables discovery)
- cups (Printing - not needed)
- bluetooth (Unless using BT peripherals)
- X11 display server (Headless systems)
```

**Check running services:**
```bash
systemctl list-units --type=service --state=running
```

**Disable unnecessary services:**
```bash
sudo systemctl disable avahi-daemon
sudo systemctl disable cups
sudo systemctl disable bluetooth
sudo systemctl mask unused-service  # Prevent re-enabling
```

---

## 4. File & Directory Permissions

### Principle: Least Privilege

**Configuration Files:**
```bash
chmod 640 /etc/dnsmasq.conf         # Owner: read/write, Group: read
chmod 640 /etc/exports              # Owner: read/write, Group: read
chmod 755 /srv/tftp                 # Readable by all (PXE needs it)
chmod 755 /srv/nfs                  # Readable by all (NFS needs it)
```

**Secret Files:**
```bash
chmod 600 ~/.ssh/id_ed25519         # Only owner can read
chmod 644 ~/.ssh/id_ed25519.pub     # Public (can be world-readable)
chmod 700 ~/.ssh                    # Only owner can access directory
chmod 640 config/secrets/*.conf     # Owner/group read only
```

**Service Accounts:**
```bash
# Services should NOT run as root
# NFS runs as 'nobody' by default
# DHCP runs as 'dnsmasq' by default

# Verify:
ps aux | grep dnsmasq | grep -v root  # Should NOT show root
ps aux | grep nfs | grep -v root       # Should NOT show root
```

---

## 5. Kernel Hardening

**File:** `config/security/sysctl.conf`

**Critical Parameters:**
```bash
# Disable IP forwarding (unless gateway)
net.ipv4.ip_forward=0

# Enable SYN cookies (DDoS protection)
net.ipv4.tcp_syncookies=1

# Disable ICMP redirects
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Enable bad error message protection
net.ipv4.icmp_ignore_bogus_error_responses=1

# Log suspicious packets
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1

# Increase connection backlog
net.ipv4.tcp_max_syn_backlog=4096
```

**Apply kernel settings:**
```bash
sudo sysctl -p config/security/sysctl.conf
```

---

## 6. Fail2Ban Configuration

**File:** `config/security/fail2ban.conf`

**Protection Against Brute Force:**
```bash
# Ban after 5 failed SSH attempts
maxretry = 5

# Ban duration: 1 hour
bantime = 3600

# Check interval: 10 minutes
findtime = 600
```

**Installation:**
```bash
sudo apt install fail2ban

# Copy config
sudo cp config/security/fail2ban.conf /etc/fail2ban/jail.local

# Restart
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status sshd
```

---

## 7. User Access Control

### Sudoers Policy

**File:** `config/security/sudoers`

**Principle:** Only users who NEED sudo have it

```bash
# Good: Specific user, specific commands
%cluster-admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl
%cluster-admins ALL=(ALL) NOPASSWD: /bin/cp /etc/*

# Bad: Full sudo access
# pi ALL=(ALL) NOPASSWD: ALL
```

**Implementation:**
```bash
# 1. Create admin group
sudo groupadd cluster-admins

# 2. Add authorized users
sudo usermod -aG cluster-admins jon

# 3. Edit sudoers safely (ALWAYS use visudo!)
sudo visudo

# 4. Add minimal required commands
%cluster-admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl
%cluster-admins ALL=(ALL) NOPASSWD: /bin/cp
```

---

## 8. Logging & Monitoring

### Enable Security Logging

**System Logs:**
```bash
# SSH authentication attempts
sudo tail -f /var/log/auth.log | grep ssh

# Service failures
sudo journalctl -u dnsmasq -f
sudo journalctl -u nfs-server -f

# Kernel messages (suspicious activity)
sudo dmesg | tail -20
```

**Centralized Log Storage:**
```bash
operations/logs/
├── auth.log         # SSH authentication
├── services.log     # Service startup/failure
├── kernel.log       # Kernel messages
└── security.log     # Security events
```

**Automated Log Rotation:**
```bash
# Logs in /var/log/ rotate automatically via logrotate
# Custom logs configured in /etc/logrotate.d/
```

---

## 9. Regular Security Maintenance

### Daily
- ✅ Monitor SSH login attempts
- ✅ Check failed service starts
- ✅ Review security alerts

### Weekly
- ✅ Review system logs for anomalies
- ✅ Check for unauthorized users
- ✅ Verify firewall rules still correct

### Monthly
- ✅ Check for available security updates
- ✅ Review user access (sudo, SSH keys)
- ✅ Test backup restoration
- ✅ Verify security configurations still applied

### Quarterly
- ✅ Rotate SSH keys
- ✅ Update security documentation
- ✅ Security audit (permissions, services, access)
- ✅ Penetration test (if resources allow)

### Annually
- ✅ Complete security review
- ✅ Audit all access control
- ✅ Review and update security policies

---

## 10. Incident Response

### If Compromised

**Immediate Actions:**
```bash
1. DISCONNECT the system (network cable)
2. DO NOT reboot or shut down gracefully
3. Preserve evidence for analysis
4. Notify team immediately
5. Assess scope of compromise

# After preserving evidence:
6. Restore from clean backup
   ./operations/recovery/restore-from-backup.sh
7. Review what happened
8. Implement fixes to prevent recurrence
9. Audit all systems for similar issues
```

**Prevention:**
- ✅ Backups tested regularly
- ✅ Can restore in < 30 minutes
- ✅ Clean backups identified and verified
- ✅ Recovery procedures documented

---

## 11. Implementation Roadmap

**PHASE 0 (Foundation - Now)**
- [ ] Review security baseline
- [ ] Document current state
- [ ] Create config/security/ directory
- [ ] Create security policies

**PHASE 1 (SSH Hardening)**
- [ ] Generate SSH keys
- [ ] Disable password authentication
- [ ] Disable root login
- [ ] Verify SSH key access works

**PHASE 2 (Firewall)**
- [ ] Install UFW
- [ ] Configure firewall rules per node
- [ ] Test connectivity still works
- [ ] Enable UFW

**PHASE 3 (Service Hardening)**
- [ ] Disable unnecessary services
- [ ] Set proper file permissions
- [ ] Implement Fail2Ban
- [ ] Apply kernel hardening

**PHASE 4 (Monitoring)**
- [ ] Setup centralized logging
- [ ] Configure log rotation
- [ ] Implement security monitoring
- [ ] Create alerts for failures

---

## Security Checklist

Use this before deploying:

```bash
□ SSH Keys generated and deployed
□ Password authentication disabled
□ Root login disabled
□ UFW firewall configured per node
□ Unnecessary services disabled
□ File permissions set correctly
□ Kernel hardening applied
□ Fail2Ban installed and configured
□ Logging enabled and monitored
□ Backups encrypted and tested
□ Documentation updated
□ Team trained on procedures
```

---

## References & Standards

- **CIS Benchmarks:** https://www.cisecurity.org/cis-benchmarks/
- **NIST Cybersecurity Framework:** https://www.nist.gov/cyberframework
- **Raspberry Pi Security Guide:** https://www.raspberrypi.com/documentation/computers/os.html#security
- **OpenSSH Security:** https://man.openbsd.org/sshd_config
- **Linux Kernel Hardening:** https://kernsec.org/wiki/index.php/Kernel_Self_Protection_Project

---

## Questions?

- How do I rotate SSH keys? → `config/secrets/ssh-keys/README.md`
- Did I lock myself out of SSH? → `docs/troubleshooting.md`
- What ports do I need? → See node-specific firewall config above
- How do I test security? → `operations/maintenance/security-audit.sh`

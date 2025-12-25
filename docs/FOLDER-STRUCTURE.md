# Repository Folder Structure & Best Practices

**Version:** 1.0  
**Date:** December 25, 2025  
**Purpose:** Define professional folder organization for scalable operations

## Directory Tree

```
Portable-Pi-5-Cluster-Server/
│
├── config/                          # All configurations
│   ├── templates/                   # Base configuration templates
│   │   ├── README.md               # Template usage guide
│   │   ├── dnsmasq.conf.template   # DHCP/TFTP/DNS template
│   │   ├── exports.template        # NFS exports template
│   │   └── chrony.conf.template    # NTP configuration template
│   │
│   ├── overlays/                    # Node-specific configurations
│   │   ├── boot-node/              # Boot node overrides
│   │   │   ├── dnsmasq.conf
│   │   │   ├── exports
│   │   │   └── README.md
│   │   ├── isr-node/               # ISR node overrides
│   │   ├── mesh-node/              # Mesh node overrides
│   │   └── vhf-node/               # VHF/UHF node overrides
│   │
│   ├── security/                    # Security-related configs
│   │   ├── README.md               # Security policies
│   │   ├── firewall.ufw            # UFW firewall rules
│   │   ├── ssh_hardening.conf      # SSH security settings
│   │   ├── fail2ban.conf           # Fail2Ban configuration
│   │   └── sysctl.conf             # Kernel hardening
│   │
│   ├── secrets/                     # Credentials & secrets (NEVER commit)
│   │   ├── .gitkeep
│   │   ├── README.md               # Secrets management guide
│   │   ├── ssh-keys/               # SSH key pairs (untracked)
│   │   ├── api-keys/               # API credentials (untracked)
│   │   └── certificates/           # TLS certs (untracked)
│   │
│   ├── boot/                        # PXE boot configs (existing)
│   ├── network/                     # Network configs (existing)
│   ├── nfs/                         # NFS configs (existing)
│   ├── ntp/                         # Time sync configs (existing)
│   └── README.md                    # Config directory guide
│
├── deployments/                     # Deployment procedures & scripts
│   ├── README.md                    # Deployment guide
│   ├── PRE-DEPLOYMENT-CHECKLIST.md # Pre-deployment verification
│   ├── POST-DEPLOYMENT-CHECKLIST.md # Post-deployment verification
│   │
│   ├── boot-node/                  # Boot node deployment
│   │   ├── README.md              # Boot node setup guide
│   │   ├── 01-system-setup.sh     # Initial system config
│   │   ├── 02-install-services.sh # Install DHCP/NFS/DNS
│   │   ├── 03-configure-services.sh # Configure services
│   │   └── 04-verify-setup.sh     # Verification tests
│   │
│   └── node-templates/             # Template scripts for other nodes
│       ├── README.md              # Node setup templates
│       ├── isr-node-setup.sh      # ISR node template
│       ├── mesh-node-setup.sh     # Mesh node template
│       └── vhf-node-setup.sh      # VHF node template
│
├── operations/                      # Operational procedures
│   ├── README.md                    # Operations guide
│   │
│   ├── backups/                     # Backup storage & procedures
│   │   ├── README.md              # Backup policy & procedures
│   │   ├── backup-daily.sh        # Daily backup script
│   │   ├── backup-config.sh       # Configuration backup
│   │   ├── .gitkeep               # Keep directory in git
│   │   └── [backups stored here]
│   │
│   ├── recovery/                    # Disaster recovery procedures
│   │   ├── README.md              # Recovery procedures
│   │   ├── restore-from-backup.sh # Restore from backup
│   │   ├── recovery-checklist.md  # What to do if things break
│   │   └── failover-procedures.md # Multi-node failover
│   │
│   ├── logs/                        # Centralized logs (if applicable)
│   │   ├── README.md              # Log management
│   │   ├── .gitkeep
│   │   └── [logs stored here]
│   │
│   ├── maintenance/                 # Maintenance procedures
│   │   ├── README.md              # Maintenance schedule
│   │   ├── weekly-checks.sh       # Weekly verification
│   │   ├── monthly-health.sh      # Monthly health check
│   │   └── upgrade-procedures.md  # How to safely upgrade
│   │
│   └── monitoring/                  # Monitoring configuration
│       ├── README.md              # Monitoring setup
│       ├── health-metrics.sh      # Collect health metrics
│       └── alert-thresholds.conf  # Alert configuration
│
├── scripts/                         # Operational & utility scripts
│   ├── cluster-status.sh           # System diagnostics
│   ├── validate-config.sh          # Configuration validation
│   ├── README.md
│   ├── oled_display_v1.py
│   └── security_monitor_v1.1.py
│
├── docs/                            # Documentation (existing)
│   ├── quick-start.md
│   ├── setup.md
│   ├── hardware.md
│   ├── troubleshooting.md
│   └── README.md
│
├── Makefile                         # Operations orchestration
├── README.md                        # Project overview
├── LICENSE                          # MIT License
├── CONTRIBUTING.md                  # Contribution guidelines
├── PROJECT_STATUS.md                # Project status & roadmap
├── PHASE1-GUIDE.md                  # Phase 1 diagnostics guide
├── QUICK-REFERENCE.md               # Quick command reference
├── FOLDER-STRUCTURE.md              # This file
├── INFRASTRUCTURE.md                # Infrastructure guide
├── SECURITY-BASELINE.md             # Security standards
├── GIT-WORKFLOW.md                  # Git standards
└── .gitignore                       # Git ignore rules
```

## Folder Purpose & Usage

### `config/` - Configuration Management

**Purpose:** All system configurations for all nodes in one place

**Structure:**
- `templates/` - Base configurations with placeholders
- `overlays/` - Node-specific customizations
- `security/` - Security-hardened configurations
- `secrets/` - Credentials (NEVER commit to git)
- `boot/`, `network/`, `nfs/`, `ntp/` - Existing configs

**Workflow:**
```bash
1. Start with templates/
2. Apply overlays/ for each node
3. Add security/ settings
4. Store secrets/ in secure location (vault)
```

### `deployments/` - Deployment Procedures

**Purpose:** How to set up each type of node

**Contains:**
- Step-by-step deployment scripts
- Pre-deployment and post-deployment checklists
- Node-specific setup procedures
- Verification tests

**Usage:**
```bash
# Deploy boot node
./deployments/boot-node/01-system-setup.sh
./deployments/boot-node/02-install-services.sh
./deployments/boot-node/03-configure-services.sh
./deployments/boot-node/04-verify-setup.sh
```

### `operations/` - Ongoing Operations

**Purpose:** How to maintain, backup, recover, and monitor

**Subfolders:**
- `backups/` - Automated backup procedures & storage
- `recovery/` - Disaster recovery procedures
- `logs/` - Centralized logging
- `maintenance/` - Regular maintenance tasks
- `monitoring/` - Health checks & alerts

**Usage:**
```bash
# Daily backup
make daily-backup

# Weekly health check
./operations/maintenance/weekly-checks.sh

# Restore from disaster
./operations/recovery/restore-from-backup.sh
```

### `scripts/` - Utility Scripts

**Purpose:** Tools for diagnostics, validation, monitoring

**Contains:**
- `cluster-status.sh` - System diagnostics
- `validate-config.sh` - Configuration validation
- `oled_display_v1.py` - Status display
- `security_monitor_v1.1.py` - Security monitoring

## Best Practices by Folder

### Configuration Management

**Templates:** Keep generic, use variables for node-specific values
```bash
# Good: Templates use placeholders
dhcp-range={{ dhcp_start }},{{ dhcp_end }},12h
interface={{ interface_name }}

# Deploy: Overlay provides actual values
dhcp-range=192.168.1.100,192.168.1.200,12h
interface=eth0
```

**Overlays:** Each node has its own customizations
```bash
config/overlays/boot-node/dnsmasq.conf  # Boot node specific
config/overlays/isr-node/dnsmasq.conf   # ISR node specific
# Same service, different configs
```

**Secrets:** NEVER commit credentials
```bash
config/secrets/                      # In .gitignore
config/secrets/ssh-keys/             # Not in version control
config/secrets/api-keys/             # Stored securely elsewhere
config/secrets/README.md             # But document HOW to add them
```

### Deployment

**Checklist First:** Before deploying, verify prerequisites
```bash
# Deploy in sequence
1. Review PRE-DEPLOYMENT-CHECKLIST.md
2. Run deployment scripts in order (01, 02, 03, 04)
3. Run POST-DEPLOYMENT-CHECKLIST.md
4. Archive deployment report
```

**Idempotent:** Can run multiple times safely
```bash
# Good: Running twice = same result
./deployments/boot-node/03-configure-services.sh
./deployments/boot-node/03-configure-services.sh  # Safe to repeat
```

### Operations

**Backups:** Automated and tested
```bash
# Daily automatic backup
operations/backups/backup-daily.sh

# Configuration backup before changes
make backup

# Verify backups regularly
operations/maintenance/weekly-checks.sh
```

**Recovery:** Clear procedures
```bash
# If disaster occurs
1. Read operations/recovery/README.md
2. Follow recovery-checklist.md
3. Run restore-from-backup.sh
4. Verify with cluster-status.sh
```

**Monitoring:** Regular health checks
```bash
# Weekly verification
./operations/maintenance/weekly-checks.sh

# Monthly deep health check
./operations/maintenance/monthly-health.sh

# Always-on monitoring
./scripts/cluster-status.sh
```

## Git Workflow

### What Gets Committed

✅ **DO commit:**
- `config/templates/` - Base configurations
- `config/overlays/` - Node-specific (non-sensitive)
- `config/security/` - Security policies
- `deployments/` - Deployment procedures
- `operations/` - Operational procedures
- `scripts/` - Utility scripts
- Documentation and guides

❌ **DO NOT commit:**
- `config/secrets/` - Credentials, keys, certificates
- `operations/backups/` - Backup files
- `operations/logs/` - System logs
- `.env` or local config files
- `Makefile.local` - Local customizations
- Any files with IP addresses, passwords, tokens

### .gitignore Pattern

```bash
# Secrets (never commit)
config/secrets/**
!config/secrets/README.md
!config/secrets/.gitkeep

# Operational data
operations/backups/**
!operations/backups/.gitkeep
!operations/backups/README.md

operations/logs/**
!operations/logs/.gitkeep
!operations/logs/README.md

# Local overrides
Makefile.local
local.conf
.env
```

## Scaling Strategy

As your cluster grows:

**Phase 1 (Current):** Single boot node + concept
- Use `config/templates/` and `config/overlays/boot-node/`
- Document everything in `deployments/boot-node/`

**Phase 2:** Multiple nodes (ISR, Mesh, VHF)
- Add overlays for each node
- Use `deployments/node-templates/` for automation
- Implement backup system in `operations/backups/`

**Phase 3:** Multi-site/redundancy
- Create `sites/` directory for site-specific configs
- Enhanced failover in `operations/recovery/`
- Monitoring across sites in `operations/monitoring/`

**Phase 4:** Enterprise scale
- Configuration management tool (Ansible/Salt)
- Central logging system
- Advanced monitoring/alerting
- Automated healing procedures

## Next Steps

1. **Review structure:** Understand purpose of each folder
2. **Start with templates:** Move existing configs into template structure
3. **Create overlays:** Define node-specific customizations
4. **Security baseline:** Add security configurations
5. **Deployment scripts:** Create step-by-step procedures
6. **Backup system:** Implement backup/restore procedures
7. **Operations manual:** Document regular maintenance

## References

- [Infrastructure Guide](INFRASTRUCTURE.md) - Setup procedures
- [Security Baseline](SECURITY-BASELINE.md) - Security standards
- [Git Workflow](GIT-WORKFLOW.md) - Version control standards
- [Deployments README](deployments/README.md) - How to deploy
- [Operations README](operations/README.md) - How to operate

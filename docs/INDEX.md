# Repository Navigation Guide

**Quick Index to All Documentation**

Last Updated: December 25, 2025

---

## 🚀 Getting Started (Read First)

1. **[SETUP-COMPLETE.md](SETUP-COMPLETE.md)** - What was built and how to use it
2. **[INFRASTRUCTURE.md](INFRASTRUCTURE.md)** - Complete setup and architecture
3. **[docs/quick-start.md](docs/quick-start.md)** - 10-minute quick start

---

## 📚 Essential Documentation

### Planning & Architecture
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Architecture, setup phases, deployment workflow
- [FOLDER-STRUCTURE.md](FOLDER-STRUCTURE.md) - Directory organization and purposes
- [docs/hardware.md](docs/hardware.md) - Hardware specifications and setup

### Security & Hardening
- [SECURITY-BASELINE.md](SECURITY-BASELINE.md) - Security standards and implementation roadmap
- [config/secrets/README.md](config/secrets/README.md) - Secrets management and rotation
- **Configuration templates** in `config/security/`:
  - `firewall.ufw` - UFW firewall rules
  - `sshd_config` - SSH hardened configuration
  - `fail2ban.conf` - Brute force protection
  - `sysctl.conf` - Kernel hardening
  - `sudoers` - Privilege escalation control

### Operations & Maintenance
- [operations/OPERATIONS.md](operations/OPERATIONS.md) - Daily, weekly, monthly procedures
- [deployments/PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md) - Pre-deployment verification
- [deployments/POST-DEPLOYMENT-CHECKLIST.md](deployments/POST-DEPLOYMENT-CHECKLIST.md) - Post-deployment verification
- [docs/troubleshooting.md](docs/troubleshooting.md) - Common issues and solutions

### Version Control & Collaboration
- [GIT-WORKFLOW.md](GIT-WORKFLOW.md) - Git standards, branching, and team workflow
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

---

## 📂 Directory Structure

### `config/` - Configuration Files

```
config/
├── boot/                    # Boot configuration files
├── network/                 # Network configuration (DHCP, DNS)
├── nfs/                    # NFS configuration
├── ntp/                    # NTP/time configuration
├── overlays/               # Node-specific customizations
│   ├── boot-node/
│   ├── isr-node/
│   ├── mesh-node/
│   └── vhf-node/
├── secrets/                # Credentials (git-ignored)
│   └── README.md          # Secrets management guide
├── security/               # Security configurations
│   ├── fail2ban.conf
│   ├── firewall.ufw
│   ├── sshd_config
│   ├── sudoers
│   └── sysctl.conf
└── templates/              # Base templates (to be created)
```

### `deployments/` - Deployment Procedures

```
deployments/
├── boot-node/             # Boot node deployment
│   ├── 01-system-setup.sh        (to be created)
│   ├── 02-install-services.sh    (to be created)
│   ├── 03-configure-services.sh  (to be created)
│   └── 04-verify-setup.sh        (to be created)
├── node-templates/        # Generic node templates
├── PRE-DEPLOYMENT-CHECKLIST.md
└── POST-DEPLOYMENT-CHECKLIST.md
```

### `operations/` - Operational Procedures

```
operations/
├── OPERATIONS.md           # Daily/weekly/monthly procedures
├── backups/               # Backup storage and scripts
├── logs/                  # System logs
├── recovery/              # Disaster recovery procedures
└── maintenance/           # Regular maintenance tasks
```

### `docs/` - Documentation

```
docs/
├── quick-start.md         # 10-minute quick start
├── setup.md               # Detailed setup guide
├── hardware.md            # Hardware documentation
├── troubleshooting.md     # Troubleshooting guide
├── PHASE1-GUIDE.md        # Phase 1 diagnostics guide
├── PROJECT_STATUS.md      # Project status and roadmap
└── QUICK-REFERENCE.md     # Command reference
```

### Root Level Key Files

```
/
├── README.md                  # Main project overview
├── INFRASTRUCTURE.md          # Complete setup guide
├── SECURITY-BASELINE.md       # Security standards
├── GIT-WORKFLOW.md            # Version control standards
├── FOLDER-STRUCTURE.md        # Folder organization
├── SETUP-COMPLETE.md          # Setup completion summary
├── CONTRIBUTING.md            # Contribution guidelines
├── LICENSE                    # MIT License
└── Makefile                   # Build and test commands
```

---

## 🔐 Security Files Reference

All in `config/security/`:

| File | Purpose | Key Config |
|------|---------|-----------|
| `firewall.ufw` | Firewall rules | `DEFAULT_INPUT_POLICY="DROP"` |
| `sshd_config` | SSH hardening | `PasswordAuthentication no` |
| `fail2ban.conf` | Brute force protection | `maxretry = 3` |
| `sysctl.conf` | Kernel hardening | `kernel.randomize_va_space = 2` |
| `sudoers` | Privilege escalation | Group-based permissions |

---

## 📋 Checklists

### Pre-Deployment
**[deployments/PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md)**
- 50+ verification items
- System readiness
- Security baseline
- Documentation completeness

### Post-Deployment
**[deployments/POST-DEPLOYMENT-CHECKLIST.md](deployments/POST-DEPLOYMENT-CHECKLIST.md)**
- 70+ verification items
- Service status
- Performance baseline
- Operational readiness

---

## 🛠️ Common Tasks

### First-Time Setup
1. Read [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Architecture overview
2. Review [SECURITY-BASELINE.md](SECURITY-BASELINE.md) - Security requirements
3. Complete [PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md)
4. Follow deployment steps in [INFRASTRUCTURE.md](INFRASTRUCTURE.md)
5. Complete [POST-DEPLOYMENT-CHECKLIST.md](deployments/POST-DEPLOYMENT-CHECKLIST.md)

### Daily Operations
1. Read [operations/OPERATIONS.md](operations/OPERATIONS.md) - Section "Daily Operations"
2. Run: `make status`
3. Review logs: `sudo journalctl -f -p warning`

### Troubleshooting
1. Check [docs/troubleshooting.md](docs/troubleshooting.md)
2. Use [operations/OPERATIONS.md](operations/OPERATIONS.md) - Section "Troubleshooting"
3. Review relevant service logs

### Making Changes
1. Read [GIT-WORKFLOW.md](GIT-WORKFLOW.md) - Version control standards
2. Create feature branch: `git checkout -b feature/my-change`
3. Make changes, test thoroughly
4. Commit with clear message: `git commit -m "type: description"`
5. Push and create pull request

### Managing Secrets
1. Read [config/secrets/README.md](config/secrets/README.md)
2. Generate secrets: SSH keys, certificates, API keys
3. Store in `config/secrets/`
4. Verify `.gitignore` includes secrets
5. Load via environment variables in scripts

---

## 📊 File Statistics

**Total Documentation:** 2,550+ lines
- INFRASTRUCTURE.md: 650 lines
- GIT-WORKFLOW.md: 400 lines
- SECURITY-BASELINE.md: 400 lines
- operations/OPERATIONS.md: 450 lines
- FOLDER-STRUCTURE.md: 300 lines
- config/secrets/README.md: 350 lines

**Security Templates:** 500+ lines
- firewall.ufw, sshd_config, fail2ban.conf, sysctl.conf, sudoers

**Checklists:** 120+ items
- PRE-DEPLOYMENT: 50+ items
- POST-DEPLOYMENT: 70+ items

**Directories Created:** 15
- Templates, overlays (4), secrets, security, deployments (2), operations (3)

---

## 🔍 Finding What You Need

### By Topic

**Architecture & Setup**
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Complete guide
- [FOLDER-STRUCTURE.md](FOLDER-STRUCTURE.md) - Directory organization
- [docs/hardware.md](docs/hardware.md) - Hardware setup

**Security**
- [SECURITY-BASELINE.md](SECURITY-BASELINE.md) - Standards
- [config/security/](config/security/) - Configuration templates
- [config/secrets/README.md](config/secrets/README.md) - Secrets management

**Operations**
- [operations/OPERATIONS.md](operations/OPERATIONS.md) - Procedures
- [docs/troubleshooting.md](docs/troubleshooting.md) - Problem solving
- [deployments/PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md) - Pre-flight checks

**Development & Collaboration**
- [GIT-WORKFLOW.md](GIT-WORKFLOW.md) - Version control
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

**Quick Reference**
- [docs/quick-start.md](docs/quick-start.md) - 10-minute start
- [docs/QUICK-REFERENCE.md](docs/QUICK-REFERENCE.md) - Command reference
- [README.md](README.md) - Project overview

### By Time Needed

**10 Minutes** → [docs/quick-start.md](docs/quick-start.md)

**30 Minutes** → [SETUP-COMPLETE.md](SETUP-COMPLETE.md)

**1-2 Hours** → [INFRASTRUCTURE.md](INFRASTRUCTURE.md)

**2-4 Hours** → Full setup following [INFRASTRUCTURE.md](INFRASTRUCTURE.md) + [deployments/PRE-DEPLOYMENT-CHECKLIST.md](deployments/PRE-DEPLOYMENT-CHECKLIST.md)

**4-6 Hours** → Deployment + [deployments/POST-DEPLOYMENT-CHECKLIST.md](deployments/POST-DEPLOYMENT-CHECKLIST.md)

---

## ✅ Documentation Checklist

**Foundation Complete:**
- ✅ INFRASTRUCTURE.md - Complete setup guide
- ✅ SECURITY-BASELINE.md - Security standards
- ✅ GIT-WORKFLOW.md - Version control standards
- ✅ FOLDER-STRUCTURE.md - Directory organization
- ✅ operations/OPERATIONS.md - Operational procedures
- ✅ config/secrets/README.md - Secrets management
- ✅ deployments/PRE-DEPLOYMENT-CHECKLIST.md - Pre-deployment
- ✅ deployments/POST-DEPLOYMENT-CHECKLIST.md - Post-deployment
- ✅ config/security/ - 5 security configuration templates

**Ready for Deployment:**
- ✅ Firewall rules (config/security/firewall.ufw)
- ✅ SSH configuration (config/security/sshd_config)
- ✅ Fail2Ban setup (config/security/fail2ban.conf)
- ✅ Kernel hardening (config/security/sysctl.conf)
- ✅ Sudoers rules (config/security/sudoers)

**Next Phase (To Be Created):**
- ⏳ Boot node deployment scripts (01-04)
- ⏳ Backup procedures
- ⏳ Recovery scripts
- ⏳ Monitoring setup

---

## 📞 Questions?

**Architecture questions?**
→ See [INFRASTRUCTURE.md](INFRASTRUCTURE.md)

**Security questions?**
→ See [SECURITY-BASELINE.md](SECURITY-BASELINE.md)

**Operation questions?**
→ See [operations/OPERATIONS.md](operations/OPERATIONS.md)

**Troubleshooting?**
→ See [docs/troubleshooting.md](docs/troubleshooting.md)

**Git workflow?**
→ See [GIT-WORKFLOW.md](GIT-WORKFLOW.md)

**How do I get started?**
→ See [SETUP-COMPLETE.md](SETUP-COMPLETE.md)

---

**Last Updated:** December 25, 2025  
**Status:** Foundation Complete - Ready for Phase 2 Deployment

# Documentation Index & Navigation

**Complete Guide to the Portable Pi 5 Cluster Server**

Last Updated: December 25, 2025

---

## 🚀 Getting Started (Choose Your Path)

### Fast Track (30 minutes)
→ **New to the project?** Start here:

1. **[QUICK-START.md](quick-start.md)** - Deploy boot node with 4 automated phases
2. **[HARDWARE.md](hardware.md)** - What physical components you need  
3. **[SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md)** - How the deployment scripts work

### Complete Setup (2-3 hours)
→ **Need full context?** Follow this path:

1. **[INFRASTRUCTURE.md](../INFRASTRUCTURE.md)** - Architecture, design, phases
2. **[SETUP.md](setup.md)** - Detailed step-by-step installation guide
3. **[HARDWARE.md](hardware.md)** - Component details and wiring
4. **[TROUBLESHOOTING.md](troubleshooting.md)** - Fix issues as they arise

### Operations & Maintenance
→ **Cluster is running, need to keep it healthy:**

1. **[OPERATIONS.md](../operations/OPERATIONS.md)** - Daily/weekly/monthly procedures
2. **[TROUBLESHOOTING.md](troubleshooting.md)** - Common problems and solutions
3. **[SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md)** - Automated tools (backup, health-check, key rotation)

---

## 📚 Complete Documentation Map

### Essential Setup Guides
| Document | Purpose | Time |
|----------|---------|------|
| **[QUICK-START.md](quick-start.md)** | Deploy boot node in 4 phases | ~2 min read |
| **[SETUP.md](setup.md)** | Complete installation walkthrough | ~15 min read |
| **[HARDWARE.md](hardware.md)** | Component specs, wiring, power | ~10 min read |

### Architecture & Planning
| Document | Purpose | Time |
|----------|---------|------|
| **[INFRASTRUCTURE.md](../INFRASTRUCTURE.md)** | Architecture, phases, workflow | ~20 min read |
| **[FOLDER-STRUCTURE.md](../FOLDER-STRUCTURE.md)** | Directory organization | ~5 min read |
| **[PROJECT-STATUS.md](PROJECT_STATUS.md)** | What's done, what's planned | ~5 min read |

### Deployment & Operations
| Document | Purpose | Items |
|----------|---------|-------|
| **[SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md)** | Deployment & automation scripts | 7 scripts |
| **[OPERATIONS.md](../operations/OPERATIONS.md)** | Daily/weekly/monthly procedures | 20+ procedures |
| **[PRE-DEPLOYMENT-CHECKLIST.md](../deployments/PRE-DEPLOYMENT-CHECKLIST.md)** | Pre-deployment verification | 50+ items |
| **[POST-DEPLOYMENT-CHECKLIST.md](../deployments/POST-DEPLOYMENT-CHECKLIST.md)** | Post-deployment verification | 70+ items |

### Security & Configuration
| Document | Purpose | Items |
|----------|---------|-------|
| **[SECURITY-BASELINE.md](../SECURITY-BASELINE.md)** | Security standards & hardening | 10+ procedures |
| **[config/secrets/README.md](../config/secrets/README.md)** | Secrets management & rotation | Key rotation guide |
| **Security templates** in `config/security/` | Firewall, SSH, Fail2Ban, kernel hardening | 5 templates |

### Development & Collaboration
| Document | Purpose | Items |
|----------|---------|-------|
| **[GIT-WORKFLOW.md](../GIT-WORKFLOW.md)** | Git standards, branching, team workflow | Conventions |
| **[CONTRIBUTING.md](../CONTRIBUTING.md)** | Contribution guidelines | How to participate |

### Problem Solving
| Document | Purpose | Coverage |
|----------|---------|----------|
| **[TROUBLESHOOTING.md](troubleshooting.md)** | Fix common issues | Network, NFS, Time, Storage, SSH, Deployment |

---

## 📂 Directory Structure Reference

```
config/                           # Configuration files
├── boot/                         # PXE boot config
├── network/                      # DNS/DHCP config
├── nfs/                          # NFS server config
├── ntp/                          # NTP/GPS time sync
├── overlays/                     # Node-specific customizations
├── secrets/                      # Credentials (git-ignored)
└── security/                     # Security templates

deployments/                      # Deployment & scripts
├── boot-node/
│   ├── 01-system-setup.sh       # OS updates, hostname, hardening
│   ├── 02-install-services.sh   # Install all packages
│   ├── 03-configure-services.sh # Deploy configs, start services
│   └── 04-verify-setup.sh       # Run 70+ verification tests
├── PRE-DEPLOYMENT-CHECKLIST.md  
└── POST-DEPLOYMENT-CHECKLIST.md 

operations/                       # Operational scripts & docs
├── OPERATIONS.md                # Daily/weekly/monthly procedures
├── backups/backup-daily.sh      # Automated daily backups
├── maintenance/health-check.sh  # System health monitoring
├── recovery/                    # Disaster recovery procedures
└── logs/                        # System log storage

docs/                            # Documentation (this folder)
├── QUICK-START.md               # 30-minute deployment guide
├── SETUP.md                     # Complete setup walkthrough
├── HARDWARE.md                  # Component specifications
├── TROUBLESHOOTING.md           # Common issues & solutions
└── INDEX.md                     # This file
```

---

## 🎯 Quick Task Lookup

### I want to...

**...deploy the cluster**
→ [QUICK-START.md](quick-start.md) - 30 minute automated deployment

**...understand the architecture**
→ [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) - Complete design overview

**...fix a problem**
→ [TROUBLESHOOTING.md](troubleshooting.md) - Solutions for common issues

**...set up a specific node (ISR, Mesh, VHF)**
→ [SETUP.md](setup.md) - Per-node configuration guide

**...verify hardware is correct**
→ [HARDWARE.md](hardware.md) - Component specs and requirements

**...configure security**
→ [SECURITY-BASELINE.md](../SECURITY-BASELINE.md) - Security standards

**...manage backups and monitoring**
→ [SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md) - Automation tools

**...perform daily operations**
→ [OPERATIONS.md](../operations/OPERATIONS.md) - Daily procedures

**...know what scripts do**
→ [SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md) - All 7 scripts explained

**...contribute to the project**
→ [CONTRIBUTING.md](../CONTRIBUTING.md) - How to participate

---

## 📖 Reading Guide by Role

### For System Administrators
1. [QUICK-START.md](quick-start.md) - Deploy the cluster
2. [OPERATIONS.md](../operations/OPERATIONS.md) - Day-to-day management
3. [TROUBLESHOOTING.md](troubleshooting.md) - Problem solving
4. [SECURITY-BASELINE.md](../SECURITY-BASELINE.md) - Security hardening

### For Hardware Integrators
1. [HARDWARE.md](hardware.md) - Component specifications
2. [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) - System architecture
3. [SETUP.md](setup.md) - Physical setup details
4. [config/](../config/) - Configuration examples

### For Developers
1. [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) - Architecture overview
2. [GIT-WORKFLOW.md](../GIT-WORKFLOW.md) - Development standards
3. [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute
4. [FOLDER-STRUCTURE.md](../FOLDER-STRUCTURE.md) - Code organization

### For Security Officers
1. [SECURITY-BASELINE.md](../SECURITY-BASELINE.md) - Security standards
2. [config/security/](../config/security/) - Security templates
3. [config/secrets/README.md](../config/secrets/README.md) - Secrets management
4. [TROUBLESHOOTING.md](troubleshooting.md) - Security issue resolution

---

## 💡 Common Reference Points

**First Time Setup:**
1. [QUICK-START.md](quick-start.md)
2. Run deployment scripts
3. [TROUBLESHOOTING.md](troubleshooting.md) if issues
4. [OPERATIONS.md](../operations/OPERATIONS.md) for ongoing management

**Need Help?**
1. Search [TROUBLESHOOTING.md](troubleshooting.md)
2. Check relevant config: `config/` directory
3. Review [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) for architecture questions
4. See [CONTRIBUTING.md](../CONTRIBUTING.md) to report issues

---

## 📊 Documentation Status

**Documentation Coverage:**
- ✅ 2,000+ lines of guides
- ✅ 4 core setup documents
- ✅ 4 reference/planning documents
- ✅ 7 deployment/automation scripts
- ✅ 5 security templates
- ✅ 2 comprehensive checklists

**Last Updated:** December 25, 2025  
**Status:** ✅ Complete and Current  
**Maintained By:** Project Team

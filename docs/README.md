# Documentation Center

**Your guide to the Portable Pi 5 Cluster Server**

---

## 🚀 Quick Start

**Want to deploy in 30 minutes?**  
→ Go to **[QUICK-START.md](quick-start.md)**

**Need the complete setup guide?**  
→ Go to **[SETUP.md](setup.md)**

**Have a problem to solve?**  
→ Go to **[TROUBLESHOOTING.md](troubleshooting.md)**

**Need to navigate all docs?**  
→ Go to **[INDEX.md](INDEX.md)** ← Comprehensive documentation map

---

## 📚 Main Documentation Files in This Folder

| File | Purpose | Best For |
|------|---------|----------|
| **[QUICK-START.md](quick-start.md)** | Deploy boot node in 4 phases | First-time deployment |
| **[SETUP.md](setup.md)** | Complete installation walkthrough | Detailed setup guidance |
| **[HARDWARE.md](hardware.md)** | Component specs, wiring, power system | Hardware setup & requirements |
| **[TROUBLESHOOTING.md](troubleshooting.md)** | Solutions for common issues | Fixing problems |
| **[INDEX.md](INDEX.md)** | Complete documentation map | Finding anything |

---

## 📖 Where to Find What

### I'm New - Where Do I Start?
1. Read [QUICK-START.md](quick-start.md) - 5 minutes
2. Understand [HARDWARE.md](hardware.md) - 10 minutes  
3. Run deployment scripts - 30 minutes

### I Need Full Context
1. Read [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) - Architecture overview
2. Read [SETUP.md](setup.md) - Detailed setup
3. Follow [QUICK-START.md](quick-start.md) - Automated deployment

### Something's Broken
→ [TROUBLESHOOTING.md](troubleshooting.md) - Solutions by topic

### I Need to Find Specific Information
→ [INDEX.md](INDEX.md) - Complete documentation navigation map

### I Want to Know About Operations
→ [OPERATIONS.md](../operations/OPERATIONS.md) - Daily/weekly/monthly procedures

### I Need Script Documentation
→ [SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md) - All 7 scripts explained

---

## 🎯 Key Concepts

### The Four Deployment Phases
1. **System Setup** - OS updates, hostname, security hardening
2. **Install Services** - Install all required packages
3. **Configure Services** - Deploy configs, enable services
4. **Verify Setup** - Run 70+ tests to validate

See [QUICK-START.md](quick-start.md) for deployment command details.

### Node Types
- **Boot Node** (192.168.1.10) - PXE, DHCP, DNS, NFS, Time sync
- **ISR Node** (192.168.1.20) - RF monitoring, signal analysis
- **Mesh Node** (192.168.1.30) - LoRa networking
- **VHF Node** (192.168.1.40) - Transceiver interface

See [HARDWARE.md](hardware.md) for all nodes, or [SETUP.md](setup.md) for per-node setup.

### Security Standards
- Key-based SSH only
- UFW firewall with restrictive rules
- Fail2Ban brute force protection
- Kernel hardening
- Regular key rotation

See [SECURITY-BASELINE.md](../SECURITY-BASELINE.md) for details.

---

## 📂 Full Documentation Structure

```
Portable-Pi-5-Cluster-Server/
├── docs/                      ← You are here
│   ├── QUICK-START.md         → 30-minute deployment
│   ├── SETUP.md               → Complete setup guide
│   ├── HARDWARE.md            → Component requirements
│   ├── TROUBLESHOOTING.md     → Problem solutions
│   ├── INDEX.md               → Navigation map
│   └── README.md              → This file
│
├── scripts/                   
│   ├── SCRIPTS-REFERENCE.md   → All scripts explained
│   ├── oled_display_v1.py
│   ├── security_monitor_v1.1.py
│   └── rotate-ssh-keys.sh
│
├── deployments/
│   ├── boot-node/
│   │   ├── 01-system-setup.sh
│   │   ├── 02-install-services.sh
│   │   ├── 03-configure-services.sh
│   │   └── 04-verify-setup.sh
│   ├── PRE-DEPLOYMENT-CHECKLIST.md
│   └── POST-DEPLOYMENT-CHECKLIST.md
│
├── operations/
│   ├── OPERATIONS.md          → Daily/weekly/monthly
│   ├── backups/backup-daily.sh
│   └── maintenance/health-check.sh
│
├── config/                    → Configuration files
│   ├── network/, nfs/, ntp/, boot/
│   ├── security/              → Security templates
│   ├── overlays/              → Node customizations
│   └── secrets/               → Credentials (git-ignored)
│
├── INFRASTRUCTURE.md          → Architecture & design
├── SECURITY-BASELINE.md       → Security standards
├── GIT-WORKFLOW.md            → Version control
├── FOLDER-STRUCTURE.md        → Directory guide
├── README.md                  → Project overview
└── ...
```

---

## ✅ What's Included

**Documentation:**
- ✅ 2,000+ lines of setup guides
- ✅ Complete troubleshooting guide
- ✅ Hardware specifications
- ✅ Security baselines

**Deployment:**
- ✅ 4-phase automated boot node setup
- ✅ 50+ pre-deployment checks
- ✅ 70+ post-deployment tests

**Automation:**
- ✅ Daily backup script
- ✅ Health monitoring
- ✅ SSH key rotation
- ✅ Security monitoring

**Configuration:**
- ✅ Network (DHCP/DNS)
- ✅ NFS storage
- ✅ NTP time sync
- ✅ Security hardening
- ✅ Firewall rules

---

## 🔍 Search Tip

**Looking for something specific?**

Use **[INDEX.md](INDEX.md)** - it has:
- Task lookup (I want to...)
- Topic lookup (By subject)
- Role-based guides
- Quick reference table

---

## 📞 Need Help?

1. **Deploying?** → [QUICK-START.md](quick-start.md)
2. **Got an error?** → [TROUBLESHOOTING.md](troubleshooting.md)
3. **Setting up a node?** → [SETUP.md](setup.md)
4. **Need to find something?** → [INDEX.md](INDEX.md)
5. **Want to understand architecture?** → [INFRASTRUCTURE.md](../INFRASTRUCTURE.md)

---

**Last Updated:** December 25, 2025  
**Status:** ✅ Documentation Complete

## Common Tasks

### First Time Setup

1. Review [Hardware Documentation](hardware.md)
2. Follow [Quick Start Guide](quick-start.md)
3. Complete [Installation Guide](setup.md)
4. Test with [Troubleshooting Guide](troubleshooting.md)

### Adding a New Node

1. Install Raspberry Pi OS
2. Configure network (IP, hostname)
3. Clone this repository
4. Run node-specific setup scripts
5. Test connectivity

### Updating Configuration

1. Edit files in `config/` directory
2. Backup original files
3. Apply changes: `sudo cp config/file /etc/location`
4. Restart service: `sudo systemctl restart service`
5. Verify: `sudo systemctl status service`

### Monitoring Cluster Health

1. SSH to boot node
2. Run: `systemctl status` (view all services)
3. Check specific services:
   - DNS/DHCP: `sudo systemctl status dnsmasq`
   - NFS: `sudo systemctl status nfs-kernel-server`
   - Time: `chronyc sources`
4. View logs: `sudo journalctl -f`

## Getting Help

### Quick Troubleshooting

1. **Network issues?** → [Troubleshooting: Network](troubleshooting.md#network-issues)
2. **NFS problems?** → [Troubleshooting: NFS](troubleshooting.md#nfs-issues)
3. **Time not syncing?** → [Troubleshooting: Time](troubleshooting.md#time-synchronization-issues)
4. **Storage issues?** → [Troubleshooting: Storage](troubleshooting.md#storage-issues)

### For Detailed Information

- [Hardware questions](hardware.md) - Component specs and setup
- [Configuration questions](../config/README.md) - Config file details
- [Script questions](../scripts/README.md) - Python script docs
- [Installation questions](setup.md) - Step-by-step guides

### Still Need Help?

1. Check [Troubleshooting Guide](troubleshooting.md) thoroughly
2. Review relevant section in this index
3. Search `config/` and `docs/` for related content
4. Check system logs: `sudo journalctl -xe`
5. Open an issue on GitHub with detailed information

## Version History

- **v0.1.1**: Initial stable release with emergency comms focus
- See [docs/v0.1.1.txt](v0.1.1.txt) for detailed version notes

## Contributing

Want to improve this documentation?

1. Review [CONTRIBUTING.md](../CONTRIBUTING.md)
2. Edit markdown files directly
3. Test links and commands
4. Submit pull request

Documentation improvements are always welcome!

## License

This documentation and all project files are licensed under the MIT License. See [LICENSE](../LICENSE) for details.

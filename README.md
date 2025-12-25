# Portable Pi 5 Cluster Server

A complete emergency communications cluster built on Raspberry Pi 5 nodes, featuring PXE booting, mesh networking, RF monitoring, and GPS time synchronization.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Hardware](#hardware)
- [Software Stack](#software-stack)
- [Node Types](#node-types)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgments](#acknowledgments)


## Overview

This repository contains all the configurations, scripts, and documentation needed to set up and maintain a portable Raspberry Pi cluster server. The cluster is designed to support emergency communications and networking, leveraging PXE booting, overlays, and various specialized tools.

The system integrates features like software-defined radios (SDRs), LoRa communication, Reticulum-based mesh networking, and more, enabling the cluster to behave like a cohesive, multifunctional unit for diverse tasks.

## Features

**PXE Boot Environment:** Centralized boot server using TFTP and NFS to manage operating systems across cluster nodes.

**Overlay Management:** Modular overlays for node-specific software and configurations, simplifying updates and customization.

**Emergency Communication Tools:** Support for ham radio software (FLdigi, Winlink), SDR applications (CubicSDR, SDR Trunk, Dump1090), and LoRa communication.

**Mesh Networking:** Reticulum-powered peer-to-peer networking with Mosquitto MQTT broker and FreeTAC Server integration.

**Time Synchronization:** GPS-based and NTP time sync for improved reliability in isolated networks.


## Hardware

- Raspberry Pi 5s (4 GB or 8 GB) with PoE hats.

- Peripheral equipment: USB SDRs, GPS receiver, SSD, LoRa hats/dongles.

- Managed PoE switch with VLAN and QoS capabilities.

- Battery power supply with AC passthrough charging.


## Software

**Base OS:** Raspberry Pi OS with a custom overlay for each node.

**PXE Boot:** *dnsmask (DHCP and TFTP configuration), OverlayFS, NFS.*

**RF Communication Tools:** *FLdigi, Winlink, JS8Call, Direwolf, CQRLog.*

**Mesh Networking:** *Reticulum, Mosquitto MQTT, FreeTAKServer.*

**Passive RF Monitoring:** *SDR Trunk, CubicSDR, Dump1090, Dump978, PyAware.*

**Security Tools** *UFW, Fail2Ban, Security Breach Monitoring Script.*

**Administrative Tools** *Rsync, SSH, Parallel, SSH, Flask Client Dashboard.*

**Other Services** *NTP via GPS, Offline HTML + CSS Learning Portal, Yacy, OLED Status Display Script, PyGame.*


## Node Types

- **Boot Node:** Manages the cluster and provides PXE boot services (DHCP, TFTP, NFS).

- **ISR Node:** Passive RF monitoring using software-defined radios for ADS-B and spectrum analysis.

- **Mesh Node:** LoRa-based Reticulum mesh networking for decentralized communication.

- **VHF/UHF Node:** Digital data communications via dual-band transceiver interface. 

## Getting Started

**Start Here - Understand Your Current System:**

```bash
# Check cluster status and diagnostics
make status              # Quick health check
make validate            # Validate configurations
make diagnose            # Full diagnostics (both above)
```

For detailed setup instructions, see [Setup Guide](docs/setup.md).

**Full Quick Start:**
1. Run `make diagnose` to understand current state
2. Review [Hardware Documentation](docs/hardware.md) for your setup
3. Follow [Installation Guide](docs/setup.md) for PXE boot configuration
4. Check [Troubleshooting Guide](docs/troubleshooting.md) if issues arise

## Installation

Detailed installation instructions are in [docs/setup.md](docs/setup.md).

## Documentation

### Essential Guides

**Start Here:**
- [Quick Start Guide](docs/quick-start.md) - Get up and running in 10 minutes
- [Infrastructure Setup](INFRASTRUCTURE.md) - Complete setup and architecture guide

**Operations & Maintenance:**
- [Operations Manual](operations/OPERATIONS.md) - Daily/weekly/monthly procedures
- [Security Baseline](SECURITY-BASELINE.md) - Security standards and hardening
- [Git Workflow](GIT-WORKFLOW.md) - Version control standards and branching strategy

**Advanced Topics:**
- [Folder Structure](FOLDER-STRUCTURE.md) - Organization and best practices
- [Secrets Management](config/secrets/README.md) - Secure credential handling
- [Hardware Documentation](docs/hardware.md) - Equipment specifications
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

**Deployment Procedures:**
- [Pre-Deployment Checklist](deployments/PRE-DEPLOYMENT-CHECKLIST.md) - Verify readiness
- [Post-Deployment Checklist](deployments/POST-DEPLOYMENT-CHECKLIST.md) - Verify success

### Key Command Reference

```bash
# Status & Diagnostics
make status              # Quick health check
make status-full         # Detailed status report
make test               # Comprehensive validation
make clean              # Clean temporary files

# Git Workflow
git status              # Check uncommitted changes
git log --oneline       # View commit history
git checkout -b feature/my-feature  # Create feature branch

# Operations
sudo systemctl status dnsmasq nfs-server ssh chrony ufw
sudo journalctl -f      # Follow system logs
```

See [GIT-WORKFLOW.md](GIT-WORKFLOW.md) for detailed commands.

## Directory Structure

```
├── config/              # Configuration files for all services
├── docs/                # Documentation and guides
├── scripts/             # Python scripts for monitoring and management
└── README.md            # This file
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

This project is tailored to emergency communications, but improvements that align with the project's goals are encouraged.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Raspberry Pi Foundation for hardware and OS
- Open-source communities: FLdigi, SDR Trunk, Reticulum, Mosquitto, and others
- Emergency communications practitioners and mesh networking enthusiasts
ChatGPT for troubleshooting and brainstorming assistance.



## Planned_Versions

**Version 0.1:** Core setup and basic functionality.

        PXE boot environment operational.

        NFS, SSH, and VNC working across nodes.

        Basic overlays for node-specific configurations.


**Version 0.2:** Full overlay implementation and tool integration.

        Node-specific functionalities enabled (e.g., SDR tools, LoRa communication, Reticulum).

        GPS-based time synchronization introduced.

        Initial power management tools.


**Version 0.3:** Enhanced networking and monitoring.

        Mesh networking with Reticulum and MQTT broker fully implemented.

        HTTP dashboard for cluster status.

        LogWatch integration for automated reporting.


**Version 0.4:** Optimization and portability.

        Improved power management for extended battery use.

        Hardware monitoring tools for thermal and power usage.

        Finalized cluster casing and cable management.


**Version 1.0:** Stable release.

        Fully documented and tested cluster server.

        Streamlined deployment process for replication by other users.

---

## 🚀 Quick Start to Production

### One Command Deployment

```bash
cd ~/Portable-Pi-5-Cluster-Server
sudo ./scripts/deployment-coordinator.sh
```

This runs an interactive guided setup covering all 8 stages:
- Pre-flight system checks
- Configuration validation
- Boot node setup (DHCP, DNS, TFTP, NFS, NTP)
- Worker node deployment (ISR, Mesh, VHF)
- Performance optimization
- Security hardening
- Initial backup creation

**Duration:** 30-60 minutes depending on internet speed

### Verification & Monitoring

After deployment, verify everything:

```bash
# Full health check (80+ tests)
./scripts/health-check-all.sh

# Cluster status report
./scripts/cluster-orchestrator.sh report

# Performance analysis
./scripts/performance-monitor.sh analyze
```

---

## 🏗️ New Capabilities (Production Ready)

### Deployment & Orchestration
- **Automated Coordinator** - End-to-end deployment in 8 stages
- **Boot Node Setup** - Complete DHCP/DNS/NFS/NTP infrastructure
- **Worker Nodes** - Specialized setups for ISR (RF), Mesh (LoRa), VHF (radio)
- **Configuration Validation** - Pre-deployment testing (80+ checks)

### Monitoring & Management
- **Health Check Suite** - Comprehensive system verification
- **Performance Monitoring** - CPU, memory, I/O, network, thermal analysis
- **Cluster Orchestrator** - Multi-node management with parallel operations
- **Performance Tuning** - Automatic optimization recommendations

### Backup & Recovery
- **Automated Backup** - Complete system state snapshots
- **Disaster Recovery** - Full restore capabilities with verification
- **Backup Management** - List, verify, and cleanup old backups

---

## 🎯 Common Commands

### Deploy
```bash
sudo ./scripts/deployment-coordinator.sh full    # Full cluster
sudo ./scripts/deployment-coordinator.sh boot    # Boot node only
```

### Monitor
```bash
./scripts/health-check-all.sh                    # Full health check
./scripts/performance-monitor.sh monitor 300     # Continuous monitoring
./scripts/cluster-orchestrator.sh report         # Cluster status
```

### Backup
```bash
./operations/backups/backup-restore-manager.sh create     # Create backup
./operations/backups/backup-restore-manager.sh restore    # Restore
```

---

## ✨ What's New (December 2025)

**Complete Production-Ready Suite:**
- ✅ Fully automated cluster deployment
- ✅ 80+ comprehensive health checks
- ✅ Real-time performance monitoring
- ✅ Multi-node orchestration
- ✅ Disaster recovery system
- ✅ 2,000+ lines of production code

**Status:** All major features implemented and ready for deployment.

See [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) and [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md) for details.

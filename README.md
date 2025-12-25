# Portable Pi 5 Cluster Server
![License](https://img.shields.io/badge/license-MIT-green)


A portable, field-deployable emergency communications cluster built on Raspberry Pi 5 nodes, featuring PXE booting, modular overlays, mesh networking, RF monitoring, and GPS-based time synchronization.

This project is in active early development. Some architectural decisions are still evolving, but all current functionality, tooling, and documentation are represented here without omission.

## 📌 Project Status

Development Stage: Early / Iterative

Focus: Emergency communications, rapid deployment, portability

Philosophy: Document everything that exists, even if it may change

No design decisions have been artificially “locked in” yet. This README represents the current reality, not a finalized specification.

## 📚 Table of Contents

- Overview

- Core Features

- Hardware Overview

- Software Stack

- Node Types

- Quick Start

- Installation & Deployment

- Documentation Center

- Operations & Maintenance

- Directory Structure

- Planned Versions

- Contributing

- License

- Acknowledgments

## Overview

This repository contains all configurations, scripts, and documentation required to build, deploy, and operate a portable Raspberry Pi 5 cluster server intended for emergency communications and isolated-network scenarios.

The cluster is designed to function as a cohesive, multi-role system, supporting:

- PXE-booted diskless nodes

- Modular, node-specific overlays

- RF monitoring and digital communications

- Mesh networking via Reticulum and LoRa

- GPS-based time synchronization

- Automated deployment, monitoring, and recovery

The system is suitable for field operations, experimentation, and learning, with an emphasis on reliability over elegance.

## Core Features
### PXE Boot Environment

- Centralized boot server

- DHCP, DNS, TFTP, and NFS services

- Diskless or semi-diskless node operation

- Consistent OS images across nodes

### Overlay Management

- Node-type and node-specific customizations

- Simplified updates and rollback

- Separation of base OS and role-specific tooling

### Emergency Communications

- Ham radio digital modes (FLdigi, Winlink, JS8Call)

- APRS and packet radio support

- VHF/UHF transceiver integration

### Passive RF Monitoring

- SDR Trunk

- CubicSDR

- Dump1090 / Dump978

- PyAware (ADS-B)

### Mesh Networking

- Reticulum-based peer-to-peer mesh

- LoRa integration

- Mosquitto MQTT broker

- FreeTAKServer integration

### Time Synchronization

- GPS-based reference time

- NTP / Chrony services

- Improved correlation across RF and log data

### Security & Administration

- UFW firewall

- Fail2Ban

- SSH key-only access

- Security monitoring scripts

- Automated SSH key rotation

## Hardware Overview

- 4x Raspberry Pi 5 (4 GB or 8 GB)

- PoE HATs

- Managed PoE switch (VLAN/QoS capable)

- Battery power supply with AC passthrough

- USB SDRs

- GPS receiver

- LoRa HATs or dongles

- SSD storage where applicable

See `docs/HARDWARE.md`
 for wiring, power design, and component specifications.

### Architecture Overview

The Portable Pi 5 Cluster Server is designed as a modular, field-deployable emergency communications cluster. It combines PXE booting, mesh networking, RF monitoring, and GPS-based time synchronization in a unified, portable system.

```
┌─────────────────────────────────────────────────────────────┐
│                    Portable Pi 5 Cluster                     │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────────────┐   ┌─────────────┐   ┌─────────────┐
│  │ Boot Node (Primary)   │──▶│ ISR Node    │   │ Mesh Node   │
│  │ DHCP/TFTP/DNS/NFS/GPS │   │ (RF Monitor)│   │ (LoRa Mesh) │
│  └───────────────────────┘   └─────────────┘   └─────────────┘
│                         │
│                         ▼
│                    VHF Node (Radio Interface)
└─────────────────────────────────────────────────────────────┘
```

Network: 10.0.0.0/8 primary, 192.168.0.0/16 secondary

- Services: DHCP (67/68)
- TFTP (69), DNS (53) 
- NFS (2049), SSH (22) 
- NTP (123)

### Node Roles & Responsibilities
| Node	| Primary Functions | Notes |
|-------|-------------------|-------|
| Boot Node | PXE booting, DHCP, DNS, NFS, Time sync (chrony + GPS), Cluster monitoring | Centralized management, overlay deployment
| ISR Node | RF spectrum monitoring, ADS-B decoding, SDR data collection | Passive monitoring and logging
| Mesh Node | LoRa-based Reticulum mesh networking | |Decentralized messaging and communication routing
| VHF Node | Digital VHF/UHF transceiver interface | Supports ham radio protocols and emergency comms

### Workflow & Relationships

1. **Boot Node** provides OS images and configuration overlays to all other nodes via PXE/NFS.

2. **ISR Node** collects spectrum data and communicates relevant alerts over the mesh.

3. **Mesh Node** forms a peer-to-peer decentralized network, relaying messages between ISR, VHF, and other field nodes.

4. **VHF Node** interfaces with analog/digital radios, bridging the cluster to external comms networks.

5. **All nodes** synchronize time via GPS/NTP, ensuring coordinated logging and event tracking.

6. **Monitoring & Dashboard** The Boot Node hosts a Flask-based dashboard for real-time cluster monitoring, node health, and system alerts.

## Software Stack
**Base System**

- Raspberry Pi OS

- OverlayFS

- PXE boot via dnsmasq

- NFS root filesystem

**RF & Communications**

- FLdigi

- Winlink

- JS8Call

- Direwolf

- CQRLog

**Mesh & Networking**

- Reticulum

- Mosquitto MQTT

- FreeTAKServer

**Monitoring & Visualization**

- SDR Trunk

- CubicSDR

- Dump1090 / Dump978

- PyAware

- OLED status display

- Flask-based dashboard (planned)

- System Services

- Chrony (GPS/NTP)

- UFW

- Fail2Ban

- Rsync

- SSH

- GNU Parallel

## Cluster Dashboard

The Tactical Operations Web Interface provides real-time monitoring, control, and tool integration for the Portable Pi 5 Cluster.

### Features

- **Cluster Overview:** Node statuses, deployment state, and purpose-driven roles

- **Health Metrics:** CPU, memory, disk, temperature, uptime, auto-refresh

- **Control Operations:** Deploy boot node, update all nodes, reboot/shutdown individually or cluster-wide

- **Performance Analysis:** Node and cluster-wide resource metrics

- **Backup & Recovery:** Create, restore, verify backups

- **Tool Integration:** Manage node-specific tools (ADSB, Mesh, SDR) with status indicators

### Modes

- **Demo Mode:** Local testing with simulated data, no cluster required

- **Production Mode:** Connects via SSH to real nodes, full operational control

### Dashboard Quick Start
``` 
cd web && ./run.sh
```

Access locally: http://127.0.0.1:5000

Connect to cluster: set `DEMO_MODE=False` and `HOST=0.0.0.0`

### API & Tool Integration

The dashboard exposes REST API endpoints for:

- Cluster & node status

- Health checks and validation

- Node operations (reboot, shutdown, update)

- Backup management

- Tool-specific control (starting/stopping integrated apps)

## Node Types

| Node Type | IP Address | Primary Role |
|-----------|------------|--------------|
| Boot Node | 192.168.1.10 | PXE, DHCP, DNS, NFS, Time |
| ISR Node | 192.168.1.20 | Passive RF monitoring |
| Mesh Node | 192.168.1.30 | LoRa mesh networking |
| VHF Node | 192.168.1.40 | Digital VHF/UHF communications |


Node roles are logical, not rigid. Responsibilities may shift as development progresses.

## Quick Start

Want to deploy in ~30 minutes?

```
cd ~/Portable-Pi-5-Cluster-Server && sudo ./scripts/deployment-coordinator.sh
```

This interactive deployment covers:

Pre-flight system checks

- [ ]  Configuration validation

- [ ] Boot node setup (DHCP, DNS, TFTP, NFS, NTP)

- [ ] Worker node provisioning

- [ ] Performance tuning

- [ ] Security hardening

- [ ] Initial backup creation

## Installation & Deployment
Four Deployment Phases

1. System Setup

   - OS updates

   - Hostname

   - Initial security hardening

2. Install Services

   - All required packages

3. Configure Services

   - Deploy configuration files

   - Enable services

4. Verify Setup

   - 70+ automated tests

See `docs/SETUP.md`
 and `docs/QUICK-START.md`


## Documentation Center

The project includes a fully structured documentation system.

### Start Here

- `docs/QUICK-START.md`
 – Rapid deployment

- `docs/SETUP.md`
 – Full installation guide

- `docs/TROUBLESHOOTING.md`
 – Problem resolution

- `docs/INDEX.md`
 – Complete documentation map

### Architecture & Standards

- `INFRASTRUCTURE.md` – System architecture

- `SECURITY-BASELINE.md` – Security standards

- `GIT-WORKFLOW.md` – Version control practices

- `FOLDER-STRUCTURE.md` – Repository organization

### Operations

- `operations/OPERATIONS.md` – Daily / weekly / monthly tasks

- `deployments/` – Pre/Post deployment checklists

- `scripts/SCRIPTS-REFERENCE.md` – Script documentation

### Operations & Maintenance
#### Common Commands
```
make status
make diagnose
sudo systemctl status dnsmasq nfs-server chrony ufw
sudo journalctl -f
```

#### Backups
```
./operations/backups/backup-restore-manager.sh create
```

```
./operations/backups/backup-restore-manager.sh restore
```

## Directory Structure
```
Portable-Pi-5-Cluster-Server/
├── docs/
├── scripts/
├── deployments/
├── operations/
├── config/
├── INFRASTRUCTURE.md
├── SECURITY-BASELINE.md
├── README.md
└── ...
```

## Planned Versions
### v0.1

-PXE boot operational

- NFS, SSH, VNC

- Basic overlays

### v0.2

- Full overlay implementation

- SDR, LoRa, Reticulum

- GPS time sync

### v0.3

- Mesh networking finalized

- MQTT broker

- HTTP dashboard

- LogWatch reporting

### v0.4

- Power optimization

- Thermal monitoring

- Finalized casing

### v1.0

- Fully documented

- Tested

- Replicable deployment

## Contributing

Contributions are welcome, especially those aligned with:

- Emergency communications

- Reliability

- Documentation clarity

See CONTRIBUTING.md.

## License

MIT License. See LICENSE.

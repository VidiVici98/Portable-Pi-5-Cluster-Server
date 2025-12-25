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


Documentation

- [Quick Start Guide](docs/quick-start.md) - First-time setup walkthrough
- [Hardware Setup](docs/hardware.md) - Detailed hardware configuration and components
- [Installation Guide](docs/setup.md) - Complete installation and configuration
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

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

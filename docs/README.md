# Documentation Index

Complete guide to understanding and using the Portable Pi 5 Cluster Server.

## Getting Started (Start Here!)

1. **[README.md](../README.md)** - Project overview and features
2. **[Quick Start Guide](quick-start.md)** - Get running in 30 minutes
3. **[Installation Guide](setup.md)** - Complete setup walkthrough

## In-Depth Documentation

### Hardware & Setup

- **[Hardware Documentation](hardware.md)**
  - Complete component list and specifications
  - Wiring diagram and physical setup
  - Network configuration
  - Power system overview

### Software & Configuration

- **[Configuration Guide](../config/README.md)**
  - Configuration file organization
  - PXE boot setup
  - NFS and storage configuration
  - NTP and GPS time synchronization

- **[Scripts Documentation](../scripts/README.md)**
  - OLED display monitoring script
  - Security monitoring script
  - Running scripts as systemd services
  - Future script plans

### Operation & Troubleshooting

- **[Troubleshooting Guide](troubleshooting.md)**
  - Network issues and solutions
  - NFS problems
  - Time synchronization troubleshooting
  - Storage issues
  - Security monitoring help
  - OLED display problems
  - SSH access issues
  - Log file guidance

## Project Structure

```
Portable-Pi-5-Cluster-Server/
├── config/                    # Configuration files
│   ├── boot/                 # PXE boot configs
│   ├── network/              # DNS/DHCP configs
│   ├── nfs/                  # NFS configuration
│   ├── ntp/                  # Time sync configuration
│   └── README.md             # Config guide
│
├── docs/                     # Documentation
│   ├── quick-start.md        # 30-minute setup
│   ├── setup.md              # Full installation
│   ├── hardware.md           # Hardware details
│   ├── troubleshooting.md    # Problem solving
│   ├── README.md             # This file
│   └── assets/               # Documentation images
│
├── scripts/                  # Python scripts
│   ├── oled_display_v1.py   # Status display
│   ├── security_monitor_v1.1.py  # Security monitoring
│   └── README.md             # Scripts guide
│
├── README.md                # Project overview
├── LICENSE                  # MIT License
├── CONTRIBUTING.md          # Contribution guidelines
└── .gitignore              # Git ignore rules
```

## Glossary

### Cluster Terms

- **Boot Node**: Primary node providing PXE services, DHCP, TFTP, NFS
- **ISR Node**: Intelligence, Surveillance, Reconnaissance node with SDR monitoring
- **Mesh Node**: LoRa and Reticulum mesh networking node
- **VHF/UHF Node**: Dual-band transceiver interface node
- **PXE**: Preboot Execution Environment (network boot)
- **NFS**: Network File System (shared storage)
- **TFTP**: Trivial File Transfer Protocol
- **DHCP**: Dynamic Host Configuration Protocol
- **NTP**: Network Time Protocol
- **GPS**: Global Positioning System for time sync

### Technology Stack

- **Base**: Raspberry Pi OS (Debian-based Linux)
- **Network**: dnsmasq, NFS, OpenSSH
- **Time Sync**: chrony, gpsd, NTP
- **RF Tools**: FLdigi, Winlink, JS8Call, SDR applications
- **Mesh**: Reticulum, Mosquitto MQTT, FreeTAKServer
- **Monitoring**: Custom Python scripts, psutil
- **Display**: OLED via GPIO, PyGame rendering

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

# Quick Start Guide

Get your Portable Pi 5 Cluster running in 30 minutes.

## Prerequisites

- 4× Raspberry Pi 5 with PoE HATs
- Managed PoE switch
- Cat 6a Ethernet cables
- Network with internet access (for initial setup only)
- SSH access capability

## 5-Minute Boot Node Setup

Assuming your boot node is running Raspberry Pi OS:

```bash
# Clone this repository
git clone https://github.com/yourusername/Portable-Pi-5-Cluster-Server.git
cd Portable-Pi-5-Cluster-Server

# Install core dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y dnsmasq nfs-kernel-server git curl python3-pip

# Apply boot node configuration
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf
sudo cp config/nfs/exports /etc/exports
sudo systemctl restart dnsmasq nfs-kernel-server

# Verify services are running
sudo systemctl status dnsmasq
sudo systemctl status nfs-kernel-server
```

## 10-Minute Other Nodes Setup

For each additional node (ISR, Mesh, VHF):

```bash
# SSH into node
ssh pi@192.168.1.X

# Clone repository
git clone https://github.com/yourusername/Portable-Pi-5-Cluster-Server.git
cd Portable-Pi-5-Cluster-Server

# Run node-specific setup (interactive)
./scripts/setup-node.sh  # [When available]

# Or manually install basic tools
sudo apt update
sudo apt install -y git curl python3-pip openssh-server
```

## Verify Connectivity

From boot node:

```bash
# Test ping to all nodes
ping 192.168.1.20  # ISR
ping 192.168.1.30  # Mesh
ping 192.168.1.40  # VHF

# Test DHCP
dnsmasq --test

# Check NFS
showmount -e localhost
```

## What's Next?

1. **Hardware:** Verify all components in [Hardware Setup](hardware.md)
2. **Full Setup:** Follow [Installation Guide](setup.md) for complete configuration
3. **Troubleshooting:** Check [Troubleshooting](troubleshooting.md) if issues arise
4. **RF Tools:** Configure node-specific applications (SDRs, LoRa, etc.)

## Common Issues

**Nodes can't connect to boot node:**
- Check ethernet cables
- Verify PoE switch is powered
- Run `ip addr` to confirm IP assignment
- See [Troubleshooting](troubleshooting.md)

**NFS mount fails:**
- Verify exports: `showmount -e <boot-node-ip>`
- Check firewall: `sudo ufw status`
- Review `/etc/exports` configuration

**DHCP not working:**
- Restart dnsmasq: `sudo systemctl restart dnsmasq`
- Check config: `sudo dnsmasq --test`
- View logs: `sudo journalctl -u dnsmasq -f`

## Need Help?

- Check [Troubleshooting Guide](troubleshooting.md)
- Review [Hardware Documentation](hardware.md)
- See configuration examples in [config/](../config/) directory
- Open an issue on GitHub

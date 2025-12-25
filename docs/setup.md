# Installation and Setup Guide

This guide walks through setting up the Portable Pi 5 Cluster Server from hardware assembly to full operational deployment.

## Prerequisites

- 4× Raspberry Pi 5 (4GB or 8GB)
- PoE HATs (WaveShare F or similar)
- M.2 SSDs and PCIe HATs
- LoRa HATs for mesh nodes
- USB SDRs for ISR node
- GPS receiver (HiLetGo or similar)
- Managed PoE switch with VLAN support
- Cat 6a Ethernet cables
- Network access and administrative privileges

See [Hardware Setup](hardware.md) for complete hardware requirements and wiring.

## Step 1: Initial System Setup

### 1.1 Install Raspberry Pi OS

For each Raspberry Pi node:

1. Download Raspberry Pi OS Lite (64-bit) from [raspberrypi.com](https://www.raspberrypi.com/software/)
2. Use Raspberry Pi Imager to write to M.2 SSD
3. Enable SSH during initial setup
4. Set hostname according to node type:
   - `boot-node` for PXE server
   - `isr-node` for RF monitoring
   - `mesh-node` for LoRa/Reticulum
   - `vhf-node` for transceiver interface

### 1.2 Network Configuration

Configure static IP addresses for each node. Example network layout:

```
Boot Node:    192.168.1.10
ISR Node:     192.168.1.20
Mesh Node:    192.168.1.30
VHF Node:     192.168.1.40
```

Edit `/etc/dhcpcd.conf`:

```bash
interface eth0
static ip_address=192.168.1.10/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 1.1.1.1
```

## Step 2: Boot Node Configuration

The boot node provides PXE services for the entire cluster.

### 2.1 Install Dependencies

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y dnsmasq nfs-kernel-server openssh-server curl wget git python3-pip
```

### 2.2 Configure DHCP and TFTP

Edit `/etc/dnsmasq.conf` using provided config:

```bash
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf
```

Key settings:
- DHCP range: 192.168.1.100-192.168.1.200
- TFTP root: `/srv/tftp/`
- PXE server: Boot node IP

Restart service:

```bash
sudo systemctl restart dnsmasq
```

### 2.3 Configure NFS

Edit `/etc/exports`:

```bash
sudo cp config/nfs/exports /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```

### 2.4 Configure Time Synchronization

For GPS-based time sync:

```bash
sudo apt install -y gpsd chrony
sudo cp config/ntp/gpsd /etc/default/gpsd
sudo cp config/ntp/chrony/chrony.conf /etc/chrony/chrony.conf
sudo systemctl restart chrony gpsd
```

Verify time sync:

```bash
timedatectl status
chronyc sources
```

## Step 3: Network Configuration

### 3.1 Hostname and Hosts File

Update `hostname` and `hosts`:

```bash
sudo cp config/network/hostname /etc/hostname
sudo cp config/network/hosts /etc/hosts
sudo hostnamectl set-hostname $(cat /etc/hostname)
```

### 3.2 DNS Configuration

Update `/etc/resolv.conf` or use systemd-resolved:

```bash
sudo cp config/network/networks /etc/networks
sudo systemctl restart systemd-resolved
```

## Step 4: Node-Specific Configuration

### ISR Node (RF Monitoring)

1. Install SDR software:

```bash
sudo apt install -y rtl-sdr cubicsdr dump1090-fa
```

2. Plug in USB SDR dongles
3. Configure permissions:

```bash
sudo usermod -a -G plugdev $USER
```

### Mesh Node (LoRa/Reticulum)

1. Install Reticulum:

```bash
sudo pip3 install rns
```

2. Configure LoRa HAT on GPIO
3. Create Reticulum config in `~/.reticulum/`

### VHF/UHF Node (Transceiver)

1. Install transceiver control software
2. Configure serial interface for radio control
3. Test communication parameters

## Step 5: Security Configuration

### 5.1 Firewall Setup

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # SSH
sudo ufw allow 53/tcp  # DNS
sudo ufw allow 53/udp  # DNS
sudo ufw allow 69/udp  # TFTP
sudo ufw enable
```

### 5.2 SSH Hardening

Edit `/etc/ssh/sshd_config`:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

### 5.3 Security Monitoring

Enable security monitor script:

```bash
python3 scripts/security_monitor_v1.1.py &
```

## Step 6: OLED Display Setup (Optional)

Install OLED display drivers and dependencies:

```bash
pip3 install pygame adafruit-circuitpython-ssd1306 pillow
```

Run display script:

```bash
python3 scripts/oled_display_v1.py &
```

## Step 7: Verification

Test cluster connectivity:

```bash
ping 192.168.1.20  # ISR node
ping 192.168.1.30  # Mesh node
ping 192.168.1.40  # VHF node
```

Test NFS mount on remote node:

```bash
mount -t nfs 192.168.1.10:/srv/nfs /mnt/cluster
```

Test DHCP and TFTP:

```bash
dnsmasq --test
tftp -r test.txt 192.168.1.10
```

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.

## Next Steps

- Configure service overlays for node-specific applications
- Set up monitoring and logging infrastructure
- Deploy RF communication software on respective nodes
- Test failover and redundancy scenarios
- Configure wireless access point integration

## Support

For detailed component information, see [Hardware Setup](hardware.md).

For issues, consult [Troubleshooting Guide](troubleshooting.md) or open an issue on the project repository.

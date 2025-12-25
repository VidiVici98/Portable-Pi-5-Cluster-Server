# Configuration Files

This directory contains all configuration files for the Portable Pi 5 Cluster Server.

## Directory Structure

```
config/
├── boot/              # PXE boot server configuration
├── network/           # Network and DNS configuration
├── nfs/              # NFS (Network File System) configuration
└── ntp/              # NTP and GPS time synchronization
```

## Boot Configuration (`boot/`)

Contains PXE boot server configurations.

- **5ac412be/**: Hardware-specific boot configs (MAC address or hardware ID)
  - `cmdline.txt`: Kernel command-line parameters
  - `config.txt`: Raspberry Pi boot configuration

## Network Configuration (`network/`)

Essential network settings for the cluster.

- **dnsmasq.conf**: DHCP, DNS, and TFTP server configuration
  - Defines IP range, DNS settings, TFTP root
  - Configures PXE boot parameters
  
- **hostname**: System hostname for the boot node

- **hosts**: Local hostname-to-IP mappings for cluster nodes

- **networks**: Network definitions (legacy or extended configuration)

## NFS Configuration (`nfs/`)

Network File System setup for shared storage.

- **exports**: NFS share definitions
  - Defines which directories are shared
  - Sets client access permissions
  - Controls mount options

- **fstab**: File system mount table
  - Defines NFS mounts to attach on boot
  - Specifies mount options and retry policies

- **nfs.conf**: NFS daemon configuration
  - Service parameters
  - Performance tuning options

## NTP Configuration (`ntp/`)

Time synchronization via GPS and NTP.

- **gpsd**: GPS daemon configuration
  - Device paths for GPS receiver
  - Baud rate and serial settings
  - GPS signal processing options

- **chrony/**: Chrony NTP daemon configuration
  - **chrony.conf**: Main NTP configuration
    - GPS time source integration
    - NTP server definitions
    - Time sync parameters
  
  - **conf.d/**: Additional configuration modules
  
  - **sources.d/**: Time source definitions
    - **gps.sources**: GPS-based time source configuration
    - **README**: Source configuration documentation

## Using These Configurations

### Applying Configurations

Copy configuration files to the appropriate system locations:

```bash
# Boot node setup
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf
sudo cp config/nfs/exports /etc/exports
sudo cp config/ntp/gpsd /etc/default/gpsd
sudo cp config/ntp/chrony/chrony.conf /etc/chrony/chrony.conf

# Reload services
sudo systemctl restart dnsmasq
sudo exportfs -a
sudo systemctl restart chrony gpsd
```

### Customizing Configurations

Before applying, review and modify as needed:

1. Edit IP addresses to match your network
2. Adjust DHCP ranges for your cluster size
3. Modify NFS paths if using different directories
4. Configure GPS device path for your hardware

See [Installation Guide](../docs/setup.md) for detailed configuration instructions.

## Configuration Notes

- All IP addresses use `192.168.1.x` range (default)
- Boot node: `192.168.1.10`
- ISR node: `192.168.1.20`
- Mesh node: `192.168.1.30`
- VHF node: `192.168.1.40`

Adjust these values according to your network requirements.

## Troubleshooting Configuration

For configuration-related issues, see:
- [Troubleshooting Guide](../docs/troubleshooting.md)
- [Installation Guide](../docs/setup.md)

Configuration errors appear in system logs:

```bash
# Check service-specific logs
sudo journalctl -u dnsmasq -f
sudo journalctl -u nfs-server -f
sudo journalctl -u chrony -f
```

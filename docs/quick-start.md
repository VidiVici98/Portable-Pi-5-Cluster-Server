# Quick Start Guide - Automated Deployment

Deploy your Portable Pi 5 Cluster boot node in **4 automated phases** (~30 minutes total).

## What You Need

- Raspberry Pi 5 running Raspberry Pi OS (Lite 64-bit recommended)
- Internet access for initial setup
- SSH access to the Pi
- This repository cloned to the boot node

## 1-Minute Initial Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/Portable-Pi-5-Cluster-Server.git
cd Portable-Pi-5-Cluster-Server

# Make scripts executable (one-time only)
chmod +x deployments/boot-node/*.sh
```

## Deploy Boot Node (4 Automated Phases)

Run these commands in order. Each phase is idempotent (safe to rerun):

### Phase 1: System Setup (~5-10 minutes)
```bash
sudo bash deployments/boot-node/01-system-setup.sh
```
Sets hostname to `boot-node`, updates OS, configures timezone, applies kernel hardening.

### Phase 2: Install Services (~5-10 minutes)
```bash
sudo bash deployments/boot-node/02-install-services.sh
```
Installs DHCP/DNS, TFTP, NFS, time sync, firewall, brute force protection, and monitoring tools.

### Phase 3: Configure Services (~5 minutes)
```bash
sudo bash deployments/boot-node/03-configure-services.sh
```
Deploys configs, sets up firewall rules, enables services, creates TFTP boot files.

### Phase 4: Verify Setup (~2-5 minutes)
```bash
sudo bash deployments/boot-node/04-verify-setup.sh
```
Runs 70+ tests across 9 categories: system health, services, network, security, ports, NFS, TFTP, NTP, firewall.

**Exit code 0 = ✅ All tests passed**

## Automate Operations (Optional)

### Daily Backups
```bash
sudo crontab -e
# Add: 0 2 * * * /home/jon/Portable-Pi-5-Cluster-Server/operations/backups/backup-daily.sh
```

### Hourly Health Monitoring
```bash
sudo crontab -e
# Add: 0 * * * * /home/jon/Portable-Pi-5-Cluster-Server/operations/maintenance/health-check.sh quiet
```

View health status:
```bash
tail -50 operations/logs/health-check.log
```

## Deploy Other Nodes

For each additional node (ISR, Mesh, VHF):

```bash
ssh pi@<node-ip>
git clone https://github.com/yourusername/Portable-Pi-5-Cluster-Server.git

# Configure static IP
sudo nano /etc/dhcpcd.conf  # See SETUP.md for details

# Node-specific setup (see SETUP.md or NODE-SETUP.md)
```

## What's Next?

✅ **Boot node deployed**

1. **Detailed setup guide:** [SETUP.md](SETUP.md) for per-node configuration
2. **Hardware requirements:** [HARDWARE.md](HARDWARE.md)
3. **Script reference:** [SCRIPTS-REFERENCE.md](../scripts/SCRIPTS-REFERENCE.md)
4. **Operations guide:** [OPERATIONS.md](../operations/OPERATIONS.md)
5. **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Troubleshooting

**Phase fails?** Check logs and rerun same phase:
```bash
tail -50 /var/log/boot-node-setup.log
sudo bash deployments/boot-node/03-configure-services.sh  # Example: rerun phase 3
```

**Phase 4 reports failures?** 
- Read failure messages (most include fixes)
- Check service logs: `journalctl -u dnsmasq -n 20`
- Check firewall: `sudo ufw status`
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed help

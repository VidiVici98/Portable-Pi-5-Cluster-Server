# Troubleshooting Guide

Common issues and solutions for the Portable Pi 5 Cluster.

## Network Issues

### Nodes can't communicate with boot node

**Check connectivity:**

```bash
ping 192.168.1.10  # From other node to boot node
ip addr            # Verify IP assignment
arp -a             # Check ARP table
```

**Verify DHCP is working:**

```bash
sudo dnsmasq --test
sudo systemctl status dnsmasq
sudo journalctl -u dnsmasq -f
```

**Check network interface:**

```bash
ifconfig
ip link show
ethtool eth0
```

### DNS not resolving

**Verify dnsmasq configuration:**

```bash
sudo cat /etc/dnsmasq.conf
sudo systemctl restart dnsmasq
nslookup google.com 192.168.1.10
```

**Check resolv.conf:**

```bash
cat /etc/resolv.conf
sudo systemctl restart systemd-resolved
```

### TFTP not responding

```bash
# Test TFTP from another node
tftp 192.168.1.10
> get test.txt
> quit

# Check dnsmasq TFTP config
grep "tftp" /etc/dnsmasq.conf
```

## NFS Issues

### Cannot mount NFS share

**Verify NFS service is running:**

```bash
sudo systemctl status nfs-kernel-server
sudo exportfs -a
showmount -e 192.168.1.10
```

**Check exports configuration:**

```bash
sudo cat /etc/exports
sudo exportfs -r  # Reload exports
```

**Mount with verbose output:**

```bash
sudo mount -v -t nfs 192.168.1.10:/srv/nfs /mnt/cluster
mount | grep nfs  # Verify mount
```

**Permission denied on NFS:**

```bash
# Check file permissions on server
ls -l /srv/nfs
sudo chown -R nobody:nogroup /srv/nfs
sudo chmod 777 /srv/nfs
```

### NFS filesystem errors

**Check filesystem integrity:**

```bash
sudo fsck /dev/sda1  # Adjust device name
```

**Repair filesystem:**

```bash
sudo umount /srv/nfs
sudo fsck -y /dev/sda1
sudo mount /srv/nfs
```

## Time Synchronization Issues

### Time not syncing from GPS

**Verify GPS is connected:**

```bash
ls -l /dev/ttyUSB*
sudo gpsctl -v
```

**Check chronyd status:**

```bash
sudo systemctl status chrony
chronyc sources       # Show time sources
chronyc tracking      # Show synchronization status
```

**Check gpsd configuration:**

```bash
sudo cat /etc/default/gpsd
sudo systemctl restart gpsd
```

**Manual time setting (if needed):**

```bash
sudo date -s "2025-12-25 14:30:00"
timedatectl status
```

## Storage Issues

### SSD Not recognized

**Check device detection:**

```bash
lsblk
lspci
dmesg | tail -20
```

**Verify PCIe HAT connection:**

```bash
# Reboot and check
sudo reboot
lsblk  # Should show M.2 SSD
```

### Slow NFS performance

**Monitor I/O:**

```bash
iostat -x 1
iotop
```

**Check SSD health:**

```bash
sudo apt install -y smartmontools
sudo smartctl -a /dev/nvme0n1
```

## Security Monitoring

### Security monitor not running

**Check script status:**

```bash
ps aux | grep security_monitor
sudo python3 scripts/security_monitor_v1.1.py --test
```

**View security status:**

```bash
cat /tmp/security_status
```

**Check resource usage:**

```bash
top
free -h
df -h
```

## OLED Display Issues

### Display not showing output

**Verify display connection:**

```bash
i2cdetect -y 1  # Should show device at 0x3C
ls -l /dev/i2c*
```

**Check script execution:**

```bash
python3 scripts/oled_display_v1.py
```

**Verify dependencies:**

```bash
pip3 list | grep -i pygame
pip3 list | grep -i adafruit
```

## SSH Access Issues

### Cannot SSH to nodes

**Verify SSH is running:**

```bash
sudo systemctl status ssh
ssh localhost  # Test locally first
```

**Check SSH configuration:**

```bash
sudo cat /etc/ssh/sshd_config
sudo sshd -t  # Test config
```

**Test SSH with verbose output:**

```bash
ssh -vvv pi@192.168.1.20
```

## System Logs

**View system logs:**

```bash
sudo journalctl -xe              # Latest errors
sudo journalctl -u dnsmasq -f   # Follow dnsmasq
sudo journalctl -u nfs-server -f # Follow NFS
dmesg | tail -50                 # Kernel messages
```

**Check system status:**

```bash
systemctl status
systemctl list-units --failed
```

## Getting Help

If issues persist:

1. Collect diagnostic information:
   ```bash
   uname -a
   cat /etc/os-release
   ip addr
   systemctl list-units --failed
   journalctl -xe
   ```

2. Check [Installation Guide](setup.md) for configuration details

3. Review [Hardware Setup](hardware.md) for component requirements

4. Open an issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Relevant log output
   - Hardware configuration

# Pre-Deployment Checklist

**Purpose:** Verify readiness before deploying to cluster  
**Version:** 1.0  
**Date:** December 25, 2025  

## System Readiness

- [ ] Boot node has stable power supply
- [ ] Ethernet cable connected to network
- [ ] SD card has proper read/write permissions
- [ ] Sufficient disk space (at least 1GB free)
- [ ] Network connectivity verified
- [ ] Internet access available for package downloads
- [ ] DNS resolution working (`ping 8.8.8.8`)
- [ ] System time is correct (`date`)
- [ ] All required packages installed (`make test`)

## Configuration Validation

- [ ] `validate-config.sh` runs without errors
- [ ] All templates have placeholders filled
- [ ] No syntax errors in config files
- [ ] Network configuration is correct
- [ ] NFS exports defined
- [ ] DHCP scope is correct
- [ ] DNS forward/reverse zones configured
- [ ] Hostname set correctly
- [ ] Static IP configured
- [ ] Gateway/DNS servers correct

## Security Baseline

- [ ] SSH keys generated and in place
- [ ] SSH public key in `authorized_keys`
- [ ] No passwords stored in plain text
- [ ] Secrets directory created and ignored by git
- [ ] `.gitignore` includes secrets
- [ ] Database passwords set
- [ ] API keys obtained
- [ ] TLS certificates generated
- [ ] File permissions on secrets: 600

## Backups

- [ ] Current system state backed up
- [ ] Boot configuration backed up
- [ ] Network configuration backed up
- [ ] NFS exports backed up
- [ ] SSH keys backed up (encrypted)
- [ ] Backup location is accessible
- [ ] Restore procedure tested
- [ ] Backup location is NOT in git repository

## Documentation

- [ ] Network diagram available
- [ ] IP address allocation documented
- [ ] Service dependency diagram available
- [ ] Emergency contact information available
- [ ] Quick start guide reviewed
- [ ] Troubleshooting guide reviewed
- [ ] Security procedures documented
- [ ] Recovery procedures documented

## Git Repository

- [ ] Repository initialized
- [ ] README.md reviewed and accurate
- [ ] LICENSE file included
- [ ] CONTRIBUTING.md reviewed
- [ ] `.gitignore` properly configured
- [ ] No secrets in staging area
- [ ] No temporary files in staging
- [ ] All files committed
- [ ] Remote repository configured
- [ ] Initial backup pushed to remote

## Network Preparation

- [ ] Network DHCP scope planned
- [ ] Static IPs assigned to each node
- [ ] Network diagram created
- [ ] Network security reviewed
- [ ] Firewall rules planned
- [ ] DNS records planned
- [ ] NTP server identified
- [ ] Network latency acceptable (<100ms between nodes)
- [ ] Bandwidth adequate for NFS

## Hardware Verification

### Boot Node
- [ ] Raspberry Pi 5 powered on
- [ ] SD card recognized
- [ ] USB storage available
- [ ] Ethernet connected and active
- [ ] LED indicators normal
- [ ] Temperature acceptable (<80°C)
- [ ] Voltage stable (5V ±5%)

### Network Nodes (ISR, Mesh, VHF)
- [ ] Devices available for imaging
- [ ] Network connectivity ready
- [ ] Power supplies ready
- [ ] Network topology planned

## Service Readiness

### DHCP/TFTP
- [ ] dnsmasq installed
- [ ] DHCP scope configured
- [ ] TFTP root directory ready
- [ ] Boot files in place
- [ ] Test client can request lease

### NFS
- [ ] NFS utilities installed
- [ ] Export paths created
- [ ] Export permissions set
- [ ] Test mount successful

### DNS
- [ ] DNS forwarder configured
- [ ] Local zone configured
- [ ] Reverse zone configured
- [ ] Test queries resolve

### Time/GPS
- [ ] chrony installed
- [ ] GPS device detected (if using)
- [ ] ntpd configured
- [ ] Time sync verified

## Operational Readiness

- [ ] On-call schedule established
- [ ] Escalation procedures documented
- [ ] Monitoring plan created
- [ ] Alert thresholds defined
- [ ] Disaster recovery plan reviewed
- [ ] Incident response plan reviewed
- [ ] Team training completed

## Sign-Off

- [ ] **Operator:** _________________ **Date:** _________
- [ ] **Reviewer:** _________________ **Date:** _________
- [ ] **Approver:** _________________ **Date:** _________

## Notes

```
[Space for deployment notes and special considerations]
```

---

**Do not proceed until all items are checked.**

For issues, see: [troubleshooting.md](docs/troubleshooting.md)

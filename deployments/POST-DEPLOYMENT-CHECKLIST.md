# Post-Deployment Checklist

**Purpose:** Verify successful deployment and operational status  
**Version:** 1.0  
**Date:** December 25, 2025  

## System Status

- [ ] Boot node boots successfully
- [ ] System logs show no critical errors
- [ ] Disk usage within acceptable range (<80%)
- [ ] Memory usage stable
- [ ] CPU temperature normal (<80°C)
- [ ] No emergency resets in last 24 hours
- [ ] System time is correct
- [ ] All mounted filesystems operational

## Network Connectivity

- [ ] Boot node has IP address
- [ ] DNS resolution working
- [ ] Can ping gateway
- [ ] Can ping external host (8.8.8.8)
- [ ] Network throughput acceptable
- [ ] Ping latency stable
- [ ] No packet loss
- [ ] MTU size correct (1500)
- [ ] Interface statistics normal

## DHCP/TFTP Service

- [ ] dnsmasq service is running
- [ ] DHCP server responding
- [ ] Test client receives IP lease
- [ ] Lease expiration working
- [ ] TFTP boot files accessible
- [ ] Test boot over network successful
- [ ] No DHCP pool exhaustion
- [ ] DHCP logs show normal operation

## NFS Service

- [ ] NFS service is running
- [ ] NFS ports listening
- [ ] Export list correct (`showmount -e`)
- [ ] Test mount from localhost successful
- [ ] Test mount from remote successful
- [ ] File read/write working
- [ ] Permissions correct
- [ ] Performance acceptable
- [ ] No stale handles
- [ ] NFS logs show normal operation

## DNS Service

- [ ] DNS service is running
- [ ] DNS ports listening
- [ ] Forward lookup working
- [ ] Reverse lookup working
- [ ] Local domain resolves correctly
- [ ] External queries forwarded correctly
- [ ] Query response time acceptable
- [ ] No SERVFAIL errors
- [ ] Cache statistics reasonable
- [ ] DNS logs show normal operation

## SSH Access

- [ ] SSH service is running
- [ ] SSH port listening
- [ ] Key-based authentication working
- [ ] Can SSH from local network
- [ ] Password authentication disabled
- [ ] Root login disabled
- [ ] Can SSH from different subnets
- [ ] SSH logs show normal operation
- [ ] No failed authentication attempts
- [ ] Known hosts file correct

## Time Synchronization

- [ ] ntpd/chrony running
- [ ] Time synchronized to NTP server
- [ ] System time within ±1 second of reference
- [ ] Time offset minimal
- [ ] GPS time (if configured) tracking correctly
- [ ] Leap second handling correct
- [ ] Time logs show normal operation

## Security

- [ ] Firewall is enabled and active
- [ ] UFW rules applied correctly
- [ ] No unexpected open ports
- [ ] Fail2Ban service running
- [ ] SSH brute force protection active
- [ ] Sudo audit logging enabled
- [ ] File permissions correct
- [ ] No world-readable secrets
- [ ] Security logs monitored
- [ ] No privilege escalation attempts

## Services Status

```bash
sudo systemctl status --all | grep -E "dnsmasq|nfs|ssh|chrony|ufw"
```

Check all critical services:
- [ ] dnsmasq is active (running)
- [ ] nfs-server is active (running) or nfs-client ready
- [ ] ssh is active (running)
- [ ] chrony is active (running)
- [ ] ufw is active (enabled)

## Monitoring

- [ ] Monitoring service running
- [ ] Metrics being collected
- [ ] Dashboard accessible
- [ ] Alerts configured
- [ ] Alert thresholds appropriate
- [ ] No false positive alerts
- [ ] Historical data available
- [ ] Query performance acceptable

## Logging

- [ ] Syslog service running
- [ ] Logs being written
- [ ] Log rotation configured
- [ ] Old logs being archived
- [ ] Log retention policy enforced
- [ ] No disk space issues from logs
- [ ] Sensitive information not in logs
- [ ] Log analysis possible

## Backup Verification

- [ ] Backup job executed successfully
- [ ] Backup files present and recent
- [ ] Backup size reasonable
- [ ] Backup encryption verified
- [ ] Backup integrity verified
- [ ] Restore from backup tested
- [ ] Backup logs show success

## Performance Baseline

- [ ] Network throughput measured: __________ Mbps
- [ ] Disk I/O measured: __________ IOPS
- [ ] CPU utilization at idle: __________ %
- [ ] Memory utilization at idle: __________ %
- [ ] SSH login time: __________ seconds
- [ ] NFS mount time: __________ seconds
- [ ] DNS query time: __________ ms

## Operational Procedures

- [ ] Status check procedure works
- [ ] Configuration validation works
- [ ] Diagnostic tools accessible
- [ ] Health check script runs successfully
- [ ] Alert escalation tested
- [ ] Incident response tested
- [ ] Recovery procedure accessible

## Documentation

- [ ] All procedures documented
- [ ] IP address table updated
- [ ] Service dependency diagram verified
- [ ] Network topology accurate
- [ ] Known issues documented
- [ ] Configuration changes logged
- [ ] Runbooks created
- [ ] Contact information current

## Cluster Integration

If deploying additional nodes:
- [ ] Node boot from network successful
- [ ] Node obtained IP lease
- [ ] Node mounted NFS root
- [ ] Node synchronized time from boot node
- [ ] Node resolves DNS queries
- [ ] Node can SSH to boot node
- [ ] Boot node can SSH to node
- [ ] Multi-node communication verified

## Hardware Health

- [ ] Temperature sensors reporting
- [ ] Voltage sensors reporting
- [ ] No over-current conditions
- [ ] Power consumption acceptable
- [ ] Thermal paste applied correctly
- [ ] Cooling adequate
- [ ] No physical damage
- [ ] All cables secure

## Final Verification

- [ ] All services responding normally
- [ ] No critical errors in logs
- [ ] Backup recent and verified
- [ ] Configuration backed up
- [ ] Team notified of deployment
- [ ] Known limitations documented
- [ ] Next steps identified

## Performance Regression Check

Compare to baseline:
- [ ] CPU utilization: ±10%
- [ ] Memory utilization: ±10%
- [ ] Disk I/O: ±20%
- [ ] Network latency: ±5ms
- [ ] Service response times: ±10%

## Sign-Off

- [ ] **Operator:** _________________ **Date:** _________
- [ ] **Verifier:** _________________ **Date:** _________
- [ ] **Approver:** _________________ **Date:** _________

## Notes

```
[Space for post-deployment observations and issues found]
```

## Action Items

| Item | Owner | Due Date | Status |
|------|-------|----------|--------|
|      |       |          |        |
|      |       |          |        |
|      |       |          |        |

---

**If any items are not checked, investigate before declaring operational.**

For issues, see: [troubleshooting.md](../../docs/troubleshooting.md)

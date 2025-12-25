# Phase 1 Implementation Guide

**Status:** ✅ Complete  
**Date:** December 25, 2025  
**Version:** 0.1.1  

## What Phase 1 Provides

Phase 1 delivers **diagnostic-first tooling** designed to help you understand your current cluster state and validate changes before applying them.

Three main components:

| Tool | Purpose | Usage |
|------|---------|-------|
| **cluster-status.sh** | Complete system diagnostics | `sudo make status` |
| **validate-config.sh** | Configuration syntax validation | `make validate` |
| **Makefile** | Standardized operations | `make [command]` |

---

## Getting Started with Phase 1

### 1. Run Initial Diagnostics

```bash
# Get full picture of current system state
make diagnose

# This runs:
# - Configuration validation
# - System health check
# - Service status
# - Connectivity tests
# - Resource usage
```

**What to look for in output:**
- How many services are running?
- Are any nodes online besides boot node?
- What configurations exist vs. missing?
- Any critical failures?

### 2. Check Specific Status

```bash
# Quick status (no validation)
make status

# Just validate configs
make validate

# Show available backups
make list-backups
```

### 3. Safe Configuration Testing

```bash
# Always backup before changes
make backup

# Validate your changes
make validate

# Apply your changes
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf

# Verify nothing broke
make status
```

---

## Understanding the Output

### cluster-status.sh Output

**Color Coding:**
- 🟢 `✓ PASS` - System is healthy or component is working
- 🟡 `⚠ WARN` - Component exists but may need attention
- 🔴 `✗ FAIL` - Critical component missing or broken
- 🔵 `ℹ INFO` - Informational message

**Example Output Interpretation:**

```
=== Boot Node Services ===
✓ PASS: Service running: dnsmasq
⚠ WARN: Service not running: nfs-server (inactive)
✓ PASS: Service running: ssh
⚠ WARN: Service not running: chronyd (inactive)

Results Summary:
  PASS: 47
  WARN: 12
  FAIL: 3

⚠ Some issues detected - see report for details
Full report saved to: /tmp/cluster-status-20251225-004200.txt
```

**What This Means:**
- ✓ Boot node itself is responding
- ✓ DHCP (dnsmasq) is running - can provide IPs
- ⚠ NFS not running - nodes can't mount file systems
- ⚠ Chrony not running - time sync disabled
- ⚠ 12 minor warnings, 3 failures - not ready for multi-node cluster yet

### validate-config.sh Output

```
=== DNSMASQ Configuration ===
✓ dnsmasq.conf found
ℹ DHCP range configured: dhcp-range=192.168.1.100,192.168.1.200,12h
✓ Interface configured
⚠ PXE boot not configured
✗ TFTP not enabled

Summary:
  PASS: 8
  WARN: 5
  FAIL: 2

✗ Configuration issues found
```

**What This Means:**
- Config file exists ✓
- DHCP range is set ✓
- But PXE boot isn't configured ⚠
- TFTP not enabled ✗ - needed for network boot

---

## Workflow Examples

### Scenario 1: First Time Checking System

```bash
# See what you have
make diagnose

# Read the report
cat /tmp/cluster-status-*.txt

# Check configuration
make validate

# Now you know:
# - What services are running
# - What's configured
# - What's missing
# - What needs fixing
```

### Scenario 2: Troubleshooting Boot Node Issues

```bash
# Something isn't working
make status

# See detailed diagnostics in report
tail -100 /tmp/cluster-status-*.txt

# Check if config is valid
make validate

# Backup before trying fixes
make backup

# Make changes to config files
# Then validate
make validate

# Check if it worked
make status
```

### Scenario 3: Safe Configuration Changes

```bash
# Current state
make status > /tmp/status-before.txt

# Backup current config
make backup

# Make your changes to config files
nano config/network/dnsmasq.conf

# Validate changes won't break syntax
make validate

# Check status again
make status > /tmp/status-after.txt

# Compare
diff /tmp/status-before.txt /tmp/status-after.txt

# If something breaks, restore
make restore-config
```

---

## Key Findings After Running Diagnostics

### Expected for Boot Node Only

If you're seeing:
```
⚠ WARN: Only boot node online (no cluster detected)
```

This is **normal** - you haven't set up other nodes yet.

### Issues to Address

Common issues Phase 1 will find:

1. **Missing Directories**
   ```
   ✗ FAIL: Directory missing: /srv/tftp (needed for PXE boot)
   ```
   Solution: Create directories
   ```bash
   sudo mkdir -p /srv/tftp /srv/nfs
   ```

2. **Missing Config Files**
   ```
   ✗ FAIL: File missing: /etc/dnsmasq.conf
   ```
   Solution: Copy from repo
   ```bash
   sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf
   ```

3. **Services Not Running**
   ```
   ⚠ WARN: Service not running: dnsmasq (inactive)
   ```
   Solution: Install and start
   ```bash
   sudo apt install dnsmasq
   sudo systemctl start dnsmasq
   ```

4. **Invalid Configuration**
   ```
   ✗ FAIL: dnsmasq syntax error
   ```
   Solution: Review the config file for errors
   ```bash
   dnsmasq --test --conf-file=/etc/dnsmasq.conf
   ```

---

## What's NOT Ready Yet

Phase 1 is **diagnostic-only**. These will be added in Phase 2:

- Automated setup scripts
- Node provisioning
- Configuration templates
- Automated testing
- Integration checks

---

## Next Steps After Phase 1

Once you understand your current state:

1. **Run diagnostics regularly** to spot issues
2. **Use Makefile for consistency** - one command pattern
3. **Always backup before changes** - safe experimentation
4. **Validate before applying** - catch errors early
5. **Document findings** - saved reports for reference

---

## Scripts Documentation

- [cluster-status.sh](scripts/README.md#cluster-statussh) - Full documentation
- [validate-config.sh](scripts/README.md#validate-configsh) - Full documentation
- [Makefile usage](scripts/README.md#makefile-operations) - All commands

## Troubleshooting Phase 1 Tools

### cluster-status.sh fails with "must be run with sudo"

```bash
# Wrong:
./scripts/cluster-status.sh

# Right:
sudo ./scripts/cluster-status.sh

# Or use Makefile (handles sudo):
make status
```

### validate-config.sh says config missing

```bash
# Check what exists
ls -la config/network/

# Config files should be in repo
# If missing, restore from git
git checkout -- config/
```

### Makefile commands not found

```bash
# Make sure you're in repo root
pwd  # Should show: /home/jon/Portable-Pi-5-Cluster-Server

# Should be in same directory as Makefile
ls -la Makefile
```

### Report file not found

```bash
# Reports saved with timestamp
ls -la /tmp/cluster-status-*.txt

# View latest
cat /tmp/cluster-status-*.txt | tail -100
```

---

## Summary

**Phase 1 gives you:**

✅ **Visibility** - See what's working, what's not  
✅ **Validation** - Check changes before applying  
✅ **Safety** - Backup system before experiments  
✅ **Consistency** - One command pattern via Makefile  

**To start:**

```bash
cd /home/jon/Portable-Pi-5-Cluster-Server
make diagnose
```

This single command will tell you everything about your current system state.

---

**Questions?**
- Check [Troubleshooting Guide](docs/troubleshooting.md)
- Review [Project Status](PROJECT_STATUS.md)
- Run `make help` for all commands

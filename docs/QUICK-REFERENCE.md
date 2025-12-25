# Phase 1 Quick Reference

## Essential Commands

```bash
# Start here - understand your system
make diagnose               # Full diagnostics
make status                 # Quick health check
make validate               # Check configs

# Safe configuration changes
make backup                 # Backup before changes
make restore-config         # Restore if needed
make list-backups           # See available backups

# Utilities
make help                   # Show all commands
make check-services         # Service status
make watch-logs             # Monitor logs
make clean                  # Clean temp files
```

## Typical Workflow

```bash
# 1. Understand current state
make diagnose

# 2. Read detailed report
cat /tmp/cluster-status-*.txt

# 3. Plan changes
make validate

# 4. Backup current config
make backup

# 5. Make your changes
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf

# 6. Validate the change
make validate

# 7. Check if it worked
make status

# 8. If it broke, restore
make restore-config
```

## What to Read

- **Getting started:** [PHASE1-GUIDE.md](PHASE1-GUIDE.md)
- **Help with issues:** [Troubleshooting Guide](docs/troubleshooting.md)
- **Understanding system:** [PROJECT_STATUS.md](PROJECT_STATUS.md)
- **Script details:** [scripts/README.md](scripts/README.md)

## Key Files

```
Makefile                    # Orchestrates all operations
scripts/cluster-status.sh   # System diagnostics
scripts/validate-config.sh  # Configuration validation
config/                     # All configuration templates
```

## Expected Output

### After `make diagnose`:

- Green ✓ = Good
- Yellow ⚠ = Warning
- Red ✗ = Critical
- Blue ℹ = Information

```
Results Summary:
  PASS: 45     # Things working
  WARN: 10     # Things that may need attention
  FAIL: 3      # Critical issues

Report saved to: /tmp/cluster-status-[timestamp].txt
```

## Troubleshooting

**Problem:** "must be run with sudo"
```bash
make status              # Handles sudo automatically
```

**Problem:** Makefile not found
```bash
cd /home/jon/Portable-Pi-5-Cluster-Server
make help
```

**Problem:** Can't find report
```bash
ls -la /tmp/cluster-status-*.txt
```

## One Command to Start

```bash
make diagnose
```

This single command will:
1. ✓ Validate all your configurations
2. ✓ Check system health
3. ✓ Test connectivity
4. ✓ Save detailed report
5. ✓ Show summary

---

**Next:** Read [PHASE1-GUIDE.md](PHASE1-GUIDE.md) for detailed usage

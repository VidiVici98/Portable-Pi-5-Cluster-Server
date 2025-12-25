# Cluster Scripts

Tools for monitoring, management, diagnostics, and operational support of the Portable Pi 5 Cluster.

## Phase 1: Diagnostic & Validation Tools

### cluster-status.sh

**Purpose:** Complete system diagnostics and health check of the cluster.

**Features:**
- System information (hardware, OS, memory, storage)
- Network interface status
- Service status (DHCP, NFS, SSH, NTP, etc.)
- TFTP/PXE boot configuration validation
- NFS exports verification
- DNSMASQ configuration review
- Node connectivity testing (ping)
- SSH accessibility check
- Configuration file presence verification
- System resource usage monitoring
- Comprehensive diagnostic report

**Usage:**

```bash
# Run full diagnostics (requires sudo)
sudo ./scripts/cluster-status.sh

# Or use Makefile shortcut
make status
```

**Output:**
- Console output with color-coded results (✓ PASS, ⚠ WARN, ✗ FAIL)
- Full diagnostic report saved to `/tmp/cluster-status-[timestamp].txt`
- Summary showing PASS/WARN/FAIL counts

**When to Run:**
- After system startup
- After making configuration changes
- When troubleshooting issues
- Regularly to monitor health

---

### validate-config.sh

**Purpose:** Validate configuration files before applying them to the system.

**Features:**
- DNSMASQ configuration syntax check
- DHCP range validation
- PXE boot configuration verification
- TFTP setup validation
- NFS exports syntax validation
- Chrony/NTP configuration check
- GPS time reference validation
- Network hosts file validation
- Required directories verification
- IP address format validation

**Usage:**

```bash
# Validate all configuration files
./scripts/validate-config.sh

# Or use Makefile shortcut
make validate
```

**Output:**
- Console output showing validation status
- Summary of PASS/WARN/FAIL results
- Returns 0 if all valid, 1 if issues found

**When to Run:**
- Before applying configuration changes
- Before deploying to a new node
- As part of pre-deployment checklist
- When updating configuration files

---

## Makefile Operations

The `Makefile` in the repository root provides convenient shortcuts for common tasks:

```bash
# Show all available commands
make help

# Diagnostic operations
make status                 # Quick cluster status check
make validate               # Validate all configurations
make diagnose               # Full diagnostics (validate + status)

# Configuration management
make backup                 # Backup current configuration
make restore-config         # Restore from latest backup
make list-backups           # List available backups
make clean                  # Remove temporary files

# Service checks
make check-services         # Show boot node service status
make watch-logs             # Monitor cluster logs (Ctrl+C to exit)

# Git operations
make git-check              # Show git status
```

**Example Workflow:**

```bash
# Before making changes
make backup                 # Safe backup

# Validate changes are safe
make validate               # Check config syntax

# Apply changes manually
sudo cp config/network/dnsmasq.conf /etc/dnsmasq.conf

# Verify everything still works
make status                 # Full diagnostics
```

---

## Available Scripts

### oled_display_v1.py

**Purpose:** Display real-time cluster node status on 0.91" OLED displays.

**Features:**
- Shows connection status and ping latency to boot node
- Displays CPU and memory usage
- Alerts on security breach detection
- Rotates between multiple information screens
- Compatible with SSD1306 OLED displays (GPIO-connected)

**Requirements:**
- Adafruit SSD1306 library
- PyGame for rendering
- Pillow for image handling
- psutil for system metrics

**Installation:**

```bash
pip3 install pygame adafruit-circuitpython-ssd1306 pillow psutil
```

**Usage:**

```bash
# Run directly
python3 scripts/oled_display_v1.py

# Run in background
python3 scripts/oled_display_v1.py &

# Run as system service (create systemd service)
sudo nano /etc/systemd/system/cluster-oled.service
```

**Configuration:**

Edit script variables at the top:
- `screen_width` and `screen_height`: OLED display resolution (default: 128×64)
- `font`: Display font selection
- Master node IP: Default `192.168.1.1` (adjust for your boot node)

**Output:**
- Displays node connection status
- Shows system resource usage
- Alerts on security events via `/tmp/security_status` file

---

### security_monitor_v1.1.py

**Purpose:** Monitor system security and resource usage, detect breaches and anomalies.

**Features:**
- Monitors CPU and memory usage against thresholds
- Detects high-resource conditions
- Writes breach status to `/tmp/security_status` for display scripts
- Test mode for validation
- Can be extended for additional breach detection logic

**Requirements:**
- psutil library

**Installation:**

```bash
pip3 install psutil
```

**Usage:**

```bash
# Run monitoring loop
python3 scripts/security_monitor_v1.1.py

# Test mode (one-time check)
python3 scripts/security_monitor_v1.1.py --test

# Run in background
python3 scripts/security_monitor_v1.1.py > /var/log/security_monitor.log 2>&1 &
```

**Configuration:**

Edit thresholds in the script:
- `cpu_threshold`: CPU usage percentage (default: 80%)
- `memory_threshold`: Memory usage percentage (default: 90%)

**Output:**
- Console warnings when thresholds exceeded
- Writes `/tmp/security_status` file with "BREACH" status
- Integrates with OLED display for visual alerts

**Extension Points:**

Add custom breach detection:

```python
def check_for_breach():
    # ... existing checks ...
    
    # Add custom checks
    if check_file_integrity():
        breach_detected = True
    
    if check_unauthorized_access():
        breach_detected = True
```

---

## Running Scripts as Services

### Create a systemd service for OLED display

```bash
sudo nano /etc/systemd/system/cluster-oled.service
```

Add:

```ini
[Unit]
Description=Cluster Node OLED Display
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/python3 /path/to/scripts/oled_display_v1.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cluster-oled
sudo systemctl start cluster-oled
sudo systemctl status cluster-oled
```

### Create a systemd service for security monitoring

```bash
sudo nano /etc/systemd/system/cluster-security.service
```

Add:

```ini
[Unit]
Description=Cluster Security Monitor
After=network.target

[Service]
Type=simple
User=pi
ExecStart=/usr/bin/python3 /path/to/scripts/security_monitor_v1.1.py
Restart=always
RestartSec=5
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable cluster-security
sudo systemctl start cluster-security
sudo systemctl status cluster-security
```

---

## Monitoring Script Execution

Check if scripts are running:

```bash
ps aux | grep oled_display
ps aux | grep security_monitor

# Check service status
sudo systemctl status cluster-oled
sudo systemctl status cluster-security

# View logs
sudo journalctl -u cluster-oled -f
sudo journalctl -u cluster-security -f
```

---

## Future Scripts

Planned additions:
- **Node deployment script**: Automated setup for new cluster nodes
- **Health check dashboard**: Web UI for cluster status
- **Configuration manager**: Remote config deployment
- **Log aggregation**: Centralized logging from all nodes

---

## Contributing

New scripts should:
1. Include clear docstrings explaining purpose and usage
2. Handle errors gracefully
3. Log important events
4. Support both interactive and background execution
5. Be configurable without code edits
6. Include usage examples in docstrings

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

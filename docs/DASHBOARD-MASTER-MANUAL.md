# Cluster Command & Control Dashboard  
## Full Operator & Administrator Guide

---

## Table of Contents

1. Introduction
2. Operating Philosophy
3. Demo Mode vs Live Cluster Mode
4. Global Interface & Navigation
5. Dashboard Overview (Command & Control)
6. Mesh Network & Node Topology
7. ISR / Airspace & SIGINT Operations
8. RF Communications & SDR Control
9. Performance & Resource Monitoring
10. Settings & Configuration Management
11. Security, OPSEC, and Destructive Actions
12. Alerts, Logs, and Audit Trails
13. Recommended Operator Workflows
14. System Limitations & Future Expansion

---

## 1. Introduction

The **Cluster Command & Control Dashboard** is a unified web-based control surface for managing a modular, multi-node tactical compute cluster. It is designed for environments where:

- Nodes may be geographically distributed
- Network links may be unreliable or contested
- RF emissions matter
- Operator attention is limited
- Failure is expected, not exceptional

The dashboard consolidates **status, control, monitoring, and security actions** into a single interface that can be operated from a laptop, tablet, or hardened field device.

This document explains **how to use the dashboard**, **what each page does**, and **how actions affect the underlying system**.

---

## 2. Operating Philosophy

The dashboard is built around several core assumptions:

- **Transparency over automation**  
  The system shows you what it is doing. Automation exists, but it is visible and configurable.

- **Explicit state over implicit behavior**  
  Nodes, services, and links are always shown as online, offline, degraded, or pending.

- **Operator intent is primary**  
  Destructive or disruptive actions require deliberate confirmation.

- **Training and live operation share the same interface**  
  Demo Mode behaves the same as live mode, minus hardware effects.

This philosophy ensures operators can train, rehearse, and operate under stress without relearning workflows.

---

## 3. Demo Mode vs Live Cluster Mode

### Demo Mode Identification

When no backend cluster is connected, the dashboard displays a persistent banner:

⚠ DEMO MODE – No Cluster Connected


This banner appears on all pages.

---

### Demo Mode Behavior

In Demo Mode:

- All UI elements are fully interactive
- Node states, RF data, aircraft, and metrics are simulated
- Configuration changes are tracked but not applied
- Destructive actions display confirmations but do not execute
- Logs and alerts are generated synthetically

Demo Mode exists to:
- Train operators
- Validate UI and workflows
- Document system behavior
- Prevent accidental damage during development

---

### Live Cluster Mode Behavior

When connected to a real cluster:

- Node states reflect actual hardware
- RF and SDR controls affect physical devices
- Network and firewall changes take effect immediately
- Destructive actions permanently alter the system

Operators should **always confirm Demo Mode status** before performing critical actions.

---

## 4. Global Interface & Navigation

### Sidebar Navigation

A collapsible sidebar provides access to all major functional areas:

- **Dashboard** – Cluster overview and quick actions
- **Mesh Network** – Node topology and connectivity
- **ISR / Airspace** – Aircraft tracking and SIGINT
- **RF Communications** – SDR tuning and spectrum monitoring
- **Performance** – CPU, memory, thermal, and power metrics
- **Settings** – Configuration, security, and policy controls

The sidebar is designed for rapid navigation without losing context.

---

### Header and Footer

- The header is dynamically injected and shared across pages
- It may display system status or global alerts
- The footer may contain build information, warnings, or cluster identifiers

These elements provide continuity across the dashboard.

---

## 5. Dashboard Overview (Command & Control)

### Purpose

The **Overview page** is the primary operational console. It answers:

> “Is the cluster healthy, and what needs attention right now?”

Operators should return to this page frequently.

---

### Node Status Panel

Each cluster node is displayed as a **status card** showing:

- Node name and role
- Online or offline state
- Assigned IP address
- Health coloration (green, warning, critical)

This allows rapid identification of failures or degraded nodes.

---

### Node Actions Modal

Clicking a node opens a modal containing:

- Uptime
- Temperature
- Memory utilization
- Installed services
- Service states (running, idle, missing)

Available actions:
- **Reboot Node**
- **Run Diagnostics**

In live mode, these actions directly affect the selected node.

---

### Quick Actions Panel

This panel contains **cluster-wide controls**:

#### Validate Config
Checks configuration files for consistency and errors before deployment or updates.

#### Health Check
Runs a system-wide diagnostic covering:
- CPU and memory health
- Storage availability
- Service responsiveness
- Sensor and SDR availability

#### Performance
Navigates to the Performance page for detailed metrics.

#### Emergency Wipe
Initiates secure destruction of locally stored data. This action is irreversible.

#### Reboot All
Reboots every node in the cluster simultaneously.

All disruptive actions require explicit confirmation.

---

### Activity Log

A rolling log displays:
- Operator actions
- System events
- Configuration changes
- Warnings and errors

Logs are timestamped and ordered newest-first.

---

## 6. Mesh Network & Node Topology

### Purpose

The **Mesh page** visualizes how nodes are connected, trusted, and routing traffic.

It is used to:
- Diagnose connectivity issues
- Verify mesh formation
- Observe failover behavior

---

### Topology Visualization

The topology map displays:
- Nodes as distinct entities
- Links between nodes
- Backhaul preference paths
- Link health indicators

A hover-to-unlock overlay prevents accidental interaction.

---

### Node List & Trust State

Each node entry shows:
- Role (Boot, ISR, RF, Mesh)
- Heartbeat status
- Latency indicators
- Trust model (known, provisional, isolated)

Operators can identify misbehaving or compromised nodes quickly.

---

## 7. ISR / Airspace & SIGINT Operations

### Purpose

This page combines **airspace awareness** and **signal intelligence** into a single operational view.

---

### Aircraft Tracking (ADS-B / UAT)

#### What It Shows
- Aircraft positions on a live map
- Callsign, ICAO, altitude, speed, heading
- Aggregate statistics (count, message rate, altitude max)

#### How to Use It
- Use filters to reduce clutter
- Click aircraft to view details
- Observe bearing lines relative to ISR nodes

In live mode, this data comes from ADS-B/UAT receivers.

---

### Signal Monitoring & SDR Control

Operators can:
- Tune frequencies manually
- Select modulation modes (FM, AM, SSB, CW)
- Adjust gain and step size
- Use preset frequencies

A simulated spectrum and waterfall visualize signal activity.

---

### Signal Triangulation

When multiple ISR nodes are available:
- Bearings are displayed per node
- RSSI values are shown
- An estimated emitter location is plotted
- Confidence and error radius are visualized

This demonstrates multi-node direction finding.

---

## 8. RF Communications & SDR Control

### Purpose

The RF page focuses on **communications and monitoring**, not ISR fusion.

---

### Receiver Controls

Operators can:
- Set center frequency
- Adjust gain
- Select modulation
- Switch receivers

Controls are designed for quick tuning without menu depth.

---

### Spectrum & Waterfall

Visual tools include:
- Real-time spectrum view
- Scrolling waterfall
- Signal strength indicators
- Noise floor estimates

These help identify active channels and interference.

---

### Intended Live Use

- Monitoring tactical VHF/UHF channels
- Observing RF congestion
- Supporting direction finding workflows

---

## 9. Performance & Resource Monitoring

### Purpose

This page answers:
> “Are we approaching thermal, power, or compute limits?”

---

### Metrics Displayed

- CPU utilization per node
- Memory usage
- Storage consumption
- Thermal readings
- Power and throttling states

---

### Operator Use

Operators use this page to:
- Detect overheating
- Identify runaway processes
- Decide when to shed load
- Validate deployment profiles

---

## 10. Settings & Configuration Management

### Purpose

The **Settings page** defines **how the cluster behaves**, not just what it does.

Changes are tracked and require explicit application.

---

### Deployment Profile

Defines:
- Deployment mode (Training, Operational, Stealth)
- Power environment
- Thermal assumptions
- Operator density

These settings influence system behavior globally.

---

### Power & Hardware Policy

Controls:
- Power budget enforcement
- Thermal throttling behavior
- Automatic reboot policies
- Sacrificial node shutdown rules

---

### Failover & Autonomy

Defines:
- Autonomy level
- Restart conditions
- Node promotion rules
- Automatic isolation behavior

---

### Network & Mesh Behavior

Controls:
- Backhaul preference order
- Discovery visibility
- Trust model enforcement
- Heartbeat validation

---

### Security & Access Control

Includes:
- Authentication mode
- Session timeout
- Lockdown mode
- USB interface disabling

---

### Firewall Configuration (UFW)

Operators can:
- Enable or disable host firewall
- Set default inbound/outbound policy
- Add, edit, and remove rules
- Review pending changes
- Apply changes with acknowledgment

Misconfiguration warnings are explicit.

---

### Data Handling & OPSEC

Controls:
- Data classification
- Retention policy
- Encryption at rest
- Export permissions

---

### Secure Data Destruction

Includes:
- Automatic purge timers
- Manual secure purge
- Emergency wipe

All actions require acknowledgment and confirmation.

---

## 11. Security, OPSEC, and Destructive Actions

The dashboard assumes **compromise is possible**.

As a result:
- Destructive actions are deliberate
- Warnings are explicit
- Confirmation is mandatory
- Logs are maintained

Operators are expected to understand the consequences before proceeding.

---

## 12. Alerts, Logs, and Audit Trails

The system logs:
- Operator actions
- Configuration changes
- Firewall modifications
- Destructive operations

Forensic bundles can be exported for review.

---

## 13. Recommended Operator Workflows

- Start every session on the **Overview page**
- Check node status before making changes
- Validate config before applying updates
- Use Performance to confirm thermal safety
- Treat Emergency Wipe as last-resort only

---

## 14. System Limitations & Future Expansion

Planned expansions include:
- Live SDR integration
- Persistent storage backends
- Alert routing to external systems
- Role-based access control
- Automated mission profiles

## 14 Quick Start (Local Machine)

### Prerequisites
- Python 3.9 or higher
- Your laptop (any OS: Windows, Mac, Linux)
- Internet connection (optional - works offline with demo mode)

### Launch Dashboard

```bash
cd ~/Portable-Pi-5-Cluster-Server/web
./run.sh
```

That's it! The dashboard will:
1. Create a virtual environment
2. Install Flask and dependencies
3. Start the web server
4. Print the access URL

### Access Dashboard

Open your browser and go to:
```
http://127.0.0.1:5000
```

Or from your laptop:
```
http://localhost:5000
```

---

### Demo Mode (Default - No Cluster Needed)
```bash
./run.sh
```
Uses realistic simulated data. Perfect for:
- Testing the dashboard locally
- Learning the interface
- Testing without hardware

### Production Mode (Connected to Cluster)
```bash
cd web
export DEMO_MODE=False
export HOST=0.0.0.0
./run.sh
```
Connects to actual cluster nodes via SSH
- Real metrics and data
- Actual control operations
- Full cluster management

---

## 15 Connection to Real Cluster

When you're ready to connect to your actual cluster:

### 1. Copy Dashboard to Boot Node
```bash
scp -r ~/Portable-Pi-5-Cluster-Server/web pi@192.168.1.10:/home/pi/
```

### 2. On Boot Node, Start Dashboard
```bash
cd /home/pi/web
export DEMO_MODE=False
export HOST=0.0.0.0
./run.sh
```

### 3. Access from Your Laptop
```
http://192.168.1.10:5000
```

Or setup SSH tunnel:
```bash
ssh -L 5000:127.0.0.1:5000 pi@192.168.1.10
# Then access: http://127.0.0.1:5000
```

---

## 16 API Endpoints

The dashboard communicates with the cluster via REST API:

### Status Endpoints
- `GET /api/cluster/status` - Cluster overview
- `GET /api/nodes/list` - All nodes
- `GET /api/nodes/<id>/status` - Specific node
- `GET /api/nodes/<id>/health` - Health metrics

### Control Endpoints
- `POST /api/deploy/boot-node` - Deploy boot
- `POST /api/deploy/cluster` - Deploy all
- `POST /api/nodes/<id>/reboot` - Reboot node
- `POST /api/nodes/<id>/shutdown` - Shutdown node
- `POST /api/cluster/reboot-all` - Reboot all
- `POST /api/cluster/update-all` - Update all

### Backup Endpoints
- `GET /api/backup/list` - Available backups
- `POST /api/backup/create` - Create backup
- `POST /api/backup/restore/<id>` - Restore
- `POST /api/backup/verify/<id>` - Verify

### Analysis Endpoints
- `GET /api/performance/summary` - Cluster metrics
- `GET /api/performance/<id>` - Node metrics
- `POST /api/health-check` - Run health check
- `POST /api/validate-config` - Validate config

---

## 17 Keyboard Shortcuts

- `Ctrl+R` - Refresh page
- `Ctrl+K` - Quick access menu (future)
- `Ctrl+B` - Go to backup page (future)

---

## 18 Security Notes

### Local Use (Demo Mode)
- No authentication needed
- No external access
- Safe for testing

### Production Use
Consider adding:
1. **Basic Authentication**
   ```python
   from flask_httpauth import HTTPBasicAuth
   auth = HTTPBasicAuth()
   ```

2. **HTTPS/SSL**
   ```bash
   python3 app.py --cert=path/to/cert.pem --key=path/to/key.pem
   ```

3. **API Token**
   - Require API token for all POST requests
   - Generate token on login

4. **Firewall Rules**
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 5000
   ```

---

## 19 Troubleshooting

### Dashboard Won't Start
```bash
# Check Python
python3 --version

# Check port is available
lsof -i :5000

# Try different port
PORT=8000 ./run.sh
```

### Can't Connect to Cluster
```bash
# Verify network
ping 192.168.1.10

# Check SSH access
ssh pi@192.168.1.10 'uptime'

# Enable demo mode for testing
export DEMO_MODE=True
./run.sh
```

### Slow Performance
```bash
# Reduce auto-refresh interval in Settings
# Disable animations in browser DevTools
# Use a different browser
```

---

## 20 Advanced Usage

### Custom Port
```bash
PORT=8000 ./run.sh
```

### Custom Host
```bash
HOST=192.168.1.20 ./run.sh
```

### Run in Background
```bash
nohup ./run.sh > dashboard.log 2>&1 &
```

### Docker Container (Optional)
```bash
docker run -p 5000:5000 -e DEMO_MODE=False \
  -v ~/.ssh:/root/.ssh:ro \
  cluster-dashboard:latest
```

---

## 21 Files

```
web/
├── app.py                 # Flask application (main)
├── requirements.txt       # Python dependencies
├── run.sh                 # Launcher script
│
├── static/                # CSS & JS
|   ├── css
|   |   ├── login.css
|   |   └── style.css
|   |
|   ├── icons
|   └── js
|       └──main.js
|
└── templates/             # HTML pages
    ├── components         # Reusable Page Components
    |    ├── footer.html
    |    ├── header.html
    |    └── sidebar.html
    |
    ├── index.html
    ├── login.html
    ├── isr.html
    ├── mesh.html
    ├── vhf.html
    ├── backup.html
    └── settings.html

```

---

## 🔧 Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `DEBUG` | `True` | Enable debug mode |
| `DEMO_MODE` | `True` | Use simulated data |
| `HOST` | `127.0.0.1` | Bind address |
| `PORT` | `5000` | Port number |
| `SECRET_KEY` | `tactical-ops-...` | Session secret |

---

## 📞 Support

For issues or questions:
1. Check [DASHBOARD-API.md](DASHBOARD-API.md) for API details
2. Review logs: `tail -f dashboard.log`
3. Check GitHub issues
4. See [docs/troubleshooting.md](../docs/troubleshooting.md)

---

## 🎯 Next Steps

1. **Start Dashboard**
   ```bash
   ./run.sh
   ```

2. **Explore Interface**
   - Click through all pages
   - Test demo buttons
   - Understand metrics

3. **Deploy to Cluster**
   - When ready, copy to boot node
   - Disable demo mode
   - Connect to real cluster

4. **Customize**
   - Edit CSS for your branding
   - Add custom endpoints
   - Integrate with monitoring tools

---

**Dashboard Version:** 0.2.0  
**Documention Last Updated:** December 31, 2025 
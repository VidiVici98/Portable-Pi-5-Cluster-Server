# Cluster Dashboard - Quick Start Guide

**Tactical Operations Web Interface**  
Complete monitoring and control for your 4-node cluster

---

## 🚀 Quick Start (Local Machine)

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

## 📋 Features

### Dashboard Page
Real-time cluster operational status
- Node status indicators
- Quick action buttons
- Activity log
- Deployment status

### Monitor Page
Detailed node health metrics
- CPU usage and load
- Memory utilization
- Disk space
- Temperature
- Uptime
- Auto-refresh every 10 seconds

### Control Page
Cluster operations and management
- Deploy boot node
- Deploy full cluster
- Update all nodes
- Reboot all nodes
- Individual node control (reboot, shutdown)

### Performance Page
Real-time performance analysis
- Cluster-wide metrics
- Per-node performance
- CPU, memory, disk, network
- Thermal monitoring

### Backup Page
Disaster recovery management
- Create backup
- View available backups
- Restore from backup
- Verify backup integrity
- Backup statistics

### Settings Page
Configuration and information
- Dashboard preferences
- Cluster configuration
- System information
- Documentation links

---

## 🎨 Tactical Styling

The dashboard features military-inspired design:
- **Lime green CRT monitor aesthetic** (#00FF00)
- **Grid background pattern** - reminiscent of scope displays
- **Pulsing status indicators** - online/offline/warning
- **Monospace fonts** - tactical operations feel
- **High contrast** - for clarity in any lighting
- **Glowing effects** - futuristic tactical style

---

## 🔄 Modes

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

## 🔌 Connection to Real Cluster

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

## 📊 API Endpoints

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

## 🎮 Keyboard Shortcuts

- `Ctrl+R` - Refresh page
- `Ctrl+K` - Quick access menu (future)
- `Ctrl+B` - Go to backup page (future)

---

## 🔒 Security Notes

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

## 🐛 Troubleshooting

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

## 🚀 Advanced Usage

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

## 📋 Files

```
web/
├── app.py                 # Flask application (main)
├── requirements.txt       # Python dependencies
├── run.sh                # Launcher script
│
├── templates/            # HTML pages
│   ├── index.html        # Dashboard
│   ├── monitor.html      # Node monitoring
│   ├── control.html      # Cluster control
│   ├── performance.html   # Performance analysis
│   ├── backup.html       # Backup management
│   └── settings.html     # Settings
│
└── static/               # CSS and JS
    └── css/
        └── style.css     # Tactical styling
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

**Dashboard Version:** 1.0.0  
**Created:** December 25, 2025  
**Status:** Production Ready ✅

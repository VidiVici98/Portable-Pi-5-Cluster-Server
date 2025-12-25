# Tool Integration Guide

**Complete roadmap for integrating cluster tools and applications**

---

## Overview

The dashboard has built-in architecture for tool integration. Each node has specific tools that will be integrated as they're installed. The dashboard shows placeholder tools (marked "Coming Soon") and real tools as they become available.

---

## Node Purposes & Tool Categories

### Boot Node 🖥️
**Primary Role:** Core cluster infrastructure  
**Purpose:** NTP synchronization, NFS server, DHCP  
**IP:** 192.168.1.10

#### Tools to Integrate
- **System Management**
  - NTP Sync status and control
  - NFS server status and exports
  - DHCP server management
  
- **Monitoring**
  - Cluster health overview
  - Network connectivity monitor
  - Resource aggregation

- **Administration**
  - Shutdown all nodes
  - Reboot all nodes
  - Update all nodes

**Integration Points:**
- SSH connection to boot node for command execution
- Read system status files: `/etc/ntp.conf`, `/etc/exports`
- Monitor daemons: `ntpd`, `nfs-server`, `dnsmasq`

---

### ISR Node (Intelligence, Surveillance, Reconnaissance) 📡
**Primary Role:** RF monitoring and signal analysis  
**Purpose:** ADSB/UAT monitoring, aircraft tracking  
**IP:** 192.168.1.20

#### Tools to Integrate

**ADSB Reception**
- **dump1090** - ADS-B receiver and transponder
  - Live aircraft tracking
  - Signal strength monitoring
  - JSON output parsing
  - Integration: Web service on port 8080 (typical)
  
- **readsb** - Modern ADS-B receiver
  - Drop-in replacement for dump1090
  - Better performance and features
  - Same API interface

- **ADSB Track Display**
  - Map view of aircraft
  - Historical tracking
  - Database queries

**UAT Reception**
- **dump978** - UAT (UAV) receiver for aviation data
  - 978 MHz UAV uplink reception
  - Real-time data streaming
  - Status monitoring
  
- **UAT Monitor**
  - Live UAT message display
  - Statistics and analytics
  - Alert configuration

**Analysis & Integration**
- **Flight Track History**
  - Database of tracked aircraft
  - Historical queries
  - Export capabilities
  
- **Aircraft Database**
  - Aircraft registration lookup
  - Callsign mapping
  - Performance data

- **Alert System** [PLACEHOLDER]
  - Custom alert triggers
  - Notification system
  - Integration with external services

**Custom Tools** [PLACEHOLDER - Ready for Integration]
- Custom ADSB receiver application
- Custom UAT decoder
- Real-time processing pipeline

**Integration Architecture:**
```
ISR Node Services:
├── dump1090 (port 8080)
│   └── JSON output → Dashboard API
├── dump978 (port 30978)
│   └── Raw UAT data → Dashboard parser
├── Alert System
│   └── Rule engine → Notifications
└── Database
    └── SQLite/PostgreSQL queries
```

**Dashboard Integration Steps:**
1. Query `http://192.168.1.20:8080/data/aircraft.json` for live aircraft
2. Parse ICAO hex codes and aircraft positions
3. Display on map component
4. Monitor statistics (# tracked, messages/sec, signal quality)
5. Alert on custom triggers

**Example Tool Control:**
```javascript
// Start dump1090
POST /api/nodes/isr/tool/dump1090?action=start
// Get aircraft data
GET /api/nodes/isr/tool/dump1090?action=status
// Get current tracks
GET /api/nodes/isr/adsb/aircraft
```

---

### Mesh Node 🔗
**Primary Role:** Network communication & mesh routing  
**Purpose:** Inter-node communication, redundancy, network optimization  
**IP:** 192.168.1.30

#### Tools to Integrate

**Mesh Networking**
- **Batman-adv Status**
  - Mesh originator status
  - Topology visualization
  - Link quality metrics
  
- **Mesh Route Viewer**
  - Network topology graph
  - Hop-by-hop routing
  - Route optimization

- **Network Topology**
  - Real-time node discovery
  - Link quality analysis
  - Neighbor detection

**Routing Optimization**
- **OLSR Monitor** - Optimized Link State Routing
  - Neighbor discovery
  - Route optimization
  - Performance metrics
  
- **Route Optimization**
  - Analyze and improve routes
  - Link quality tuning
  - Bandwidth optimization

- **Backup Routes**
  - Redundant path detection
  - Failover mechanism
  - Link health monitoring

**Custom Tools** [PLACEHOLDER - Ready for Integration]
- Custom mesh protocol implementation
- Network diagnostic tools
- Advanced routing algorithms

**Integration Architecture:**
```
Mesh Node Services:
├── Batman-adv (kernel module)
│   └── sysfs interface → Dashboard polling
├── OLSR daemon
│   └── Socket interface → Dashboard API
├── Network Monitor
│   └── tcpdump/netstat → Analytics
└── Custom Mesh Protocol
    └── Message queue → Dashboard
```

**Dashboard Integration Steps:**
1. Query `batctl n` for neighbor information
2. Parse OLSR topology data
3. Build network graph visualization
4. Monitor link quality metrics
5. Alert on topology changes
6. Provide manual route optimization controls

**Example Tool Control:**
```javascript
// Get mesh topology
GET /api/nodes/mesh/topology
// Get link quality
GET /api/nodes/mesh/link-quality
// Optimize routes
POST /api/nodes/mesh/optimize-routes
```

---

### VHF Node 📻
**Primary Role:** Software Defined Radio (SDR) operations  
**Purpose:** VHF/UHF communications, signal monitoring, radio control  
**IP:** 192.168.1.40

#### Tools to Integrate

**SDR Control**
- **GQRX Control**
  - Frequency tuning
  - Mode selection (AM, FM, SSB, etc.)
  - Recording control
  - Real-time audio streaming
  
- **RTL-SDR Tools**
  - RTL-SDR device control
  - Frequency scanning
  - Signal strength monitoring
  - Gain/attenuation control

- **Frequency Scanner**
  - Automated frequency sweeping
  - Signal detection and logging
  - Alert on active frequencies

**VHF Specific**
- **VHF Receiver**
  - VHF band tuning (30-300 MHz typical)
  - Signal demodulation
  - Audio output

- **VHF Transmitter** [PLACEHOLDER]
  - Transmit capability control
  - Modulation selection
  - Power level control

- **Squelch Monitor**
  - Noise floor detection
  - Signal activation detection
  - Mute control

**Analysis**
- **Signal Strength**
  - Real-time S-meter display
  - Historical trending
  - Propagation analysis
  
- **Modulation Analyzer**
  - Modulation identification
  - Audio spectrum analysis
  - Constellation diagram display

- **Recording**
  - Raw IQ recording
  - Audio recording
  - Playback capability

**Custom Tools** [PLACEHOLDER - Ready for Integration]
- Custom SDR application
- Custom VHF tools
- Real-time signal processing

**Integration Architecture:**
```
VHF Node Services:
├── GQRX (REST API)
│   ├── Frequency control
│   ├── Mode control
│   └── Audio streaming
├── RTL-SDR library
│   ├── Device control
│   ├── Frequency tuning
│   └── Gain control
├── Signal Monitor
│   └── Real-time metrics
└── Custom Tools
    └── Plugin architecture
```

**Dashboard Integration Steps:**
1. Connect to GQRX via REST API (port typically 7356)
2. Provide frequency/mode controls
3. Monitor signal strength in real-time
4. Display audio spectrogram
5. Log received data
6. Provide recording controls

**Example Tool Control:**
```javascript
// Tune frequency
POST /api/nodes/vhf/tool/gqrx?action=tune&frequency=146.52
// Set modulation
POST /api/nodes/vhf/tool/gqrx?action=mode&mode=FM
// Get signal strength
GET /api/nodes/vhf/signal-strength
// Start recording
POST /api/nodes/vhf/record?duration=60
```

---

## Generic Tool Integration Pattern

### API Endpoint Pattern

For any tool on any node:

```
GET  /api/nodes/<node_id>/tool/<tool_name>              - Get tool status
POST /api/nodes/<node_id>/tool/<tool_name>              - Execute action
     ?action=<action> - Specific action (start, stop, status, etc.)
     &param=<value> - Additional parameters
```

### Implementation Steps

1. **Backend (Flask)**
   - Add tool detection to `ClusterAPI` class
   - Create endpoint handler for tool actions
   - Parse tool output and return JSON
   - Error handling for missing/unavailable tools

2. **Frontend (HTML/JS)**
   - Create tool control UI component
   - Add fetch calls to tool endpoints
   - Display real-time tool status
   - Provide user controls for tool actions

3. **Configuration**
   - Define tool paths in `/home/pi/cluster-config/tools.conf`
   - Set up authentication if needed
   - Configure tool parameters
   - Enable/disable tools as needed

### Example Integration: dump1090 on ISR Node

**Backend - app.py:**
```python
@app.route('/api/nodes/isr/adsb/aircraft')
def api_isr_adsb_aircraft():
    """Get list of currently tracked aircraft"""
    if DEMO_MODE:
        return jsonify({
            'aircraft': [
                {'icao': 'A12345', 'callsign': 'AAL123', 'altitude': 35000, 'speed': 450},
                {'icao': 'B23456', 'callsign': 'UAL456', 'altitude': 38000, 'speed': 475},
            ]
        })
    
    try:
        # Query dump1090 JSON API
        result = subprocess.run(
            ['curl', '-s', 'http://192.168.1.20:8080/data/aircraft.json'],
            capture_output=True,
            timeout=5
        )
        data = json.loads(result.stdout)
        return jsonify(data)
    except:
        return jsonify({'error': 'ADSB data unavailable'}), 503
```

**Frontend - dashboard.js:**
```javascript
async function loadADSBData() {
    const response = await fetch('/api/nodes/isr/adsb/aircraft');
    const data = await response.json();
    displayAircraft(data.aircraft);
}

function displayAircraft(aircraft) {
    // Add each aircraft to map
    aircraft.forEach(a => {
        addMarkerToMap(a.callsign, a.latitude, a.longitude, a.altitude);
    });
}
```

---

## Tool Installation Checklist

When installing a new tool on a node:

- [ ] Install application on node
- [ ] Verify it runs standalone
- [ ] Test via SSH from boot node
- [ ] Determine API/interface method
- [ ] Add detection code to backend
- [ ] Create API endpoints
- [ ] Add UI components to dashboard
- [ ] Test in demo mode
- [ ] Test with real tool
- [ ] Document tool in DASHBOARD-GUIDE.md
- [ ] Create tool-specific quick start

---

## Demo Mode Data

Tools return realistic demo data when `DEMO_MODE=True`:

- ADSB: Simulated aircraft with random positions/speeds
- UAT: Simulated UAT messages
- Mesh: Simulated topology with 4 nodes
- VHF: Simulated signal strength and frequency scans

This allows full dashboard testing without actual hardware.

---

## Tool Status Dashboard

The **Tools page** (`/tools`) displays:

- ✅ **Installed Tools** - Confirmed present on node
- ❌ **Not Installed** - Missing or disabled
- 🔄 **Running** - Currently active
- ⏸️ **Idle** - Installed but not running
- 🚀 **Coming Soon** - Placeholders for future tools

---

## Security Considerations

When integrating tools:

1. **Authentication**
   - Verify SSH key setup for automation
   - Use service accounts with limited permissions
   - Implement dashboard authentication for production

2. **Data Protection**
   - Secure API endpoints (HTTPS recommended)
   - Validate all user inputs
   - Log tool actions for audit

3. **Resource Limits**
   - Monitor tool resource usage
   - Implement timeouts (30s default)
   - Prevent runaway processes

4. **Error Handling**
   - Gracefully handle tool failures
   - Provide meaningful error messages
   - Alert on critical errors

---

## Next Steps

1. **Install ADSB Tools** (ISR Node Priority)
   - `sudo apt install dump1090-fa`
   - Configure for local network access
   - Integrate aircraft display to dashboard

2. **Install Mesh Tools** (Mesh Node Priority)
   - Set up batman-adv kernel module
   - Configure OLSR daemon
   - Integrate topology visualization

3. **Install SDR Tools** (VHF Node Priority)
   - Install GQRX and RTL-SDR libraries
   - Configure hardware access
   - Integrate frequency tuning controls

4. **Create Tool Management UI**
   - Tool start/stop controls
   - Parameter configuration
   - Real-time status monitoring

5. **Build Advanced Dashboards**
   - Aircraft tracking map
   - Network topology visualization
   - Spectrum analyzer display
   - Log viewer

---

## Resources

- **ADSB:** https://github.com/flightaware/dump1090
- **SDR:** https://osmocom.org/projects/rtl-sdr/
- **Mesh:** https://www.open-mesh.org/projects/open-mesh/wiki
- **OLSR:** http://www.olsr.org/

---

**Version:** 1.0  
**Last Updated:** December 25, 2025  
**Status:** Ready for Integration

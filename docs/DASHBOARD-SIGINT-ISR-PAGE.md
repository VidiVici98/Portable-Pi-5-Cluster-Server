# SIGINT / ISR Dashboard  
**Airspace & RF Monitoring Page (Demo Mode)**

## Overview

The **SIGINT / ISR** page provides a unified interface for airspace surveillance, RF spectrum monitoring, and signal origin estimation. In its current **demo configuration**, all components are fully interactive from a UI/UX perspective but rely on simulated or placeholder data rather than live backend integrations.

This page is intended to represent the operational end-state for intelligence, surveillance, and reconnaissance workflows once connected to cluster nodes and real signal sources.

---

## Demo Mode Behavior

When the system is running without a connected cluster, a prominent banner is displayed:

> ⚠ **DEMO MODE – No Cluster Connected**

In this state:
- API calls return mock or randomized data
- Controls are functional but do not affect real hardware
- Visualizations update on timers to simulate live conditions

---

## Page Layout & Major Sections

### 1. ADS-B / UAT Aircraft Tracking

**Purpose:**  
Provide real-time situational awareness of nearby air traffic using ADS-B and UAT data sources.

#### Components
- **Statistics Panel**
  - Aircraft Tracked
  - Messages per Second
  - Maximum Observed Altitude
  - Average Aircraft Speed

- **Live Aircraft Map**
  - Dark-themed Leaflet map
  - Rotating aircraft icons based on heading
  - Auto-framing to include aircraft and ISR nodes
  - Bearing rays projected from ISR nodes toward aircraft headings

- **Tracking Controls**
  - Aircraft type filter (commercial, military, general aviation, cargo)
  - Minimum altitude filter
  - Adjustable auto-refresh interval
  - Start/Stop tracking toggle

- **Aircraft List & Details**
  - Scrollable list of tracked aircraft
  - Click-to-select interaction
  - Detailed readout including:
    - Callsign
    - ICAO address
    - Altitude
    - Speed
    - Heading
    - Coordinates

**Demo Notes**
- Aircraft positions, speeds, and headings are simulated
- Message rates and statistics are randomized
- Filters are UI placeholders and do not yet affect datasets

---

### 2. VHF / SDR Frequency Control

**Purpose:**  
Provide operator control and visibility into RF monitoring and SDR-based receiver systems.

#### Receiver Control Panel
- Frequency display (MHz)
- Manual frequency entry
- Fine-tuning buttons (MHz and kHz steps)
- Modulation mode selection:
  - FM
  - AM
  - SSB
  - CW
- Preset frequency buttons (e.g., Emergency, GMRS, 2m Simplex)

#### Signal Analysis Panel
- Simulated S-meter
- Live spectrum waterfall display
- Signal statistics:
  - Signal strength
  - Noise floor
  - SNR
  - Modulation
  - Bandwidth

#### Receiver Status Panel
- Device and tuner identification
- Gain and sample rate
- Active/inactive state indicator
- Gain adjustment slider

**Demo Notes**
- Spectrum and waterfall visuals are procedurally generated
- Gain and frequency changes update the UI only
- No SDR hardware is accessed in demo mode

---

### 3. Signal Triangulation & Origin Estimation

**Purpose:**  
Demonstrate direction-finding and emitter location estimation using multi-node bearings.

#### Bearing & Compass Visualization
- Animated compass display
- Primary bearing readout
- Confidence estimate
- Signal classification

#### Receiver Bearings Table
- Per-node bearing angles
- RSSI values
- Lock/degraded status indicators

#### Triangulation Map
- Estimated signal origin marker
- Error radius visualization
- Solution quality indicator
- Auto-framing to include all participating nodes

**Demo Notes**
- Bearings and RSSI values are simulated
- Triangulation math is simplified and illustrative
- Marker position updates periodically to simulate refinement

---

## Interaction Safeguards

To prevent accidental map manipulation:
- All maps use a **hover-to-unlock guard**
- Brief overlays block input unless intentionally engaged

This pattern is consistent across ADS-B and triangulation maps.

---

## Navigation & Integration

- Sidebar navigation and global header are shared with the rest of the dashboard
- Footer content is dynamically injected
- This page is designed to integrate with:
  - ISR cluster nodes
  - SDR hardware
  - ADS-B/UAT receivers
  - Future alerting and recording subsystems

---

## Intended Future Backend Integrations

Once wired to live systems, this page will support:
- Real-time ADS-B ingestion from ISR nodes
- Live SDR tuning and demodulation
- Direction-of-arrival processing
- Multi-node triangulation with confidence modeling
- Historical signal capture and replay

---

## Summary

The **SIGINT / ISR Dashboard** serves as the intelligence-gathering and analysis hub of the cluster server platform. In demo mode, it provides a realistic and operator-ready interface that mirrors final functionality, ensuring that workflows, layouts, and controls are validated before backend activation.

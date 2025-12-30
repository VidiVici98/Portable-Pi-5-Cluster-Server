# Mesh Network Dashboard  
**Distributed Node Awareness & Field Asset Control (Demo Mode)**

## Overview

The **Mesh Network** page provides real-time situational awareness and command interaction for a distributed mesh of field assets. It combines geospatial visualization, node health monitoring, communications logging, and asset-level control into a single operational view.

In the current **demo configuration**, all nodes, links, alerts, and actions are simulated. The UI reflects the intended end-state behavior once live mesh radios, TAK feeds, and cluster services are integrated.

---

## Demo Mode Indicator

When operating without a live cluster, the following banner is displayed persistently:

> ⚠ **DEMO MODE – No Cluster Connected**

In this mode:
- Node status, positions, and events are simulated
- Commands and alerts are non-destructive
- All actions are logged locally for UX validation only

---

## Page Layout

The page is divided into three primary regions:

1. **Mesh Network Overview (Stats)**
2. **Tactical Map & Field Assets Panel**
3. **Side Control & Communications Panel**

---

## Mesh Network Overview (Stats Panel)

### Purpose

Provides an at-a-glance health summary of the mesh.

### Displayed Metrics

| Metric | Description |
|------|-------------|
| Total Nodes | Number of known mesh assets |
| Online | Nodes reporting normal status |
| Degraded | Nodes with reduced link quality |
| Offline | Nodes currently unreachable |

Values update dynamically as simulated network events occur.

---

## Tactical Map

### Description

A dark-themed, Leaflet-based geospatial map representing the operational area and all mesh-related entities.

### Displayed Elements

- **Mesh Nodes**
  - Circle markers for each asset
  - Popup with callsign, UID, and role

- **Mesh Links**
  - Dashed lines representing peer-to-peer connectivity

- **Sensor Cones**
  - Directional polygons indicating sensor or antenna coverage

- **C2 Overlays**
  - Radius-based command-and-control influence areas

- **Trigger Zones**
  - Localized alert or automation regions

- **TAK Entities**
  - Friendly forces injected from TAK-like feeds

- **Hostile Entities**
  - Red markers representing adversarial or unknown units

- **Geofences**
  - Circular restricted or monitored areas

### Map Interaction Guard

To prevent accidental map movement:
- A hover-activated overlay temporarily blocks interaction
- Intentional interaction requires sustained hover

This behavior is consistent with other map-based pages in the platform.

---

## Field Assets Panel

### Description

A scrollable list of all mesh nodes displayed alongside the map.

Each **Node Card** includes:
- Callsign
- Status indicator (OK / DEGRADED / DOWN)
- UID
- Operational role

### Interaction

Clicking a node card opens the **Asset Detail Modal**, providing deep visibility and control for that asset.

---

## Map Layers Control

### Purpose

Allow operators to toggle specific data layers on the map.

### Available Layers

- Mesh Nodes
- TAK Entities
- Mesh Links
- Geofences
- Sensor Cones
- Hostiles

Layer toggles are instantaneous and do not affect underlying data.

---

## Controls Panel

### Available Actions

| Action | Description |
|------|-------------|
| Simulate Network Event | Randomizes node health states |
| Broadcast Alert | Issues a simulated alert to all nodes |
| Create Broadcast Message | Opens the broadcast composition modal |

All actions generate entries in the Comms Log.

---

## Communications Log

### Description

A live, chronological log of network and operator activity.

### Logged Events Include

- Network state updates
- Broadcast alerts
- Command execution acknowledgements
- Operator-initiated actions

Entries are prepended with timestamps and displayed in reverse chronological order.

---

## Broadcast Message Modal

### Purpose

Compose and send a message to multiple mesh nodes.

### Features

- Multi-select target list (All Nodes or Teams A–F)
- Free-text message body
- Send / Cancel actions

### Demo Behavior

Messages are logged and acknowledged visually but are not transmitted to real assets.

---

## Asset Detail Modal

### Purpose

Provide a detailed operational view and control surface for a single mesh asset.

### Displayed Information

**Header**
- Callsign
- UID
- Role
- Status badge (OK / DEGRADED / DOWN)

**Connectivity & Health**
- Link quality visualization
- Last-heard timestamp
- Power level (placeholder)
- Position status

**Location**
- Latitude / Longitude
- Heading
- Center-on-map control

**Capabilities**
- Dynamically derived from asset role
- Examples:
  - Mesh Relay
  - Gateway
  - Sensor Cone
  - Broadcast Receiver

**Actions**
- Send Direct Message
- Assign Task
- Request Status Update
- Reboot Asset (destructive, confirmation required)

**Recent Activity**
- Collapsible log of asset-specific events

---

## Action Confirmation Modal

### Purpose

Prevent accidental execution of sensitive actions.

### Behavior

- Context-specific titles and warnings
- Optional text input for messages or tasking
- Explicit confirm / cancel flow
- Visual acknowledgment of command lifecycle:
  - Sent
  - Acknowledged
  - Completed

All confirmations are logged to the Comms Log.

---

## Node Actions Modal

### Purpose

Provide simplified node-level actions outside the full asset context.

### Available Actions

- Reboot Node
- Run Diagnostics

(Primarily a placeholder for future expansion.)

---

## Data & Simulation Model

### Demo Data Includes

- Six mesh nodes (Teams Alpha–Foxtrot)
- Friendly TAK entities
- Hostile entities
- Geofences and sensor cones

### Update Mechanics

- Network events randomize node health
- Map and stats refresh immediately
- Logs reflect all simulated changes

---

## Intended Future Integrations

When connected to live systems, this page will support:

- Real-time mesh radio telemetry
- TAK server ingestion
- True link-quality metrics
- Secure messaging and tasking
- Asset reboot and diagnostics via cluster orchestration
- Automated alerts and triggers

---

## Summary

The **Mesh Network Dashboard** serves as the operational backbone for distributed field assets. In demo mode, it functions as a high-fidelity simulation environment to validate workflows, visualization density, and command ergonomics before enabling live mesh control.

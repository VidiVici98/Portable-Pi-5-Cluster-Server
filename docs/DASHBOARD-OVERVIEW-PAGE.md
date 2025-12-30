# Dashboard Overview Page

## Purpose

The Dashboard Overview page provides a high-level, real-time operational view of the cluster. It is intended to be the primary landing page for operators, presenting node availability, cluster health actions, recent activity, and direct access to node-specific tools.

In the current demo configuration, all data and interactions are UI/UX representations only. Visual state changes, confirmations, and activity logging occur client-side without enforcing real backend actions.

## Demo Mode Indicator

When the application is running in demo mode, a persistent banner is displayed at the top of the page:

⚠ DEMO MODE – No Cluster Connected


This banner is controlled server-side via the demo_mode flag and is intended to clearly communicate that:

- No live cluster is connected

- Actions are non-destructive

- Data is simulated or placeholder only

## Page Layout

The page is composed of the following major regions:

- Quick Navigation Sidebar

- Header / Navbar

- Node Status Overview

- Cluster Quick Actions

- Activity Log

- Node Tool Modals (Hidden until invoked)

## Node Status Overview

### Description

The Node Status section displays a card for each node in the cluster, refreshed automatically every 5 seconds.

Each node card shows:

- Node name

- Online / offline indicator

- IP address

- Operational state (ONLINE / OFFLINE)

**Visual States**
| State | Indicator | Card Style |
|-------|-----------|------------|
| Online | 	Green dot | Success styling |
| Offline | Red dot | Critical styling |

The overall cluster health is also reflected by dynamically adjusting the page title color:

- All nodes online: Success color

- Any node offline: Warning color

### Interaction

Clicking on a node status card opens a Node Tool Modal for that specific node, providing deeper visibility into its services and tools.

## Node Tool Modals

### Purpose

Node Tool Modals provide a detailed, per-node view of:

- Available tools and services

- Service categories

- Installation and runtime status

- Node metadata (IP, purpose, uptime, memory, temperature)

These modals reuse the same tool-card layout used elsewhere in the application, ensuring consistency.

### Behavior

- Modals are dynamically generated on page load

- Tool status updates refresh every 15 seconds

- Clicking outside the modal or on the close icon dismisses it

## Demo Mode Behavior

In demo mode:

- Tool status indicators are visually updated

- No actual service control or execution occurs

- Status values may be static or simulated

## Cluster Quick Actions

The Quick Actions panel provides cluster-level operational controls.

**Available Actions**

| Action | Description |
|--------|-------------|
| Validate Config | Simulates a full configuration validation pass
| Health Check | Simulates a comprehensive cluster health scan
| Performance | Redirects to the Performance page
| Emergency Wipe | Simulates secure data destruction
| Reboot All | Simulates a full cluster reboot

### Safety Controls

Destructive actions (Emergency Wipe, Reboot All) require multiple confirmation dialogs to prevent accidental execution.

In demo mode, these confirmations still appear, but no backend operations are performed.

## Activity Log
### Description

The Activity Log displays a chronological list of operator actions and system events.

Each entry includes:

- Timestamp (local browser time)

- Human-readable action description

- Logged Events Include

- Dashboard initialization

- Configuration validation

- Health checks

- Reboot or wipe initiation

- Other simulated system events

Entries are inserted dynamically at the top of the log.

**Data Refresh & Automation**

| Component | Refresh Interval |
|-----------|------------------|
| Node status | Every 5 seconds |
| Tool status | Every 15 seconds |

These intervals are intended to mirror real-world operational dashboards and can be adjusted once live backend integration is complete.

## Backend Integration Status
Current State (Demo)

The following API endpoints are referenced but not yet enforced:

`/api/cluster/status`

`/api/cluster/node-summary`

`/api/validate-config`

`/api/health-check`

`/api/cluster/reboot-all`

`/api/cluster/destroy-data`

`/api/nodes/{nodeId}/tool-status`

Responses are assumed to be mocked, stubbed, or simulated.

## Future State (Live)

Once wired to the backend, this page will:

- Reflect real cluster state

- Execute actual orchestration actions

- Serve as the primary operational control surface

**Intended Audience**

- Cluster operators

- System administrators

- Tactical or field operators monitoring distributed nodes

## Summary

The Dashboard Overview page is designed to deliver immediate situational awareness and fast access to node-level operations. In demo mode, it serves as a high-fidelity UX prototype, allowing validation of workflows, visual hierarchy, and operator interaction patterns before live cluster control is enabled.
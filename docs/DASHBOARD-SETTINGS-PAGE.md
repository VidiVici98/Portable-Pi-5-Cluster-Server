# Cluster Settings Dashboard  
**Global Configuration, Security Policy, and Lifecycle Control (Demo Mode)**

## Overview

The **Cluster Settings** page is the authoritative control surface for configuring how the cluster behaves, protects itself, consumes resources, and responds to failure or compromise. Unlike operational dashboards, this page is **stateful and policy-driven**, with explicit safeguards against accidental or unsafe changes.

In **demo mode**, all settings changes are simulated, but the UI and workflows reflect real-world consequences, dependencies, and operator responsibilities.

---

## Demo Mode Indicator

When no live cluster is connected, a persistent banner is displayed:

> ⚠ **DEMO MODE – No Cluster Connected**

In this mode:
- No configuration changes are applied to real nodes
- Destructive actions are simulated only
- Firewall, purge, and reboot actions display confirmation flows without execution

---

## Pending Changes System

### Purpose

Prevent accidental configuration drift and ensure deliberate application of impactful changes.

### Behavior

- Any change to tracked settings increments a **pending change counter**
- A persistent **Pending Changes Banner** appears at the top of the page
- Operators may:
  - **Review** pending changes
  - **Apply** all pending changes in a single commit

This design enforces **batch application** and mirrors real cluster reconfiguration workflows.

---

## Settings Architecture

Settings are grouped into **functional policy domains**, each rendered as a discrete card section. This ensures clarity, minimizes cross-domain coupling, and supports future RBAC enforcement.

---

## Deployment Profile

### Purpose

Defines high-level assumptions about how the cluster is being used and operated.

### Configurable Parameters

- **Deployment Mode**
  - Training
  - Operational
  - Contested RF
  - Stealth / Low Emissions

- **Power Environment**
  - Stable Grid
  - Generator
  - DC Power

- **Ambient Temperature Expectation**
  - < 25°C
  - 25–40°C
  - 40–55°C

- **Operator Density**
  - Single Operator
  - Team / Shared Console

These settings inform downstream automation, throttling behavior, and alert sensitivity.

---

## Power & Hardware Policy

### Purpose

Control how the cluster manages energy constraints and thermal risk.

### Controls

- **Node Power Budget Enforcement**
  - Global power cap (per-node caps reserved for future expansion)

- **Thermal Throttling Policy**
  - Soft Throttle
  - Aggressive Throttle
  - Hard Shutdown

- **Automatic Reboot on Brownout**
- **Sacrificial Node Shutdown**
  - Allows non-critical nodes to be powered down to preserve core services

---

## Failover & Autonomy

### Purpose

Define how independently the cluster can recover from faults.

### Controls

- **Autonomy Level**
  - Manual Only
  - Assisted Recovery
  - Fully Autonomous

- **Service Restart Policy**
  - Never
  - On Crash
  - On Threshold Breach

- **Secondary Node Promotion**
- **Automatic Node Isolation**

These settings govern self-healing behavior and escalation thresholds.

---

## Network & Mesh Behavior

### Purpose

Control how the cluster participates in and exposes itself within mesh and backhaul networks.

### Controls

- **Preferred Backhaul Order**
  - PoE → Cluster Mesh → External Mesh
  - Cluster Mesh First

- **Discovery Visibility**
  - Silent
  - Passive
  - Active Beaconing

- **Mesh Trust Model**
  - Known Clusters Only
  - Known + Provisional
  - Opportunistic

- **Heartbeat Sanity Enforcement**

These settings directly influence detectability, trust boundaries, and resiliency.

---

## Security & Access Control

### Purpose

Define authentication posture and operator access constraints.

### Controls

- **Authentication Mode**
  - Local Credentials
  - Local + Keyfile

- **Session Timeout**
  - 15 / 30 / 60 minutes

- **Lockdown Mode**
- **Disable Physical USB Interfaces**

This section enforces both cyber and physical access discipline.

---

## Network Firewall (UFW)

### Purpose

Explicitly manage ingress and egress exposure at the host level.

### Global Firewall Controls

- Enable / Disable Host Firewall
- Default Inbound Policy (Allow / Deny)
- Default Outbound Policy (Allow / Deny)

---

### Firewall Rules Table

Each rule defines:
- Service name
- Port or range
- Protocol
- Source scope
- Action (ALLOW / DENY)
- Status (ACTIVE / PENDING)

#### Rule States

- **ACTIVE** — Applied and enforced
- **PENDING** — Staged but not yet committed

---

### Firewall Safeguards

- Dedicated **Apply Firewall Changes** workflow
- Explicit confirmation modal with:
  - Summary of pending changes
  - Connectivity loss warning
  - Mandatory acknowledgment checkbox

This design intentionally slows down high-risk operations.

---

## Data Handling & OPSEC

### Purpose

Control how sensitive data is stored, retained, and exported.

### Controls

- **Data Classification**
  - Unclassified
  - Sensitive
  - Restricted

- **Retention Policy**
  - 24 hours
  - 72 hours
  - Manual Only

- **Encrypt Data at Rest**
- **Allow Export to Removable Media**

These settings shape compliance posture and compromise blast radius.

---

## Secure Data Destruction (Danger Zone)

### Purpose

Provide irreversible data destruction options under controlled conditions.

### Controls

- **Automatic Data Purge Timer**
  - Disabled
  - 24 hours
  - 72 hours
  - 7 days

- **Require Operator Confirmation Before Auto-Purge**

### Manual Actions

- **Manual Secure Purge**
- **EMERGENCY WIPE**

---

### Destruction Confirmation Modal

Before execution:
- Explicit warning text
- Enumerated data categories to be destroyed
- Mandatory acknowledgment checkbox

In demo mode, actions are simulated but follow real confirmation discipline.

---

## Alerting & Notifications

### Purpose

Control alert volume, fatigue, and operator acknowledgment requirements.

### Controls

- Alert aggregation
- Repeated alert suppression
- Mandatory operator acknowledgment

---

## Maintenance & Update Policy

### Purpose

Define how and when the cluster updates itself.

### Controls

- **Update Channel**
  - Stable
  - Ops-Tested
  - Development

- **Auto-Update Policy**
  - Never
  - When Idle
  - Scheduled Window

- **Automatic Rollback**
- **Field Service Diagnostics Mode**

These settings balance stability against operational currency.

---

## Audit & Forensics

### Purpose

Ensure traceability, accountability, and post-event reconstruction.

### Controls

- Log all operator actions
- Track configuration changes
- **Time Synchronization Source**
  - Boot Node
  - External NTP

### Actions

- **Export Forensic Bundle**
  - Aggregates logs, configs, and artifacts for off-system analysis

---

## Summary

The **Cluster Settings Dashboard** is intentionally conservative, layered, and explicit. It treats configuration as a **controlled operation**, not a casual activity, and assumes that many changes may have irreversible or cascading consequences.

In demo mode, it functions as a policy validation and UX rehearsal environment. In live deployments, it becomes the cluster’s **governance and survivability control plane**.
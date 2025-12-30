# RF Communications Dashboard  
**Voice, Data, and RF Propagation Control (Demo Mode)**

## Overview

The **RF Communications** page is the platform’s primary interface for RF monitoring, frequency control, digital messaging, and propagation visualization. It is designed to unify **voice-spectrum awareness**, **non-voice digital transport**, and **RF effects modeling** into a single operator workflow.

In its current **demo configuration**, all RF behavior, signal metrics, transmissions, and coverage models are simulated. The UI reflects the intended operational end-state once connected to SDR hardware, radios, and cluster-managed RF nodes.

---

## Demo Mode Indicator

When no live cluster or RF backend is connected, a persistent banner is displayed:

> ⚠ **DEMO MODE – No Cluster Connected**

In this mode:
- SDR data is procedurally generated
- Transmissions are UI-gated but non-emissive
- Logs and recordings are simulated
- No RF energy is actually transmitted

---

## Page Layout

The page is divided into four major functional regions:

1. **VHF / SDR Frequency Control**
2. **Signal Analysis & Receiver Status**
3. **Digital Message & Data Transfer**
4. **RF Propagation Estimation & Visualization**

---

## VHF / SDR Frequency Control

### Purpose

Provide fine-grained operator control over RF receivers and (future) transceivers, supporting both monitoring and transmission workflows.

### Frequency Control Features

- **Primary Frequency Display**
  - Large, high-contrast MHz readout
- **Manual Frequency Entry**
  - Direct numeric input with validation
- **Fine-Tune Controls**
  - ±1 MHz
  - ±0.1 MHz
  - ±10 kHz
- **Modulation Selection**
  - FM
  - AM
  - SSB
  - CW
- **Saved Presets**
  - 2m Simplex (146.520 MHz)
  - GMRS
  - 2m Beacon
  - Emergency (121.5 MHz)

All controls update the display and simulated signal characteristics in real time.

---

## Recording Panel

### Purpose

Simulate RF audio recording for signal capture, analysis, and archival workflows.

### Behavior

- Toggleable **REC / STOP** control
- Live duration timer
- Visual state change when recording is active

### Demo Notes

- No actual IQ or audio data is stored
- Completion triggers a simulated “recording saved” notification

---

## Signal Analysis

### Purpose

Provide immediate visual feedback on RF conditions and receiver performance.

### Components

- **S-Meter**
  - Signal strength represented visually and numerically
- **Live Spectrum Display**
  - Animated frequency-domain visualization
  - Centered on the tuned frequency
- **Signal Statistics**
  - Signal strength (dBm)
  - Noise floor
  - Signal-to-noise ratio (SNR)
  - Modulation
  - Bandwidth

### Demo Behavior

- Spectrum and meter values are procedurally generated
- Gain and frequency changes affect displayed strength

---

## Receiver Status

### Purpose

Expose hardware-level receiver details and controls.

### Displayed Information

- SDR device type
- Tuner model
- Gain (dB)
- Sample rate
- Active / inactive status

### Gain Control

- Slider-based gain adjustment
- Immediate visual impact on S-meter and spectrum
- Intended to map directly to SDR gain APIs in live mode

---

## Digital Message & Data Transfer

### Purpose

Enable **non-voice RF communications**, optimized for low-bandwidth, burst, and weak-signal links.

This subsystem is **text-first**, template-capable, and transmission-gated.

---

### Mode Tabs

| Tab | Function |
|---|---|
| TEXT | Free-form plaintext messaging |
| TEMPLATES | Structured operational message formats |
| FILES / IMAGES | File-based transfers |
| INBOX / LOG | Transmission history and message review |

---

### TEXT Mode

- Destination / callsign / node input
- Plaintext message body
- Actions:
  - TRANSMIT
  - QUEUE
  - CLEAR

Transport, encoding, and modulation are implicitly determined by the active RF profile (future backend).

---

### TEMPLATES Mode

Structured message formats designed for interoperability and disciplined traffic handling.

#### Supported Templates

- **ICS-213** – General Message
- **ARRL Radiogram**
- **Tactical SITREP**

#### Features

- Field-driven schemas
- Required-field enforcement
- Automatic DTG generation
- Radiogram CHECK calculation
- JSON-structured payload generation (demo-visible)

Templates are rendered dynamically and validated prior to transmission.

---

### FILES / IMAGES Mode

- File attachment selection
- Optional transfer notes
- Explicit warning about detectability and link requirements

**Demo warning:** File transfer functionality is representational only.

---

### INBOX / LOG

Chronological log of RF data activity.

Each entry includes:
- Time
- Direction (TX / RX)
- Message type
- Peer
- Status

Clicking a log entry opens a modal showing the full message payload.

---

## Transmission Safety Gating

Before any RF data transmission is queued, operators must acknowledge a **Transmission Warning Modal**.

### Warning Highlights

- RF traffic may be intercepted or direction-found
- Messages may persist in relays or logs
- Files and templates increase detectability

This gating is mandatory and designed to mirror real-world RF discipline.

---

## RF Propagation Estimation

### Purpose

Provide a **visual, explainable estimate** of RF coverage and detectability based on operator-defined parameters.

This is a **geometry-based demo model**, not a physics-accurate solver.

---

### Input Parameters

**General**
- Frequency (MHz)
- ERP (W)
- Antenna height (m)
- Environment:
  - Urban
  - Suburban
  - Rural

**HF Skywave Parameters**
- Maximum Usable Frequency (MUF)
- Day / night ionospheric conditions

**Directional Antenna Parameters**
- Antenna azimuth
- Beamwidth

---

### Map Visualization

A dark-themed Leaflet map displays:

- **Transmitter location**
- **Ideal coverage ellipse**
- **Environment-degraded coverage blob**
- **Directional antenna lobes**
- **HF skywave hop rings**
- **Optional threat receiver detection zones**
- **Fresnel zone clearance visualization**

Interactive map input is protected by a **hover-to-unlock guard** to prevent accidental manipulation.

---

## Demo Propagation Model

The demo model uses:
- Frequency-based attenuation
- Power and antenna height scaling
- Environmental loss factors
- Randomized distortion to simulate terrain and clutter

All calculations are intentionally transparent and explainable to operators.

---

## Intended Future Integrations

Once connected to live systems, this page is designed to support:

- Real SDR hardware (RTL-SDR, HackRF, etc.)
- Multi-node receiver selection
- Actual RF transmission control
- Digital modes (APRS, VARA, JS8, packet, etc.)
- Message encryption and authentication
- Real propagation modeling and terrain data
- Adversary detection and RF risk overlays

---

## Summary

The **RF Communications Dashboard** serves as the platform’s RF nerve center, integrating spectrum awareness, disciplined digital messaging, and coverage estimation into a single operational interface.

In demo mode, it functions as a high-fidelity simulation environment for validating operator workflows, UI ergonomics, and RF doctrine—prior to enabling live emissions and hardware control.

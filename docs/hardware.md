# Hardware Setup

## Overview
This document describes the hardware setup for the Raspberry Pi cluster that powers the portable emergency communications server. The cluster is built around 4 Raspberry Pi 5 units and various peripherials such as LoRa HATs, SDR dongles, RF transcievers, and a GPS reciever, designed to support a variety of RF communications and mesh networking applications.

## Raspberry Pi Setup
**Models Used:**
- **Raspberry Pi 5 (4GB):** *Primary nodes for running the PXE boot server, mesh networking, RF communications tools and passive RF monitoring.*
- **Raspberry Pi 5 (8GB):** *While not currently implemented, the 8GB Raspberry Pi's may replace the 4GB units in the future to allow for running more resource intensive applications if needed.*

**HATs & Accessories:**
- **PoE HATs (Power over Ethernet):** *Powers the Pi's directly via the Ethernet cable, eliminating the need for seperate power supplies.*
- **LoRa HAT & Dongles:** *Enables long-range communication via the LoRa protocol, used for wireless mesh networking and emergency communications.*
- **GPS Reciever:** *Provides GPS signals to syncronize time accross the cluster using NTP, ensuring accurate timekeeping for log entries and digital communications.*
- **SDR USB Dongles:** *Software-defined radios used for passive RF monitoring.*

## Hardware Components
**Raspberry Pi 5 (4GB)**
- **Purpose:** Acts as the PXE boot server and runs most of the network services like DHCP, TFTP, and NFS. Also used as end nodes for mesh networking and monitoring services.
- **Connection:** Connected via Cat 6a Ethernet for network communication and power via PoE HATS.

**LoRa HAT (Raspberry Pi)**
- **Purpose:** Provides long-range communication using the LoRa protocol, primarily used for mesh networking.
- **Connection:** Mounted directly to the Raspberry Pi GPIO pins.

**GPS Reciever**
- **Purpose:** Used to syncronize time across the Raspberry Pi nodes, ensuring accurate time for logs and digital RF communication.
- **Connection:** USB dongle connected to the Raspberry Pi boot node.

**SDR USB Dongles**
- **Purpose:** Used for passive RF monitoring and signal processing. Supports a variety of SDR software such as CubicSDR, SDRTrunk, and Dump1090.
- **Connection:** USB interface for data transmission and control. SMA to BNC connectors for external antennas.

**PoE Switch**
- **Purpose:** Used for connecting the Raspberry Pi nodes and other network devices (such as a wireless access point) in the local network. Also used to power the nodes through thier respective PoE HATs.
- **Connection:** Cat 6a Ethernet, managing communication between and power to the nodes.

**Power Supply & Battery Setup**
- **Purpose:** Powers the Pi cluster in the absence of power from the grid. A combination of a central AC adater and battery system is used to ensure continuous operations under any circumstances.
- **Connection:** Battery and AC power inputs connected to the PoE switch, which in turn powers the Pi's and periphery devices.

## Wiring diagram
Below is a diagram that illustrates how all the componencts are connected. This will help you visualize the phyiscal setup and connections bewteen the nodes, network infastructure, and other devices.

## Power Setup


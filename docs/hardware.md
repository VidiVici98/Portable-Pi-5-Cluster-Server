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

**OLED Displays**
- **Purpose:** Each Pi will have a dedicated 0.91" OLED display that will show status of the node as well as show a "Breach Risk" warning should security events be detected.
- **Connection:** These will attach to the GPIO pins on the Raspberry Pi's via dupont cables.

## Wiring diagram
Below is a diagram that illustrates how all the componencts are connected. This will help you visualize the phyiscal setup and connections bewteen the nodes, network infastructure, and other devices.

![Wiring Diagram](https://github.com/VidiVici98/Portable-Pi-5-Cluster-Server/blob/384e3a24f11a2ef5fdc4da2f00980558961ccbf6/docs/assets/Server_Diagram.jpg)

## Power Setup
The Raspberry Pi cluster is power via PoE using a centralized PoE switch (which is in turn battery powered). This simplifies the power management and reduces the number of cables. Each Raspberry Pi node is connected to the switch via Ethernet cables, which both supply power and handle data transfer.

The cluster is equipped with a battery backup system, ensuring continued operation during power outages. The battery 30 amp-hour nattery can power the Raspberry Pi nodes for several hours, depending on the usage and can be charged via an AC power adapter that interfaces via Anderson Powerpoles.

## Network Setup

**IP Addressing:** All Raspberry Pi nodes are configured with static IP addresses to ensure a consistent network setup.

**Wireless Access Point:** The Raspberry Pi cluster is connected to a local router for internal network communication.

**Network Switch:** The switch is used to connect the Raspberry Pi nodes to each other and the local network.

## Component Compatibility/Issues

**GPS Receiver Compatibility:** Some GPS dongles may require additional drivers or specific configurations to work with the Raspberry Pi. Ensure that the correct drivers are installed for NTP synchronization.

**SDR Dongles:** Certain SDR models may require different software configurations or additional tools for full compatibility with the Raspberry Pi. The recommended software for most SDRs is CubicSDR or SDRTrunk, but testing with each specific dongle is required.

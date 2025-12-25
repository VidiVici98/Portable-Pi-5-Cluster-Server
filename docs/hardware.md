# Hardware Setup

## Overview
This document describes the hardware setup for the Raspberry Pi cluster that powers the portable emergency communications server. The cluster is built around 4 Raspberry Pi 5 units and various peripherials such as LoRa HATs, SDR dongles, RF transcievers, and a GPS reciever, designed to support a variety of RF communications and mesh networking applications.

## Hardware Components

### Raspberry Pi Setup
**Models Used:**
- **Raspberry Pi 5 (4GB):** *Primary nodes for running the PXE boot server, mesh networking, RF communications tools and passive RF monitoring.*
- **Raspberry Pi 5 (8GB):** *While not currently implemented, the 8GB Raspberry Pi's may replace the 4GB units in the future to allow for running more resource intensive applications if needed.*

**HATs & Accessories:**
- **PoE HATs (Power over Ethernet):** *Powers the Pi's directly via the Ethernet cable, eliminating the need for seperate power supplies.*
- **LoRa HAT & Dongles:** *Enables long-range communication via the LoRa protocol, used for wireless mesh networking and emergency communications.*
- **GPS Reciever:** *Provides GPS signals to syncronize time accross the cluster using NTP, ensuring accurate timekeeping for log entries and digital communications.*
- **SDR USB Dongles:** *Software-defined radios used for passive RF monitoring.*

**Raspberry Pi 5 (4GB & 8GB)**
- **Purpose:** Acts as the PXE boot server and runs most of the network services like DHCP, TFTP, and NFS. Also used as end nodes for mesh networking and monitoring services.
- **Connection:** Connected via Cat 6a Ethernet for network communication and power via PoE HATS.

**PoE HAT (WaveShare F)**
- **Purpose:** Allows the Pi's to be powered via Power over Ethernet rather than requiring a seperate power cable. This HAT also incoporates a small fan and features stackable GPIO pins.
- **Connection:** Mounts directly to the Raspberry Pi GPIO pins.

**NVME PCIe to M.2 HAT (WaveShare)**
- **Purpose:** Not only does this HAT provide PoE and cooling capabilities, but it also allows an M.2 SSD to be used rather than the SD card, increasing both the ammount and longevity of our storage.
- **Connection:** Mounts directly to the Raspberry Pi GPIO pins with a ribbon cable to the PCIe.

**M.2 2242 SSD (Samsung)**
- **Purpose:** This internal SSD will serve as the primary storage device for the server rather than SD cards. This also increases the ammount of and longevity of the storage at our disposal - essential for an NFS setup.
- **Connection:** Interfaces with the WaveShare NVME PCIe to M.2 HAT.

**LoRa HAT (WaveShare)**
- **Purpose:** Provides long-range communication using the LoRa protocol, primarily used for mesh networking.
- **Connection:** Mounted directly to the Raspberry Pi GPIO pins.

**GPS Reciever (HiLetGo)**
- **Purpose:** Used to syncronize time across the Raspberry Pi nodes, ensuring accurate time for logs and digital RF communication.
- **Connection:** USB dongle connected to the Raspberry Pi boot node.

**SDR USB Dongles (Nooelec Nano 3 & NESDR Smart XTR)**
- **Purpose:** Used for passive RF monitoring and signal processing. Supports a variety of SDR software such as CubicSDR, SDRTrunk, and Dump1090.
- **Connection:** USB interface for data transmission and control. SMA to BNC connectors for external antennas.

**OLED Displays**
- **Purpose:** Each Pi will have a dedicated 0.91" OLED display that will show status of the node as well as show a "Breach Risk" warning should security events be detected.
- **Connection:** These will attach to the GPIO pins on the Raspberry Pi's via dupont cables.


### Power Setup
The Raspberry Pi cluster is power via PoE using a centralized PoE switch (which is in turn battery powered). This simplifies the power management and reduces the number of cables. Each Raspberry Pi node is connected to the switch via Ethernet cables, which both supply power and handle data transfer.

The cluster is equipped with a battery backup system, ensuring continued operation during power outages. The battery 30 amp-hour nattery can power the Raspberry Pi nodes for several hours, depending on the usage and can be charged via an AC power adapter that interfaces via Anderson Powerpoles.

**Wiring diagram**
Below is a diagram that illustrates how all the componencts are connected. This will help you visualize the phyiscal setup and connections bewteen the nodes, network infastructure, and other devices.

![Wiring Diagram](https://github.com/VidiVici98/Portable-Pi-5-Cluster-Server/blob/f2b8dbdc4f8589593db29e4760a1db96a286c4e8/docs/assets/Wiring-Diagram.png)

**PoE Managed Network Switch (Xnyahitog)**
- **Purpose:** Used for connecting the Raspberry Pi nodes and other network devices (such as a wireless access point) in the local network. Also used to power the nodes through thier respective PoE HATs.
- **Connection:** Cat 6A shielded Ethernet, managing communication between and power to the nodes while minimizing interference.

**Battery (LiFePo4)**
- **Purpose:** Powers the Pi cluster in the absence of external power.
- **Connection:** Interfaces to the fuse panel via Anderson Powerpoles as well as to an external bulkhead for re-charging.

**AC Adapter**
- **Purpose:** Allows the battery to be charged via AC power sources.
- **Connection:** Interfaces with the battery via the external bulkhead using Anderson Powerpoles.


### Network Setup

*IP Addressing:* All Raspberry Pi nodes are configured with static IP addresses to ensure a consistent network setup.

**Wireless Access Point (TP-Link EAP225):** 
- **Purpose:** The Raspberry Pi cluster is connected to a wireless access point for external network communication over WiFi. Being dual-band, it is ideal for a wide variety of RF environments.
- **Interface:** Connects to the PoE switch using cat 6A shielded Ethernet cable.

**PoE Managed Network Switch:** 
- **Purpose:** The switch is used to connect the Raspberry Pi nodes to each other and the external network (the access point).
- **Interface:** Connects to each of the Pi's as well as the access point using cat 6A shielded Ethernet cable.


## Additional Considerations

This setup is being designed with portability in mind, so careful consideration went into the overall weight and dimensions of the components. The entire assembly is fitted into a Pelican-type case for robust field deployment.

## Getting Started with This Hardware

1. **Physical Assembly:** Follow the wiring diagram above to connect all components
2. **Initial Setup:** See [QUICK-START.md](quick-start.md) for 30-minute boot node deployment
3. **Complete Guide:** [SETUP.md](setup.md) has step-by-step installation walkthrough
4. **Troubleshooting:** [TROUBLESHOOTING.md](troubleshooting.md) for hardware-related issues

## Network Default Configuration

The cluster uses this IP addressing scheme (configurable in `config/network/dnsmasq.conf`):

```
Boot Node:    192.168.1.10   (DHCP server)
ISR Node:     192.168.1.20   (RF monitoring)
Mesh Node:    192.168.1.30   (LoRa networking)
VHF Node:     192.168.1.40   (Transceiver)
DHCP Range:   192.168.1.100-200
```

## Power Consumption

Typical power draw per Pi 5 with PoE HAT and SSD:
- Idle: ~8-10W per node
- Peak load: ~25W per node
- 4-node cluster idle: ~40W
- 4-node cluster peak: ~100W

Battery capacity: 30 Ah @ 12V = 360 Wh total
Expected runtime: 3-4 hours at full load, 8+ hours at idle

## See Also

- [QUICK-START.md](quick-start.md) - Get running in 30 minutes
- [SETUP.md](setup.md) - Complete installation guide
- [INFRASTRUCTURE.md](../INFRASTRUCTURE.md) - Architecture overview
- [TROUBLESHOOTING.md](troubleshooting.md) - Hardware troubleshooting

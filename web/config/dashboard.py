from datetime import datetime
# Single source of truth for dashboard metadata
DASHBOARD_CONFIG = {
    "BUILD_VERSION": "v0.2.0",
    "BUILD_DATE": "1 Jan 2026",
    "BUILD_HASH": "mws-dbe79b8c7f1",
    "BUILD_PROFILE": "Field Portable",
    "CLUSTER_ID": "A9F3",
    "SERVER_START_TIME": datetime.utcnow(), # uptime calculation reference
    "OPERATING_MODE": "Exercise",
    "MISSION_PROFILE": "Low Visibility",
    "DATA_CLASSIFICATION": "Sensitive"
}
# Nodes
NODES = {
    'boot': {
        'ip': '192.168.1.10',
        'name': 'Boot',
        'type': 'command',
        'purpose': 'Centralized control and command of the cluster infrastructure.',
        'tools': {
            'services': ['NTP', 'NFS', 'DHCP', 'TFTP', 'flask' ],
        }
    },
    'isr': {
        'ip': '192.168.1.20',
        'name': 'SigInt',
        'type': 'isr',
        'purpose': 'Airspace and RF spectrum monitoring using software defined radios.',
        'tools': {
            'services': ['dump1090', 'readsb', 'rtl-sdr', 'dump978', 'pyaware', 'fldigi', 'aprs'],
        }
    },
    'mesh': {
        'ip': '192.168.1.30',
        'name': 'Mesh',
        'type': 'mesh',
        'purpose': 'Centralized support and coordinating for ad hoc 915mHz LoRa mesh networks.',
        'tools': {
            'services': ['Batman-adv', 'Reticulm', 'freeTAKserver', 'meshtastic', 'mosquito'],
        }
    },
    'vhf': {
        'ip': '192.168.1.40',
        'name': 'RF',
        'type': 'radio',
        'purpose': 'HF/VHF/UHF voice and data communications via analog or digital RF transmitters with CAT Control.',
        'tools': {
            'services': ['gqrx', 'satscape', 'winlink', 'fldigi', 'js8', ''],
        }
    }
}
# Roles
ROLES = {
    'admin': {
        'permissions': [
            'deploy', 
            'reboot', 
            'update', 
            'transmit', 
            'manage_mesh', 
            'manage_users'
            ]
        },
    'net control': {
        'permissions': [
            'transmit', 
            'monitor', 
            'manage_mesh' 
            ]
        },
    'operator': {
        'permissions': [
            'monitor'
            ]
        }
    }
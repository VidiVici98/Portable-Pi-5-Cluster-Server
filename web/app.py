#!/usr/bin/env python3

"""
Cluster Command & Control Dashboard
Tactical operations interface for Portable Pi 5 cluster

Supports:
- Real-time node monitoring
- Cluster control operations
- Performance analysis
- Configuration management
- Local testing mode (no cluster required)
"""

import os
import json
import subprocess
import socket
from datetime import datetime
from functools import wraps

from flask import Flask, render_template, jsonify, request, session, redirect, url_for
from flask_cors import CORS
# web/app.py
from flask import Flask, render_template

# Local configuration
DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'
DEMO_MODE = os.getenv('DEMO_MODE', 'True').lower() == 'true'

# Cluster node definitions with tool categories
NODES = {
    'boot': {
        'ip': '192.168.1.10',
        'name': 'Boot Node',
        'type': 'infrastructure',
        'purpose': 'Core cluster infrastructure, NTP sync, NFS server',
        'tools': {
            'system': ['NTP Sync', 'NFS Server', 'DHCP'],
            'monitoring': ['Cluster Health', 'Network Monitor'],
            'admin': ['Shutdown All', 'Reboot All', 'Update All']
        }
    },
    'isr': {
        'ip': '192.168.1.20',
        'name': 'ISR Node',
        'type': 'rf_monitoring',
        'purpose': 'Intelligence, Surveillance, Reconnaissance - ADSB/UAT monitoring',
        'tools': {
            'adsb': ['dump1090', 'readsb', 'ADSB Track Display'],
            'uat': ['dump978', 'UAT Monitor', 'Alert System'],
            'analysis': ['Flight Track History', 'Aircraft Database', 'Alert Config'],
            'integration': ['PLACEHOLDER: Custom ADSB Receiver', 'PLACEHOLDER: UAT Decoder']
        }
    },
    'mesh': {
        'ip': '192.168.1.30',
        'name': 'Mesh Node',
        'type': 'networking',
        'purpose': 'Mesh networking, inter-node communication, redundancy',
        'tools': {
            'mesh': ['Batman-adv Status', 'Mesh Route Viewer', 'Network Topology'],
            'routing': ['OLSR Monitor', 'Route Optimization', 'Peer Status'],
            'redundancy': ['Link Failover', 'Connection Status', 'Backup Routes'],
            'integration': ['PLACEHOLDER: Custom Mesh Protocol', 'PLACEHOLDER: Network Tools']
        }
    },
    'vhf': {
        'ip': '192.168.1.40',
        'name': 'VHF Node',
        'type': 'radio',
        'purpose': 'Software Defined Radio (SDR), VHF/UHF communications',
        'tools': {
            'sdr': ['GQRX', 'RTL-SDR Tools', 'Frequency Scanner'],
            'vhf': ['VHF Receiver', 'VHF Transmitter', 'Squelch Monitor'],
            'radio': ['Signal Strength', 'Modulation Analyzer', 'Recording'],
            'integration': ['PLACEHOLDER: Custom SDR App', 'PLACEHOLDER: VHF Tools']
        }
    }
}

# Initialize Flask app
app = Flask(__name__, template_folder='templates', static_folder='static')
app.secret_key = os.getenv('SECRET_KEY', 'tactical-ops-default-key')
CORS(app)

################################################################################
# AUTHENTICATION AND BOOT LANDING PAGE
################################################################################

USERS = {'admin': os.getenv('ADMIN_PASSWORD', 'admin123')}

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user' not in session:
            return redirect(url_for('login', next=request.url))
        return f(*args, **kwargs)
    return decorated

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if USERS.get(username) == password:
            session['user'] = username
            return redirect(request.args.get('next') or url_for('boot_landing'))
        return render_template('login.html', error='Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect(url_for('login'))

@app.route('/boot')
@login_required
def boot_landing():
    """Dashboard boot landing / preloader page"""
    return render_template('boot_landing.html')
@app.route('/header')
def header():
    return render_template('components/header.html')

################################################################################
# UTILITIES
################################################################################

class ClusterAPI:
    """Interface with cluster nodes"""
    
    @staticmethod
    def ping_node(node_id):
        """Check if node is reachable"""
        if DEMO_MODE:
            return True
        
        node_ip = NODES.get(node_id, {}).get('ip')
        if not node_ip:
            return False
        
        try:
            result = subprocess.run(
                ['ping', '-c', '1', '-W', '2', node_ip],
                capture_output=True,
                timeout=5
            )
            return result.returncode == 0
        except:
            return False
    
    @staticmethod
    def get_node_health(node_id):
        """Get node health metrics"""
        if DEMO_MODE:
            return {
                'status': 'online',
                'uptime': '45 days 12:34:56',
                'load': [0.45, 0.38, 0.42],
                'memory': {'used': 2048, 'total': 4096, 'percent': 50},
                'disk': {'used': 25600, 'total': 32768, 'percent': 78},
                'temperature': 52,
                'last_check': datetime.now().isoformat()
            }
        
        try:
            node_ip = NODES.get(node_id, {}).get('ip')
            result = subprocess.run(
                ['ssh', '-o', 'StrictHostKeyChecking=no', f'pi@{node_ip}',
                 'uptime && free && df /'],
                capture_output=True,
                timeout=10
            )
            return {'status': 'online'} if result.returncode == 0 else {'status': 'offline'}
        except:
            return {'status': 'offline'}
    
    @staticmethod
    def execute_command(node_id, command):
        """Execute command on remote node"""
        if DEMO_MODE:
            return {'success': True, 'output': f'[DEMO] Executed: {command}'}
        
        try:
            node_ip = NODES.get(node_id, {}).get('ip')
            result = subprocess.run(
                ['ssh', '-o', 'StrictHostKeyChecking=no', f'pi@{node_ip}', command],
                capture_output=True,
                timeout=30
            )
            return {
                'success': result.returncode == 0,
                'output': result.stdout.decode() if result.stdout else ''
            }
        except Exception as e:
            return {'success': False, 'error': str(e)}

################################################################################
# ROUTES - PAGES
################################################################################

@app.route('/')
def index():
    """Main dashboard"""
    return render_template('index.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/monitor')
def monitor():
    """Node monitoring page"""
    return render_template('monitor.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/control')
def control():
    """Cluster control page"""
    return render_template('control.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/tools')
def tools():
    """Node tools and integration page"""
    return render_template('tools.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/isr')
def adsb():
    """ADSB/UAT aircraft tracking page"""
    return render_template('isr.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/mesh')
def mesh():
    """Mesh network topology page"""
    return render_template('mesh.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/vhf')
def vhf():
    """VHF/SDR frequency control page"""
    return render_template('vhf.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/performance')
def performance():
    """Performance analysis page"""
    return render_template('performance.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/backup')
def backup():
    """Backup management page"""
    return render_template('backup.html', nodes=NODES, demo_mode=DEMO_MODE)

@app.route('/settings')
def settings():
    """Settings page"""
    return render_template('settings.html', nodes=NODES, demo_mode=DEMO_MODE)

################################################################################
# API - NODE STATUS
################################################################################

@app.route('/api/nodes/list')
def api_nodes_list():
    """Get list of all nodes"""
    nodes_data = []
    for node_id, node_info in NODES.items():
        online = ClusterAPI.ping_node(node_id)
        nodes_data.append({
            'id': node_id,
            'name': node_info['name'],
            'type': node_info['type'],
            'ip': node_info['ip'],
            'online': online,
            'status': 'online' if online else 'offline'
        })
    return jsonify(nodes_data)

@app.route('/api/nodes/<node_id>/health')
def api_node_health(node_id):
    """Get health metrics for specific node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    health = ClusterAPI.get_node_health(node_id)
    return jsonify(health)

@app.route('/api/nodes/<node_id>/status')
def api_node_status(node_id):
    """Get current status of node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    node = NODES[node_id]
    online = ClusterAPI.ping_node(node_id)
    
    return jsonify({
        'id': node_id,
        'name': node['name'],
        'type': node['type'],
        'ip': node['ip'],
        'online': online,
        'status': 'online' if online else 'offline',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/cluster/status')
def api_cluster_status():
    """Get overall cluster status"""
    cluster_status = {
        'timestamp': datetime.now().isoformat(),
        'nodes': {},
        'online_count': 0,
        'offline_count': 0,
        'total_count': len(NODES)
    }
    
    for node_id, node_info in NODES.items():
        online = ClusterAPI.ping_node(node_id)
        cluster_status['nodes'][node_id] = {
            'name': node_info['name'],
            'online': online,
            'ip': node_info['ip']
        }
        if online:
            cluster_status['online_count'] += 1
        else:
            cluster_status['offline_count'] += 1
    
    return jsonify(cluster_status)

################################################################################
# API - OPERATIONS
################################################################################

@app.route('/api/deploy/boot-node', methods=['POST'])
def api_deploy_boot():
    """Deploy boot node"""
    if DEMO_MODE:
        return jsonify({'success': True, 'message': 'Boot node deployment started (DEMO)'})
    
    result = ClusterAPI.execute_command('boot', 
        'sudo /home/pi/Portable-Pi-5-Cluster-Server/scripts/deployment-coordinator.sh boot')
    return jsonify(result)

@app.route('/api/deploy/cluster', methods=['POST'])
def api_deploy_cluster():
    """Deploy entire cluster"""
    if DEMO_MODE:
        return jsonify({'success': True, 'message': 'Full cluster deployment started (DEMO)'})
    
    result = ClusterAPI.execute_command('boot',
        'sudo /home/pi/Portable-Pi-5-Cluster-Server/scripts/deployment-coordinator.sh full')
    return jsonify(result)

@app.route('/api/health-check', methods=['POST'])
def api_health_check():
    """Run health check on cluster"""
    if DEMO_MODE:
        return jsonify({
            'success': True,
            'checks_passed': 65,
            'checks_warned': 8,
            'checks_failed': 2,
            'health_percent': 88
        })
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/scripts/health-check-all.sh')
    return jsonify(result)

@app.route('/api/validate-config', methods=['POST'])
def api_validate_config():
    """Validate cluster configuration"""
    if DEMO_MODE:
        return jsonify({
            'success': True,
            'message': 'Configuration validated (DEMO)'
        })
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/scripts/validate-all-configs.sh')
    return jsonify(result)

################################################################################
# API - NODE CONTROL
################################################################################

@app.route('/api/nodes/<node_id>/reboot', methods=['POST'])
def api_node_reboot(node_id):
    """Reboot a node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    if DEMO_MODE:
        return jsonify({'success': True, 'message': f'{node_id} reboot initiated (DEMO)'})
    
    result = ClusterAPI.execute_command(node_id, 'sudo reboot')
    return jsonify(result)

@app.route('/api/nodes/<node_id>/shutdown', methods=['POST'])
def api_node_shutdown(node_id):
    """Shutdown a node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    if DEMO_MODE:
        return jsonify({'success': True, 'message': f'{node_id} shutdown initiated (DEMO)'})
    
    result = ClusterAPI.execute_command(node_id, 'sudo shutdown -h now')
    return jsonify(result)

@app.route('/api/cluster/reboot-all', methods=['POST'])
def api_reboot_all():
    """Reboot all nodes"""
    if DEMO_MODE:
        return jsonify({'success': True, 'message': 'Cluster reboot initiated (DEMO)'})
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/scripts/cluster-orchestrator.sh reboot-all')
    return jsonify(result)

@app.route('/api/cluster/update-all', methods=['POST'])
def api_update_all():
    """Update all nodes"""
    if DEMO_MODE:
        return jsonify({'success': True, 'message': 'Cluster update initiated (DEMO)'})
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/scripts/cluster-orchestrator.sh update-all')
    return jsonify(result)

################################################################################
# API - BACKUP/RESTORE
################################################################################

@app.route('/api/backup/create', methods=['POST'])
def api_backup_create():
    """Create backup"""
    if DEMO_MODE:
        return jsonify({
            'success': True,
            'backup_id': 'backup-20251225-082234',
            'size_mb': 2456,
            'message': 'Backup created (DEMO)'
        })
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/operations/backups/backup-restore-manager.sh create')
    return jsonify(result)

@app.route('/api/backup/list')
def api_backup_list():
    """List available backups"""
    if DEMO_MODE:
        return jsonify({
            'backups': [
                {'id': 'backup-20251225-082234', 'size_mb': 2456, 'date': '2025-12-25 08:22:34'},
                {'id': 'backup-20251224-180000', 'size_mb': 2401, 'date': '2025-12-24 18:00:00'},
                {'id': 'backup-20251223-120000', 'size_mb': 2389, 'date': '2025-12-23 12:00:00'}
            ]
        })
    
    result = ClusterAPI.execute_command('boot',
        '/home/pi/Portable-Pi-5-Cluster-Server/operations/backups/backup-restore-manager.sh list')
    return jsonify(result)

@app.route('/api/backup/restore/<backup_id>', methods=['POST'])
def api_backup_restore(backup_id):
    """Restore from backup"""
    if DEMO_MODE:
        return jsonify({
            'success': True,
            'message': f'Restore from {backup_id} initiated (DEMO)'
        })
    
    result = ClusterAPI.execute_command('boot',
        f'/home/pi/Portable-Pi-5-Cluster-Server/operations/backups/backup-restore-manager.sh restore')
    return jsonify(result)

################################################################################
# API - PERFORMANCE
################################################################################

@app.route('/api/performance/summary')
def api_performance_summary():
    """Get performance summary"""
    if DEMO_MODE:
        return jsonify({
            'cpu_avg': 35.2,
            'memory_avg': 62.1,
            'disk_usage': 78.5,
            'network_throughput_mbps': 45.3,
            'temperature_avg': 51.2,
            'timestamp': datetime.now().isoformat()
        })
    
    return jsonify({'error': 'Performance data not available'}), 503

@app.route('/api/performance/<node_id>')
def api_performance_node(node_id):
    """Get performance metrics for node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    if DEMO_MODE:
        return jsonify({
            'cpu': 32.5,
            'memory': 65.2,
            'disk': 78.9,
            'network': 42.1,
            'temperature': 52.3,
            'timestamp': datetime.now().isoformat()
        })
    
    return jsonify({'error': 'Performance data not available'}), 503

################################################################################
# API - TOOL-SPECIFIC ENDPOINTS
################################################################################

@app.route('/api/nodes/isr/adsb/aircraft')
def api_isr_adsb_aircraft():
    """Get list of currently tracked aircraft (ADSB)"""
    if DEMO_MODE:
        import random
        aircraft = []
        callsigns = ['AAL123', 'UAL456', 'DAL789', 'SWA101', 'JBU202', 'SKW303', 'ASA404']
        for i, cs in enumerate(callsigns):
            aircraft.append({
                'icao': f'A{i:05X}',
                'callsign': cs,
                'latitude': 37.7749 + random.uniform(-0.5, 0.5),
                'longitude': -122.4194 + random.uniform(-0.5, 0.5),
                'altitude': random.randint(5000, 40000),
                'speed': random.randint(300, 500),
                'heading': random.randint(0, 360)
            })
        return jsonify({'aircraft': aircraft})
    
    try:
        result = subprocess.run(
            ['curl', '-s', 'http://192.168.1.20:8080/data/aircraft.json'],
            capture_output=True,
            timeout=5
        )
        if result.returncode == 0:
            return jsonify(json.loads(result.stdout))
    except:
        pass
    
    return jsonify({'aircraft': []}), 503

################################################################################
# API - NODE-SPECIFIC TOOLS
################################################################################

@app.route('/api/nodes/<node_id>/tools')
def api_node_tools(node_id):
    """Get available tools for a specific node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    node = NODES[node_id]
    return jsonify({
        'node_id': node_id,
        'node_name': node['name'],
        'node_type': node['type'],
        'purpose': node['purpose'],
        'tools': node['tools'],
        'available_tools_count': sum(len(tools) for tools in node['tools'].values())
    })

@app.route('/api/nodes/<node_id>/tool-status')
def api_node_tool_status(node_id):
    """Get status of tools on a node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    if DEMO_MODE:
        node = NODES[node_id]
        tools_status = {}
        for category, tools in node['tools'].items():
            tools_status[category] = {}
            for tool in tools:
                if 'PLACEHOLDER' in tool:
                    tools_status[category][tool] = {
                        'installed': False,
                        'running': False,
                        'status': 'not_available'
                    }
                else:
                    tools_status[category][tool] = {
                        'installed': True,
                        'running': tool not in ['Alert Config', 'Route Optimization'],
                        'status': 'running' if tool not in ['Alert Config', 'Route Optimization'] else 'idle'
                    }
        return jsonify({
            'node_id': node_id,
            'timestamp': datetime.now().isoformat(),
            'tools_status': tools_status
        })
    
    return jsonify({'error': 'Tool status not available in production'}), 503

@app.route('/api/nodes/<node_id>/tool/<tool_name>', methods=['GET', 'POST'])
def api_node_tool_action(node_id, tool_name):
    """Interact with a specific tool on a node"""
    if node_id not in NODES:
        return jsonify({'error': 'Node not found'}), 404
    
    action = request.args.get('action', 'status')
    
    if DEMO_MODE:
        return jsonify({
            'node_id': node_id,
            'tool': tool_name,
            'action': action,
            'status': 'demo_response',
            'message': f'{action.capitalize()} on {tool_name}',
            'timestamp': datetime.now().isoformat()
        })
    
    result = ClusterAPI.execute_command(node_id, f'which {tool_name}')
    return jsonify(result) if result.get('success') else \
           jsonify({'error': f'{tool_name} not found on {node_id}'}), 404

@app.route('/api/cluster/node-summary')
def api_cluster_node_summary():
    """Get detailed summary of all nodes with their purposes and tools"""
    if DEMO_MODE:
        summary = []
        for node_id, node_info in NODES.items():
            summary.append({
                'id': node_id,
                'name': node_info['name'],
                'type': node_info['type'],
                'purpose': node_info['purpose'],
                'ip': node_info['ip'],
                'online': True,
                'tools': {
                    'total': sum(len(tools) for tools in node_info['tools'].values()),
                    'categories': list(node_info['tools'].keys()),
                    'available': node_info['tools']
                }
            })
        return jsonify(summary)
    
    summary = []
    for node_id, node_info in NODES.items():
        online = ClusterAPI.ping_node(node_id)
        summary.append({
            'id': node_id,
            'name': node_info['name'],
            'type': node_info['type'],
            'purpose': node_info['purpose'],
            'ip': node_info['ip'],
            'online': online,
            'tools': {
                'total': sum(len(tools) for tools in node_info['tools'].values()),
                'categories': list(node_info['tools'].keys())
            }
        })
    return jsonify(summary)

################################################################################
# ERROR HANDLERS
################################################################################

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Internal server error'}), 500

################################################################################
# MAIN
################################################################################

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    host = os.getenv('HOST', '127.0.0.1')
    
    print(f"""
╔════════════════════════════════════════╗
║  Cluster Command & Control Dashboard   ║
║  Tactical Operations Interface         ║
╚════════════════════════════════════════╝

Host: {host}
Port: {port}
Debug: {DEBUG}
Demo Mode: {DEMO_MODE}

Access: http://{host}:{port}

Press Ctrl+C to stop

    """)
    
    app.run(host=host, port=port, debug=DEBUG)

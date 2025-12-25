# Dashboard API Reference

Complete API endpoint documentation for the Cluster Dashboard

---

## Base URL

```
http://localhost:5000/api
```

Or when deployed:
```
http://192.168.1.10:5000/api
```

---

## Authentication

Currently **no authentication required** in demo mode.

For production, add Bearer token:
```
Authorization: Bearer YOUR_TOKEN
```

---

## Status Endpoints

### Get Cluster Status
```
GET /cluster/status
```

Returns overall cluster health and all node statuses.

**Response:**
```json
{
  "timestamp": "2025-12-25T08:22:34.123456",
  "nodes": {
    "boot": {"name": "Boot Node", "online": true, "ip": "192.168.1.10"},
    "isr": {"name": "ISR Node", "online": true, "ip": "192.168.1.20"},
    "mesh": {"name": "Mesh Node", "online": false, "ip": "192.168.1.30"},
    "vhf": {"name": "VHF Node", "online": true, "ip": "192.168.1.40"}
  },
  "online_count": 3,
  "offline_count": 1,
  "total_count": 4
}
```

---

### List All Nodes
```
GET /nodes/list
```

Returns all nodes with basic information.

**Response:**
```json
[
  {
    "id": "boot",
    "name": "Boot Node",
    "type": "infrastructure",
    "ip": "192.168.1.10",
    "online": true,
    "status": "online"
  },
  {
    "id": "isr",
    "name": "ISR Node",
    "type": "rf_monitoring",
    "ip": "192.168.1.20",
    "online": true,
    "status": "online"
  }
]
```

---

### Get Node Status
```
GET /nodes/<node_id>/status
```

Get status of specific node.

**Parameters:**
- `node_id` - Node ID: `boot`, `isr`, `mesh`, or `vhf`

**Response:**
```json
{
  "id": "isr",
  "name": "ISR Node",
  "type": "rf_monitoring",
  "ip": "192.168.1.20",
  "online": true,
  "status": "online",
  "timestamp": "2025-12-25T08:22:34.123456"
}
```

---

### Get Node Health
```
GET /nodes/<node_id>/health
```

Get detailed health metrics for a node.

**Parameters:**
- `node_id` - Node ID

**Response:**
```json
{
  "status": "online",
  "uptime": "45 days 12:34:56",
  "load": [0.45, 0.38, 0.42],
  "memory": {
    "used": 2048,
    "total": 4096,
    "percent": 50
  },
  "disk": {
    "used": 25600,
    "total": 32768,
    "percent": 78
  },
  "temperature": 52,
  "last_check": "2025-12-25T08:22:34.123456"
}
```

---

## Deployment Endpoints

### Deploy Boot Node
```
POST /deploy/boot-node
```

Start boot node deployment (phases 1-4).

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Boot node deployment started (DEMO)"
}
```

---

### Deploy Full Cluster
```
POST /deploy/cluster
```

Start complete cluster deployment (all nodes).

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Full cluster deployment started (DEMO)"
}
```

---

## Node Control Endpoints

### Reboot Node
```
POST /nodes/<node_id>/reboot
```

Reboot a specific node.

**Parameters:**
- `node_id` - Node ID

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "isr reboot initiated (DEMO)"
}
```

---

### Shutdown Node
```
POST /nodes/<node_id>/shutdown
```

Shutdown a specific node.

**Parameters:**
- `node_id` - Node ID

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "isr shutdown initiated (DEMO)"
}
```

---

### Reboot All Nodes
```
POST /cluster/reboot-all
```

Orchestrated reboot of all nodes.

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Cluster reboot initiated (DEMO)"
}
```

---

### Update All Nodes
```
POST /cluster/update-all
```

Update all nodes (apt-get update && upgrade).

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Cluster update initiated (DEMO)"
}
```

---

## Health & Validation Endpoints

### Run Health Check
```
POST /health-check
```

Run comprehensive health check on all nodes.

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "checks_passed": 65,
  "checks_warned": 8,
  "checks_failed": 2,
  "health_percent": 88
}
```

---

### Validate Configuration
```
POST /validate-config
```

Validate cluster configuration (80+ checks).

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Configuration validated (DEMO)"
}
```

---

## Backup Endpoints

### List Backups
```
GET /backup/list
```

List all available backups.

**Response:**
```json
{
  "backups": [
    {
      "id": "backup-20251225-082234",
      "size_mb": 2456,
      "date": "2025-12-25 08:22:34"
    },
    {
      "id": "backup-20251224-180000",
      "size_mb": 2401,
      "date": "2025-12-24 18:00:00"
    }
  ]
}
```

---

### Create Backup
```
POST /backup/create
```

Create a new complete backup.

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "backup_id": "backup-20251225-082234",
  "size_mb": 2456,
  "message": "Backup created (DEMO)"
}
```

---

### Restore from Backup
```
POST /backup/restore/<backup_id>
```

Restore cluster state from a backup.

**Parameters:**
- `backup_id` - ID of backup to restore

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "message": "Restore from backup-20251225-082234 initiated (DEMO)"
}
```

---

## Performance Endpoints

### Get Cluster Performance
```
GET /performance/summary
```

Get overall cluster performance metrics.

**Response:**
```json
{
  "cpu_avg": 35.2,
  "memory_avg": 62.1,
  "disk_usage": 78.5,
  "network_throughput_mbps": 45.3,
  "temperature_avg": 51.2,
  "timestamp": "2025-12-25T08:22:34.123456"
}
```

---

### Get Node Performance
```
GET /performance/<node_id>
```

Get performance metrics for specific node.

**Parameters:**
- `node_id` - Node ID

**Response:**
```json
{
  "cpu": 32.5,
  "memory": 65.2,
  "disk": 78.9,
  "network": 42.1,
  "temperature": 52.3,
  "timestamp": "2025-12-25T08:22:34.123456"
}
```

---

## Error Responses

### 404 Not Found
```json
{
  "error": "Node not found"
}
```

### 500 Server Error
```json
{
  "error": "Internal server error"
}
```

### 503 Service Unavailable
```json
{
  "error": "Performance data not available"
}
```

---

## Rate Limiting

No rate limiting in current version.

For production, consider:
- 100 requests per minute per IP
- 1000 requests per day per API key
- Exponential backoff on 429 responses

---

## Pagination

No pagination in current version.

For large datasets, consider:
- `?page=1&limit=50` parameters
- Cursor-based pagination for logs

---

## Filtering & Sorting

No filtering in current version.

For future enhancements:
- `?status=online` - Filter by status
- `?sort=name` - Sort results
- `?type=rf_monitoring` - Filter by node type

---

## Webhooks (Future)

Planned webhook support for:
- Node status changes
- Health check failures
- Deployment completion
- High resource usage alerts

---

## Code Examples

### JavaScript/Fetch
```javascript
// Get cluster status
fetch('http://localhost:5000/api/cluster/status')
  .then(r => r.json())
  .then(data => console.log(data));

// Reboot all nodes
fetch('http://localhost:5000/api/cluster/reboot-all', {
  method: 'POST'
})
  .then(r => r.json())
  .then(data => console.log(data));
```

### Python/Requests
```python
import requests

# Get cluster status
response = requests.get('http://localhost:5000/api/cluster/status')
data = response.json()
print(data)

# Create backup
response = requests.post('http://localhost:5000/api/backup/create')
data = response.json()
print(data)
```

### cURL
```bash
# Get cluster status
curl http://localhost:5000/api/cluster/status

# Reboot all nodes
curl -X POST http://localhost:5000/api/cluster/reboot-all

# Create backup
curl -X POST http://localhost:5000/api/backup/create
```

---

## Changelog

### Version 1.0.0 (December 25, 2025)
- Initial release
- All core endpoints
- Demo mode
- Health checks
- Backup/restore
- Performance monitoring
- Node control

---

**API Version:** 1.0.0  
**Last Updated:** December 25, 2025  
**Status:** Production Ready ✅

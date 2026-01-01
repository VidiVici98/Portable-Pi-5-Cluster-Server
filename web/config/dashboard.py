from datetime import datetime

# Single source of truth for dashboard metadata
DASHBOARD_CONFIG = {
    "BUILD_VERSION": "v0.2.0",
    "CLUSTER_ID": "A9F3",
    "SERVER_START_TIME": datetime.utcnow()  # uptime calculation reference
}

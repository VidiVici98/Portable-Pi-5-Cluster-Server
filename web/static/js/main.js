// ==========================
// Tactical Dashboard - main.js
// ==========================
document.addEventListener("DOMContentLoaded", function () {

    // ==========================
    // ACTIVITY LOG BUFFER
    // ==========================
    window.__activityBuffer = [];

    window.logActivity = function(message) {
        const time = new Date().toLocaleTimeString();
        const entryHTML = `<span style="color: var(--text-muted);">[${time}]</span> ${message}`;
        const payload = { entryHTML };

        let delivered = false;

        const activityLog = document.getElementById('activity-log');
        if (activityLog) {
            const placeholder = activityLog.querySelector('.no-activity');
            if (placeholder) placeholder.remove();
            const entry = document.createElement('div');
            entry.style.cssText = 'padding: 5px 0; border-bottom: 1px solid var(--border-color-dim);';
            entry.innerHTML = entryHTML;
            activityLog.insertBefore(entry, activityLog.firstChild);
            delivered = true;
        }

        const alertsLog = document.getElementById('alertsLog');
        if (alertsLog) {
            const alertEntry = document.createElement('div');
            alertEntry.className = 'log-entry';
            alertEntry.innerHTML = entryHTML;
            alertsLog.prepend(alertEntry);
            delivered = true;
        }

        if (!delivered) window.__activityBuffer.push(payload);
    };

    function flushActivityBuffer() {
        if (!window.__activityBuffer.length) return;

        const tryFlush = () => {
            const activityLog = document.getElementById('activity-log');
            const alertsLog = document.getElementById('alertsLog');

            if (!activityLog && !alertsLog) {
                requestAnimationFrame(tryFlush);
                return;
            }

            window.__activityBuffer.forEach(({ entryHTML }) => {
                if (activityLog) {
                    const entry = document.createElement('div');
                    entry.style.cssText = 'padding: 5px 0; border-bottom: 1px solid var(--border-color-dim);';
                    entry.innerHTML = entryHTML;
                    activityLog.insertBefore(entry, activityLog.firstChild);
                }
                if (alertsLog) {
                    const alertEntry = document.createElement('div');
                    alertEntry.className = 'log-entry';
                    alertEntry.innerHTML = entryHTML;
                    alertsLog.prepend(alertEntry);
                }
            });

            window.__activityBuffer.length = 0;
        };

        tryFlush();
    }

    // ==========================
    // HEADER LOADING
    // ==========================
    function loadHeader() {
        fetch('/header')
            .then(res => res.ok ? res.text() : Promise.reject(new Error('Header fetch failed')))
            .then(html => {
                const container = document.getElementById('header-container');
                if (!container) return;

                container.innerHTML = html;
                requestAnimationFrame(() => {
                    initNavbarCollapse();
                    highlightActiveNav();
                });
            })
            .catch(err => console.error('Header load error:', err));
    }

    // ==========================
    // FOOTER LOADING + DYNAMIC
    // ==========================
    function loadFooter() {
        const container = document.getElementById('footer-embed-container');
        if (!container) return;

        fetch('/footer')
            .then(res => res.ok ? res.text() : Promise.reject(new Error('Footer fetch failed')))
            .then(html => {
                container.innerHTML = html;
                const waitForFooter = () => {
                    const alertsLog = document.getElementById('alertsLog');
                    if (!alertsLog) {
                        requestAnimationFrame(waitForFooter);
                        return;
                    }
                    initFooterDynamic();
                };
                waitForFooter();
            })
            .catch(err => console.error('Footer load error:', err));
    }

function initFooterDynamic() {
    updateFooterValues();
    initFooterButtons();
    initSlidePanelOutsideClose();
    flushActivityBuffer();
    trackPanels();

    // ==========================
    // BATTERY DISPLAY TOGGLE
    // ==========================
    const batterySpans = document.querySelectorAll('#battery-display span');
    if (batterySpans.length > 1) {
        let currentIndex = 0;
        batterySpans[currentIndex].classList.add('active');

        setInterval(() => {
            batterySpans[currentIndex].classList.remove('active');
            currentIndex = (currentIndex + 1) % batterySpans.length;
            batterySpans[currentIndex].classList.add('active');
        }, 6000); // 5 seconds per display
    }
}


    function updateFooterValues() {
        if (!window.CONFIG) return;
        const buildBtn = document.querySelector('.footer-btn[data-footer-action="build"]');
        const clusterBtn = document.querySelector('.footer-btn[data-footer-action="cluster"]');
        const sessionBtn = document.querySelector('.footer-btn[data-footer-action="session"]');

        if (buildBtn) buildBtn.textContent = window.CONFIG.dashboard_build || 'Dashboard Build';
        if (clusterBtn) clusterBtn.textContent = 'Cluster ' + (window.CONFIG.cluster_id || '--');
        if (sessionBtn) sessionBtn.textContent = 'Session ' + (window.CONFIG.session_id || '--');
    }

    // ==========================
    // UPTIME
    // ==========================
    let lastUptimeError = null;
    function updateUptime() {
        const el = document.getElementById('uptime-display');
        if (!el) return;

        fetch('/api/uptime')
            .then(res => {
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                return res.json();
            })
            .then(data => {
                el.textContent = formatTime(data.uptime_seconds || 0);
                lastUptimeError = null;
            })
            .catch(err => {
                const msg = err?.message || String(err) || 'Unknown error';
                if (msg !== lastUptimeError) {
                    logActivity('[Uptime] Failed to update: ' + msg);
                    lastUptimeError = msg;
                }
                console.error('Uptime update failed:', err);
            });
    }

    function formatTime(seconds) {
        const hrs = String(Math.floor(seconds / 3600)).padStart(2, '0');
        const mins = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
        const secs = String(seconds % 60).padStart(2, '0');
        return `${hrs}:${mins}:${secs}`;
    }

    // ==========================
    // FOOTER SLIDE PANELS
    // ==========================
    function initFooterButtons() {
        document.querySelectorAll('.footer-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.dataset.footerAction;
                if (!action) return;
                toggleSlidePanel(action);
            });
        });
    }

    function toggleSlidePanel(action) {
        const panel = document.getElementById(`panel-${action}`);
        if (!panel) return;

        const isVisible = panel.classList.contains('visible');
        document.querySelectorAll('.slide-panel').forEach(p => p.classList.remove('visible'));
        if (!isVisible) panel.classList.add('visible');
    }

    function initSlidePanelOutsideClose() {
        document.addEventListener('click', e => {
            const openPanel = document.querySelector('.slide-panel.visible');
            if (!openPanel) return;
            if (openPanel.contains(e.target)) return;
            if (e.target.closest('.footer-btn')) return;
            document.querySelectorAll('.slide-panel.visible').forEach(p => p.classList.remove('visible'));
        });
    }

    function trackPanels() {
        const footer = document.getElementById('footer-embed-container');
        if (!footer) return requestAnimationFrame(trackPanels);

        const panels = document.querySelectorAll('.slide-panel.visible');
        if (!panels.length) return requestAnimationFrame(trackPanels);

        const rect = footer.getBoundingClientRect();
        const visibleTop = Math.max(rect.top, 0);
        const visibleHeight = Math.min(rect.bottom, window.innerHeight) - visibleTop;

        panels.forEach(panel => {
            panel.style.bottom = `${visibleHeight}px`;
        });

        requestAnimationFrame(trackPanels);
    }

    // ==========================
    // SIDEBAR
    // ==========================
    const sidebarToggleBtn = document.querySelector('.sidebar-toggle');
    if (sidebarToggleBtn) sidebarToggleBtn.addEventListener('click', toggleSidebar);

    function toggleSidebar() {
        const sidebar = document.getElementById('quick-sidebar');
        if (!sidebar) return;
        sidebar.classList.toggle('expanded');
        sidebar.classList.toggle('collapsed');
    }

    function populateSidebar(pageId) {
        const sidebarNav = document.querySelector('#quick-sidebar .sidebar-content');
        if (!sidebarNav) return;

        const header = sidebarNav.querySelector('h4');
        sidebarNav.innerHTML = '';
        if (header) sidebarNav.appendChild(header);

        let links = [];
        switch (pageId) {
            case 'sigint':
                links = [
                    { text: 'Airspace Map', href: '#map-section' },
                    { text: 'Aircraft List', href: '#aircraft-section' },
                    { text: 'Receiver Control', href: '#reciever-control' },
                    { text: 'RF Waterfall', href: '#rf-waterfall' },
                    { text: 'Receiver Status', href: '#reciever-status' },
                    { text: 'Signals Triangulation', href: '#signal-triangulation' },
                    { text: 'Triangulation Map', href: '#triangulation-map' }
                ]; break;
            case 'mesh':
                links = [
                    { text: 'Tactical Map', href: '#tactical-map' },
                    { text: 'Send Alerts', href: '#send-alerts' },
                    { text: 'Node Status', href: '#node-status' },
                    { text: 'Communications Log', href: '#comms-log' }
                ]; break;
            case 'rf-comms':
                links = [
                    { text: 'Receiver Control', href: '#reciever-control' },
                    { text: 'Signal Analysis', href: '#signal-analysis' },
                    { text: 'Receiver Status', href: '#reciever-status' },
                    { text: 'Digital Data Transfer', href: '#data-transfer' },
                    { text: 'RF Propagation Estimator', href: '#propagation-estimation' },
                    { text: 'RF Propagation Map', href: '#propagation-map' }
                ]; break;
            case 'settings':
                links = [
                    { text: 'Deployment Profile', href: '#deployment-profile' },
                    { text: 'Power & Hardware', href: '#power-hardware' },
                    { text: 'Failover & Autonomy', href: '#failover' },
                    { text: 'Network & Mesh Behavior', href: '#mesh-network' },
                    { text: 'Security & Access Control', href: '#access-control' },
                    { text: 'Network Firewall', href: '#firewall-config' },
                    { text: 'Data Handling & OPSEC', href: '#opsec' },
                    { text: 'Secure Data Destruction', href: '#data-destruction' },
                    { text: 'Alerts & Notifications', href: '#notifications' },
                    { text: 'Maintenance & Updates', href: '#maintenance-updates' },
                    { text: 'Auditing & Forensics', href: '#auditing' }
                ]; break;
            case 'backup':
                links = [
                    { text: 'Create Backup', href: '#create-backup' },
                    { text: 'Available Backups', href: '#available-backups' },
                    { text: 'Backup Statistics', href: '#backup-stats' }
                ]; break;
            case 'dashboard':
                links = [
                    { text: 'Node Status', href: '#node-status' },
                    { text: 'Validate Config', href: '#validate-config' },
                    { text: 'Health Check', href: '#health' },
                    { text: 'Performance Metrics', href: '#performance' },
                    { text: 'Emergency Wipe', href: '#data-wipe' },
                    { text: 'Reboot Cluster', href: '#reboot-cluster' },
                    { text: 'Activity Log', href: '#activity-log' }
                ]; break;
        }

        links.forEach(link => {
            const a = document.createElement('a');
            a.href = link.href;
            a.textContent = link.text;
            sidebarNav.appendChild(a);
        });
    }

    function initSidebar() {
        const pageId = document.body.dataset.page;
        if (!pageId) return;
        populateSidebar(pageId);
    }

    // ==========================
    // NAVBAR COLLAPSE
    // ==========================
    function initNavbarCollapse() {
        const navbar = document.querySelector('.navbar');
        if (!navbar) return;

        let isCollapsed = false;
        const COLLAPSE_THRESHOLD = 10;

        function checkCollapse() {
            const scrollTop = window.scrollY || document.documentElement.scrollTop;
            const shouldCollapse = scrollTop > COLLAPSE_THRESHOLD;
            if (shouldCollapse !== isCollapsed) {
                navbar.classList.toggle('collapsed', shouldCollapse);
                isCollapsed = shouldCollapse;
            }
        }

        window.addEventListener('scroll', checkCollapse);
        checkCollapse();
    }

    // ==========================
    // ACTIVE NAV PAGE
    // ==========================
    function highlightActiveNav() {
        const pageId = document.body.dataset.page;
        if (!pageId) return;

        const navbar = document.getElementById('main-navbar');
        if (!navbar) return;

        navbar.querySelectorAll('.active-page')
            .forEach(el => el.classList.remove('active-page'));

        const activeLink = navbar.querySelector(`[data-page="${pageId}"]`);
        if (activeLink) activeLink.classList.add('active-page');
    }

// ==========================
// NODE MONITORING
// ==========================
let nodesData = {};

// Update node cards — must be defined BEFORE calling fetchNodes
function updateNodeCards() {
    const container = document.getElementById('nodes-container');
    if (!container) return;

    container.innerHTML = '';
    if (!Array.isArray(nodesData)) return;

    nodesData.forEach(node => {
        const card = document.createElement('div');
        card.className = 'node-card';
        card.innerHTML = `
            <h3>${node.name}</h3>
            <p>IP: ${node.ip}</p>
            <p>Type: ${node.type}</p>
            <p>Status: <span class="${node.online ? 'online' : 'offline'}">${node.status}</span></p>
        `;
        container.appendChild(card);
    });
}

// Fetch nodes — logs only errors
async function fetchNodes() {
    try {
        const response = await fetch('/api/nodes/list');
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        nodesData = data;
        updateNodeCards();
    } catch (err) {
        const msg = err?.message || String(err);
        console.error('[Nodes] Failed to fetch:', msg);
        logActivity('[Nodes] Fetch error: ' + msg);
    }
}

// Start fetching after everything is defined
fetchNodes();
setInterval(fetchNodes, 5000);

    // ==========================
    // TOOL ACTIONS
    // ==========================
    async function handleToolAction(nodeId, toolName, action) {
        try {
            const url = `/api/nodes/${nodeId}/tool/${toolName}?action=${action}`;
            const response = await fetch(url, { method: 'POST' });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            console.log(`[Tool] ${toolName} on ${nodeId} - ${action}`, data);
            logActivity(`[Tool] ${toolName} on ${nodeId} - ${action}: ${data.status || data.message}`);
            alert(`${toolName} action: ${data.status || data.message}`);
        } catch (err) {
            const msg = err?.message || String(err);
            console.error(`[Tool] Failed action on ${toolName}:`, msg);
            logActivity(`[Tool] Failed action on ${toolName}: ${msg}`);
        }
    }

    document.querySelectorAll('.tool-action-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const nodeId = btn.dataset.node;
            const toolName = btn.dataset.tool;
            const action = btn.dataset.action || 'status';
            handleToolAction(nodeId, toolName, action);
        });
    });

    // ==========================
    // SIGNALS & MODULATION
    // ==========================
    function initSignalSelectors() {
        const signalSelectors = document.querySelectorAll('.signal-selector');
        signalSelectors.forEach(sel => {
            sel.addEventListener('change', () => {
                const node = sel.dataset.node;
                const band = sel.value;
                updateSignals(node, band);
            });
        });
    }
    async function updateSignals(nodeId, band) {
        try {
            const response = await fetch(`/api/nodes/${nodeId}/tools`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            const container = document.getElementById(`${nodeId}-signals`);
            if (!container) return;
            container.innerHTML = '';
            const tools = data.tools || {};
            Object.keys(tools).forEach(cat => {
                tools[cat].forEach(tool => {
                    const item = document.createElement('div');
                    item.className = 'signal-item';
                    item.innerHTML = `<span>${tool}</span>`;
                    container.appendChild(item);
                });
            });

            logActivity(`Signals updated for node ${nodeId}, band ${band}`);
        } catch (err) {
            const msg = err?.message || String(err);
            console.error(`[Signals] Failed update for node ${nodeId}:`, msg);
            logActivity(`[Signals] Failed update for node ${nodeId}: ${msg}`);
        }
    }

    initSignalSelectors();

    // ==========================
    // PERFORMANCE SUMMARY
    // ==========================
    async function refreshPerformance() {
        try {
            const response = await fetch('/api/performance/summary');
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const data = await response.json();
            const perfEl = document.getElementById('performance-summary');
            if (!perfEl) return;
            perfEl.innerHTML = `
                CPU Avg: ${data.cpu_avg}%<br>
                Memory Avg: ${data.memory_avg}%<br>
                Disk Usage: ${data.disk_usage}%<br>
                Network Throughput: ${data.network_throughput_mbps} Mbps<br>
                Temp Avg: ${data.temperature_avg} °C
            `;
            logActivity('Performance summary updated');
        } catch (err) {
            const msg = err?.message || String(err);
            console.error('[Performance] Failed to refresh:', msg);
            logActivity('[Performance] Refresh failed: ' + msg);
        }
    }
    setInterval(refreshPerformance, 10000);
    refreshPerformance();
    // ==========================
    // INITIALIZE ALL
    // ==========================
    loadHeader();
    initSidebar();
    loadFooter();
    console.log('[Dashboard] Main JS fully initialized');
});

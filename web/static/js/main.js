// ==========================
// HEADER LOADING
// ==========================

function loadHeader() {
    fetch('/header')
        .then(res => {
            if (!res.ok) throw new Error('Header fetch failed');
            return res.text();
        })
        .then(html => {
            const container = document.getElementById('header-container');
            if (!container) return;

            container.innerHTML = html;

            // Ensure DOM + styles are applied before collapse logic
            requestAnimationFrame(() => {
                initNavbarCollapse();
                highlightActiveNav();
            });

        })
        .catch(err => {
            console.error('Header load error:', err);
        });
}

// ==========================
// FOOTER LOADING (PASSIVE)
// ==========================

function loadFooter() {
    const container = document.getElementById('footer-embed-container');
    if (!container) return;

    fetch('/footer')
        .then(res => {
            if (!res.ok) throw new Error('Footer fetch failed');
            return res.text();
        })
        .then(html => {
            container.innerHTML = html;
        })
        .catch(err => {
            console.error('Footer load error:', err);
        });
}

// ==========================
// NAVBAR COLLAPSE (ORIGINAL)
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
// SIDEBAR (UNCHANGED MODEL)
// ==========================

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

    if (pageId === 'sigint') {
        links = [
            { text: 'Airspace Map', href: '#map-section' },
            { text: 'Aircraft List', href: '#aircraft-section' },
            { text: 'Receiver Control', href: '#reciever-control' },
            { text: 'RF Waterfall', href: '#rf-waterfall' },
            { text: 'Receiver Status', href: '#reciever-status' },
            { text: 'Signals Triangulation', href: '#signal-triangulation' },
            { text: 'Triangulation Map', href: '#triangulation-map' }
        ];
    } else if (pageId === 'mesh') {
        links = [
            { text: 'Tactical Map', href: '#tactical-map' },
            { text: 'Send Alerts', href: '#send-alerts' },
            { text: 'Node Status', href: '#node-status' },
            { text: 'Communications Log', href: '#comms-log' }
        ];
    } else if (pageId === 'rf-comms') {
        links = [
            { text: 'Receiver Control', href: '#reciever-control' },
            { text: 'Signal Analysis', href: '#signal-analysis' },
            { text: 'Receiver Status', href: '#reciever-status' },
            { text: 'Digital Data Transfer', href: '#data-transfer' },
            { text: 'RF Propagation Estimator', href: '#propagation-estimation' },
            { text: 'RF Propagation Map', href: '#propagation-map' }
        ];
    } else if (pageId === 'settings') {
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
        ];
    } else if (pageId === 'backup') {
        links = [
            { text: 'Create Backup', href: '#create-backup' },
            { text: 'Available Backups', href: '#available-backups' },
            { text: 'Backup Statistics', href: '#backup-stats' }
        ];
    } else if (pageId === 'dashboard') {
        links = [
            { text: 'Node Status', href: '#node-status' },
            { text: 'Validate Config', href: '#validate-config' },
            { text: 'Health Check', href: '#health' },
            { text: 'Performance Metrics', href: '#performance' },
            { text: 'Emergency Wipe', href: '#data-wipe' },
            { text: 'Reboot Cluster', href: '#reboot-cluster' },
            { text: 'Activity Log', href: '#activity-log' }
        ];
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
// ACTIVE NAV PAGE INDICATOR
// ==========================

function highlightActiveNav() {
    const pageId = document.body.dataset.page;
    if (!pageId) return;

    const navbar = document.getElementById('main-navbar');
    if (!navbar) return;

    // Clear any stale state (safe on reloads)
    navbar
        .querySelectorAll('.active-page')
        .forEach(el => el.classList.remove('active-page'));

    // Match header links using data-page
    const activeLink = navbar.querySelector(
        `[data-page="${pageId}"]`
    );

    if (activeLink) {
        activeLink.classList.add('active-page');
    }
}

// ==========================
// BOOTSTRAP (SAFE & SIMPLE)
// ==========================

document.addEventListener('DOMContentLoaded', () => {
    loadHeader();     // was already working
    initSidebar();    // was already working
    loadFooter();     // passive, cannot break others
});

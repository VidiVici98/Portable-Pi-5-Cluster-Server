// web/static/js/main.js

/**
 * Fetch and insert the header HTML dynamically
 * Ensures navbar exists and collapse behavior works correctly
 */
async function loadHeader() {
    try {
        const response = await fetch('/header'); // Flask route that renders header.html
        if (!response.ok) throw new Error('Network error fetching header');
        const html = await response.text();

        const container = document.getElementById('header-container');
        if (!container) throw new Error('Header container not found');

        // Clear any previous content and insert safely
        container.innerHTML = '';
        container.insertAdjacentHTML('beforeend', html);

        // Wait two frames to ensure browser has fully rendered the DOM and CSS
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                initNavbarCollapse();
            });
        });

    } catch (err) {
        console.error('Failed to load header:', err);
    }
}

/**
 * Original collapse logic, unchanged
 */
function initNavbarCollapse() {
    const navbar = document.querySelector('.navbar');
    if (!navbar) return console.warn('Navbar not found');

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
    checkCollapse(); // initial check in case page is already scrolled
}

// Start everything after DOM is ready
document.addEventListener('DOMContentLoaded', loadHeader);



// web/static/js/main.js

function toggleSidebar() {
    const sidebar = document.getElementById('quick-sidebar');
    sidebar.classList.toggle('expanded');
    sidebar.classList.toggle('collapsed');
}

function populateSidebar(pageId) {
    const sidebarNav = document.querySelector('#quick-sidebar .sidebar-content');
    if (!sidebarNav) return;

    // Clear existing links except the <h4>
    const header = sidebarNav.querySelector('h4');
    sidebarNav.innerHTML = '';
    if (header) sidebarNav.appendChild(header);

    // Page-specific links
    let links = [];
    if (pageId === 'isr') {
        links = [
            { text: 'Airspace Map', href: '#map-section' },
            { text: 'Aircraft List', href: '#aircraft-section' },
            { text: 'RF Waterfall', href: '#' },
            { text: 'Receiver Status', href: '#' },
            { text: 'Signals Triangulation', href: '#' }
        ];
    } else if (pageId === 'mesh') {
        links = [
            { text: 'Tactical Map', href: '#' },
            { text: 'Node Status', href: '#' },
            { text: 'Send Alerts', href: '#' },
            { text: 'Communications Log', href: '#' }
        ];
    } else if (pageId === 'vhf') {
        links = [
            { text: '', href: '#' },
            { text: '', href: '#' },
            { text: '', href: '#' },
            { text: '', href: '#' }
        ];
    } else if (pageId === 'settings') {
        links = [
            { text: 'Deployment Profile', href: '#' },
            { text: 'Power & Hardware', href: '#' },
            { text: 'Failover & Autonomy', href: '#' },
            { text: 'Network & Mesh Behavior', href: '#' },
            { text: 'Security & Access Control', href: '#' },
            { text: 'Network Firewall', href: '#' },
            { text: 'Data Handling & OPSEC', href: '#' },
            { text: 'Secure Data Destruction', href: '#' },
            { text: 'Alerts & Notifications', href: '#' },
            { text: 'Maintenance & Updates', href: '#' },
            { text: 'Auditing & Forensics', href: '#' }
        ];
    } else if (pageId === 'backup') {
        links = [
            { text: 'Create Backup', href: '#' },
            { text: 'Available Backups', href: '#' },
            { text: 'Backup Statistics', href: '#' }
        ];
    }

    links.forEach(link => {
        const a = document.createElement('a');
        a.href = link.href;
        a.textContent = link.text;
        sidebarNav.appendChild(a);
    });
}

// Run after DOM loaded
document.addEventListener('DOMContentLoaded', () => {
    const pageId = document.body.dataset.page; // set per page
    populateSidebar(pageId);
});
function toggleSidebar() {
    const sidebar = document.getElementById('quick-sidebar');
    sidebar.classList.toggle('expanded');
    sidebar.classList.toggle('collapsed');
}

// Sidebar Navigation Logic - Content is embedded, just handle interactions
document.addEventListener('DOMContentLoaded', () => {
    const sidebarContainer = document.getElementById('sidebar-container');
    const overlay = document.getElementById('sidebar-overlay');
    const toggleBtn = document.getElementById('sidebar-toggle');
    const closeBtn = document.getElementById('close-sidebar');

    if (!sidebarContainer || !overlay || !toggleBtn) {
        console.error('Sidebar elements not found');
        return;
    }

    function openSidebar() {
        sidebarContainer.classList.add('open');
        overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    function closeSidebar() {
        sidebarContainer.classList.remove('open');
        overlay.classList.remove('active');
        document.body.style.overflow = '';
    }

    // Toggle button opens sidebar
    toggleBtn.addEventListener('click', openSidebar);

    // Close button
    if (closeBtn) {
        closeBtn.addEventListener('click', closeSidebar);
    }

    // Overlay click closes
    overlay.addEventListener('click', closeSidebar);

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && sidebarContainer.classList.contains('open')) {
            closeSidebar();
        }
    });

    // Close sidebar when clicking a link (better mobile UX)
    sidebarContainer.querySelectorAll('a').forEach(link => {
        link.addEventListener('click', closeSidebar);
    });

    // --- Deploy symbol indicator ---
    // Insert a small symbol element next to the hamburger to show latest deploy/push marker.
    try {
        const symbolEl = document.createElement('span');
        symbolEl.id = 'deploy-symbol';
        symbolEl.setAttribute('aria-hidden', 'true');
        symbolEl.style.marginLeft = '8px';
        symbolEl.style.fontSize = '1.1rem';
        symbolEl.style.lineHeight = '1';
        symbolEl.style.display = 'inline-block';
        symbolEl.textContent = '•'; // fallback
        // Place after toggle button
        toggleBtn.insertAdjacentElement('afterend', symbolEl);

        // Try fetching deploy_symbol.json from several candidate root-relative paths
        (async function fetchSymbol() {
            const candidates = [
                '/deploy_symbol.json',
                'deploy_symbol.json',
                '../deploy_symbol.json',
                '../../deploy_symbol.json',
                '../../../deploy_symbol.json'
            ];
            for (const p of candidates) {
                try {
                    const resp = await fetch(p, {cache: 'no-cache'});
                    if (!resp.ok) continue;
                    const j = await resp.json();
                    if (j && j.symbol) {
                        symbolEl.textContent = j.symbol;
                        symbolEl.title = j.message ? j.message : `Deploy symbol: ${j.symbol}`;
                        return;
                    }
                } catch (e) {
                    // ignore and try next
                }
            }
        })();
    } catch (e) {
        console.error('Failed to add deploy symbol', e);
    }

    // Also add a prominent deploy symbol next to the site title for clear visibility
    try {
        const headerTitle = document.querySelector('header h1');
        if (headerTitle) {
            const topSymbol = document.createElement('span');
            topSymbol.id = 'deploy-symbol-top';
            topSymbol.setAttribute('aria-hidden', 'true');
            topSymbol.style.marginLeft = '12px';
            topSymbol.style.fontSize = '1.6rem';
            topSymbol.style.lineHeight = '1';
            topSymbol.style.display = 'inline-block';
            topSymbol.style.padding = '2px 6px';
            topSymbol.style.borderRadius = '6px';
            topSymbol.style.background = 'rgba(212,175,55,0.12)';
            topSymbol.style.color = 'var(--primary-deep-blue)';
            topSymbol.style.fontWeight = '700';
            topSymbol.textContent = '⬤'; // fallback
            headerTitle.insertAdjacentElement('afterend', topSymbol);

            (async function fetchTopSymbol() {
                const candidates = [
                    '/deploy_symbol.json',
                    'deploy_symbol.json',
                    '../deploy_symbol.json',
                    '../../deploy_symbol.json',
                    '../../../deploy_symbol.json'
                ];
                for (const p of candidates) {
                    try {
                        const resp = await fetch(p, {cache: 'no-cache'});
                        if (!resp.ok) continue;
                        const j = await resp.json();
                        if (j && j.symbol) {
                            topSymbol.textContent = j.symbol;
                            topSymbol.title = j.message ? j.message : `Deploy symbol: ${j.symbol}`;
                            return;
                        }
                    } catch (e) {
                        // ignore and try next
                    }
                }
            })();
        }
    } catch (e) {
        console.error('Failed to add top deploy symbol', e);
    }
});

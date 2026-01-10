// Bookmarks & Progress Tracking
document.addEventListener('DOMContentLoaded', () => {
    const STORAGE_KEY = 'tboi_bookmarks';
    const LAST_PAGE_KEY = 'tboi_last_page';

    // Save current page as last visited
    saveLastVisited();

    // Create bookmark button dynamically
    const header = document.querySelector('header');
    if (!header) return;

    // Create bookmarks panel
    createBookmarksPanel();

    // Create bookmark toggle button
    let bookmarkBtn = document.getElementById('bookmark-toggle');
    if (!bookmarkBtn) {
        bookmarkBtn = document.createElement('button');
        bookmarkBtn.id = 'bookmark-toggle';
        bookmarkBtn.textContent = '🔖';
        bookmarkBtn.setAttribute('aria-label', 'Bookmarks');

        const themeBtn = document.getElementById('theme-toggle');
        if (themeBtn) {
            header.insertBefore(bookmarkBtn, themeBtn);
        } else {
            header.appendChild(bookmarkBtn);
        }
    }

    // Check if current page is bookmarked
    updateBookmarkButtonState();

    // Click handler - toggle bookmark for current page
    bookmarkBtn.addEventListener('click', (e) => {
        if (e.shiftKey) {
            // Shift+click opens panel
            openBookmarksPanel();
        } else {
            toggleBookmark();
        }
    });

    // Double-click opens panel
    bookmarkBtn.addEventListener('dblclick', () => {
        openBookmarksPanel();
    });

    function getBookmarks() {
        try {
            return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
        } catch {
            return [];
        }
    }

    function saveBookmarks(bookmarks) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(bookmarks));
    }

    function getCurrentPageInfo() {
        const title = document.querySelector('.content-card h3')?.textContent ||
            document.querySelector('h2')?.textContent ||
            document.title;
        const url = window.location.pathname;
        const subtitle = document.querySelector('.subtitle')?.textContent || '';
        return { title, url, subtitle, timestamp: Date.now() };
    }

    function isCurrentPageBookmarked() {
        const bookmarks = getBookmarks();
        const currentUrl = window.location.pathname;
        return bookmarks.some(b => b.url === currentUrl);
    }

    function toggleBookmark() {
        const bookmarks = getBookmarks();
        const currentUrl = window.location.pathname;
        const existingIndex = bookmarks.findIndex(b => b.url === currentUrl);

        if (existingIndex >= 0) {
            bookmarks.splice(existingIndex, 1);
        } else {
            bookmarks.unshift(getCurrentPageInfo());
        }

        saveBookmarks(bookmarks);
        updateBookmarkButtonState();
        renderBookmarksList();
    }

    function updateBookmarkButtonState() {
        const btn = document.getElementById('bookmark-toggle');
        if (btn) {
            if (isCurrentPageBookmarked()) {
                btn.classList.add('bookmarked');
                btn.textContent = '⭐';
            } else {
                btn.classList.remove('bookmarked');
                btn.textContent = '🔖';
            }
        }
    }

    function saveLastVisited() {
        const pageInfo = getCurrentPageInfo();
        localStorage.setItem(LAST_PAGE_KEY, JSON.stringify(pageInfo));
    }

    function getLastVisited() {
        try {
            return JSON.parse(localStorage.getItem(LAST_PAGE_KEY));
        } catch {
            return null;
        }
    }

    function createBookmarksPanel() {
        if (document.getElementById('bookmarks-panel')) return;

        const panel = document.createElement('div');
        panel.id = 'bookmarks-panel';
        panel.innerHTML = `
            <div class="bookmarks-header">
                <h3>📚 Bookmarks</h3>
                <button id="close-bookmarks">×</button>
            </div>
            <div class="bookmarks-list"></div>
            <div class="resume-reading"></div>
        `;
        document.body.appendChild(panel);

        // Also create overlay for bookmarks
        const overlay = document.createElement('div');
        overlay.id = 'bookmarks-overlay';
        overlay.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
            background: rgba(0,0,0,0.5); z-index: 4998; display: none;
        `;
        document.body.appendChild(overlay);

        // Close handlers
        document.getElementById('close-bookmarks').addEventListener('click', closeBookmarksPanel);
        overlay.addEventListener('click', closeBookmarksPanel);

        renderBookmarksList();
    }

    function openBookmarksPanel() {
        const panel = document.getElementById('bookmarks-panel');
        const overlay = document.getElementById('bookmarks-overlay');
        if (panel) {
            panel.classList.add('open');
            overlay.style.display = 'block';
            renderBookmarksList();
        }
    }

    function closeBookmarksPanel() {
        const panel = document.getElementById('bookmarks-panel');
        const overlay = document.getElementById('bookmarks-overlay');
        if (panel) {
            panel.classList.remove('open');
            overlay.style.display = 'none';
        }
    }

    function renderBookmarksList() {
        const listEl = document.querySelector('.bookmarks-list');
        const resumeEl = document.querySelector('.resume-reading');
        if (!listEl) return;

        const bookmarks = getBookmarks();
        const lastVisited = getLastVisited();

        // Determine root path
        let rootPath = '';
        const pathSegments = window.location.pathname.split('/');
        if (pathSegments.includes('parts')) {
            rootPath = '../../../';
            if (window.location.pathname.endsWith('index.html') &&
                pathSegments[pathSegments.length - 2].startsWith('part_')) {
                rootPath = '../../';
            }
        }

        if (bookmarks.length === 0) {
            listEl.innerHTML = '<p style="color:#999; text-align:center; padding:2rem;">No bookmarks yet.<br>Click the bookmark icon to save pages.</p>';
        } else {
            listEl.innerHTML = bookmarks.map((b, i) => `
                <div class="bookmark-item">
                    <a href="${rootPath}${b.url.replace(/^\//, '')}">${b.title}</a>
                    <button class="remove-bookmark" data-index="${i}">×</button>
                </div>
            `).join('');

            // Attach remove handlers
            listEl.querySelectorAll('.remove-bookmark').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    const idx = parseInt(btn.dataset.index);
                    const bks = getBookmarks();
                    bks.splice(idx, 1);
                    saveBookmarks(bks);
                    updateBookmarkButtonState();
                    renderBookmarksList();
                });
            });
        }

        // Resume reading section
        if (lastVisited && lastVisited.url !== window.location.pathname) {
            resumeEl.innerHTML = `
                <small style="display:block; margin-bottom:0.5rem; color:#666;">Continue where you left off:</small>
                <a href="${rootPath}${lastVisited.url.replace(/^\//, '')}">${lastVisited.title}</a>
            `;
            resumeEl.style.display = 'block';
        } else {
            resumeEl.style.display = 'none';
        }
    }
});

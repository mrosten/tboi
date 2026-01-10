// Sidebar Navigation Logic

document.addEventListener('DOMContentLoaded', () => {
    const sidebarContainer = document.getElementById('sidebar-container');
    const overlay = document.getElementById('sidebar-overlay');
    const toggleBtn = document.getElementById('sidebar-toggle');

    // Determine path to root relative to current page
    // We can count the number of "../" required based on nesting
    // Or simpler: The sidebar_content.html is at root. 
    // From parts/part_i/chapter_01/section.html, structure is 3 levels deep.
    // We assume standard structure: root -> parts -> part_X -> chapter_Y -> section.html

    let rootPath = '';
    const pathSegments = window.location.pathname.split('/');
    // Check if we are in 'parts'
    if (pathSegments.includes('parts')) {
        rootPath = '../../../'; // Go up 3 levels from section.html
        if (window.location.pathname.endsWith('index.html') && pathSegments[pathSegments.length - 2].startsWith('part_')) {
            // In Part Index: parts/part_i/index.html -> 2 levels deep
            rootPath = '../../';
        }
        if (window.location.pathname.endsWith('index.html') && pathSegments[pathSegments.length - 2] === 'parts') {
            // In Parts Index (if exists): parts/index.html -> 1 level deep
            rootPath = '../';
        }
    }

    // Fetch and inject sidebar
    fetch(rootPath + 'sidebar_content.html')
        .then(response => {
            if (!response.ok) throw new Error("Sidebar not found");
            return response.text();
        })
        .then(html => {
            sidebarContainer.innerHTML = html;
            setupSidebarInteractions(rootPath);
        })
        .catch(err => console.error('Error loading sidebar:', err));

    // Interactions
    function setupSidebarInteractions(rootPath) {
        const closeBtn = document.getElementById('close-sidebar');

        // Fix links
        const links = sidebarContainer.querySelectorAll('a');
        links.forEach(link => {
            const rawPath = link.getAttribute('data-path');
            if (rawPath) {
                link.href = rootPath + rawPath;
            }
        });

        // Open
        toggleBtn.addEventListener('click', () => {
            sidebarContainer.classList.add('open');
            overlay.classList.add('active');
            document.body.style.overflow = 'hidden'; // Prevent body scroll
        });

        // Close
        function closeSidebar() {
            sidebarContainer.classList.remove('open');
            overlay.classList.remove('active');
            document.body.style.overflow = '';
        }

        closeBtn.addEventListener('click', closeSidebar);
        overlay.addEventListener('click', closeSidebar);

        // Close on link click (mobile UX)
        links.forEach(link => {
            link.addEventListener('click', closeSidebar);
        });
    }
});

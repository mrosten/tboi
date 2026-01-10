document.addEventListener('DOMContentLoaded', () => {
    const searchToggle = document.getElementById('search-toggle');
    const searchModal = document.getElementById('search-modal');
    const searchInput = document.getElementById('search-input');
    const searchResults = document.getElementById('search-results');
    const backdrop = document.querySelector('.search-backdrop');

    let searchIndex = [];
    let isLoaded = false;

    // Determine root path for fetching json
    let rootPath = '';
    const pathSegments = window.location.pathname.split('/');
    if (pathSegments.includes('parts')) {
        rootPath = '../../../';
        if (window.location.pathname.endsWith('index.html') && pathSegments[pathSegments.length - 2].startsWith('part_')) {
            rootPath = '../../';
        }
    }

    // Open Search
    if (searchToggle) {
        searchToggle.addEventListener('click', async () => {
            searchModal.style.display = 'block';
            searchInput.focus();

            if (!isLoaded) {
                try {
                    const response = await fetch(rootPath + 'search_index.json');
                    searchIndex = await response.json();
                    isLoaded = true;
                } catch (e) {
                    console.error("Failed to load search index", e);
                    searchResults.innerHTML = "<p>Error loading search data.</p>";
                }
            }
        });
    }

    // Close Search
    if (backdrop) {
        backdrop.addEventListener('click', () => {
            searchModal.style.display = 'none';
        });
    }

    // Search Logic
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        if (query.length < 2) {
            searchResults.innerHTML = '';
            return;
        }

        const results = searchIndex.filter(item =>
            item.title.toLowerCase().includes(query) ||
            (item.content && item.content.toLowerCase().includes(query))
        ).slice(0, 10); // Limit 10 results

        // Render
        if (results.length === 0) {
            searchResults.innerHTML = '<p class="no-results">No results found.</p>';
        } else {
            searchResults.innerHTML = results.map(item => {
                // Snippet generation
                let snippet = '';
                if (item.content) {
                    const idx = item.content.toLowerCase().indexOf(query);
                    const start = Math.max(0, idx - 40);
                    const end = Math.min(item.content.length, idx + 100);
                    snippet = item.content.substring(start, end) + '...';
                    // Highlight
                    snippet = snippet.replace(new RegExp(query, 'gi'), match => `<mark>${match}</mark>`);
                }

                return `
                <div class="search-result-item">
                    <a href="${rootPath}${item.url}">
                        <strong>${item.title}</strong>
                        <span class="result-path">${item.part} > ${item.chapter}</span>
                        <p>${snippet}</p>
                    </a>
                </div>`;
            }).join('');
        }
    });
});

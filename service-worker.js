// Bump this value to force clients to update cached site assets when we deploy fixes
const CACHE_NAME = 'tboi-v2';
const ASSETS_TO_CACHE = [
    './',
    'index.html',
    'styles.css',
    'sidebar.js',
    'search.js',
    'glossary_tooltip.js',
    'audio.js',
    'bookmarks.js',
    'breadcrumb_mobile.js',
    'images/icon-192.png',
    'images/icon-512.png'
];

// Install event: Cache core assets
self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Opened cache');
                return cache.addAll(ASSETS_TO_CACHE);
            })
    );
});

// Activate event: Clean up old caches
self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames.map(cacheName => {
                    if (cacheName !== CACHE_NAME) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});

// Fetch event: Network first, fall back to cache for HTML; Cache first for assets
self.addEventListener('fetch', event => {
    const url = new URL(event.request.url);

    // For HTML pages: Stale-While-Revalidate (or Network First)
    // We want the user to see the latest content if possible, but work offline
    if (event.request.headers.get('accept').includes('text/html')) {
        event.respondWith(
            fetch(event.request)
                .then(response => {
                    // Update cache for next time
                    const responseClone = response.clone();
                    caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, responseClone);
                    });
                    return response;
                })
                .catch(() => {
                    // Network failed, try cache
                    return caches.match(event.request);
                })
        );
    } else {
        // For static assets (CSS, JS, images): Cache First
        event.respondWith(
            caches.match(event.request)
                .then(response => {
                    if (response) {
                        return response;
                    }
                    return fetch(event.request).then(response => {
                        // Cache new assets on the fly
                        if (!response || response.status !== 200 || response.type !== 'basic') {
                            return response;
                        }
                        const responseClone = response.clone();
                        caches.open(CACHE_NAME).then(cache => {
                            cache.put(event.request, responseClone);
                        });
                        return response;
                    });
                })
        );
    }
});

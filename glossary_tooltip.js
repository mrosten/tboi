// Glossary Tooltips
document.addEventListener('DOMContentLoaded', () => {
    // Determine root path
    let rootPath = '';
    const pathSegments = window.location.pathname.split('/');
    if (pathSegments.includes('parts')) {
        rootPath = '../../../';
        if (window.location.pathname.endsWith('index.html') && pathSegments[pathSegments.length - 2].startsWith('part_')) rootPath = '../../';
    }

    fetch(rootPath + 'glossary_terms.json')
        .then(res => res.json())
        .then(termsData => {
            // termsData is { "Term": "Definition" } or Array? The python script generates a Dict.
            // Let's inspect format_glossary.py output structure... assuming it's { "Term": "Def" }
            highlightTerms(termsData);
        })
        .catch(err => console.log('No glossary terms found'));

    function highlightTerms(terms) {
        const content = document.querySelector('.content-card');
        if (!content) return;

        // Sort terms by length (descending) to prevent "Te" matching inside "Test" improperly if "Test" is also a term
        const sortedTerms = Object.keys(terms).sort((a, b) => b.length - a.length);
        if (sortedTerms.length === 0) return;

        // Create a regex - Use word boundaries \b
        // Escape regex special chars in terms
        const escapedTerms = sortedTerms.map(t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
        const regex = new RegExp(`\\b(${escapedTerms.join('|')})\\b`, 'gi');

        // Traverse text nodes
        const walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, null, false);
        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            // Skip if inside existing links or headers if desired, but glossary can be anywhere
            if (node.parentElement.tagName === 'A' ||
                node.parentElement.tagName === 'H1' ||
                node.parentElement.tagName === 'H2' ||
                node.parentElement.classList.contains('glossary-term')) continue;
            textNodes.push(node);
        }

        textNodes.forEach(textNode => {
            const text = textNode.nodeValue;
            if (!regex.test(text)) return;

            // Reset regex lastIndex
            regex.lastIndex = 0;

            const matches = text.match(regex);
            if (!matches) return;

            // Replacement
            const fragment = document.createDocumentFragment();
            let lastIndex = 0;

            // Re-run regex to find positions (matchAll would be better but keeping it simple/compatible)
            // Actually, we can just split? No, we need the matches.
            // Let's use string replacement methodology with a temp wrapper
            // But we can't inject HTML into textNode. We must replace textNode.

            const div = document.createElement('div');
            div.innerHTML = text.replace(regex, (match) => {
                // Find exact original casing match to lookup definition?
                // The key in JSON is the Title Cased version.
                // We need to find the key that matches 'match' case-insensitively
                const key = sortedTerms.find(t => t.toLowerCase() === match.toLowerCase());
                const def = terms[key] || "";
                // Truncate def for tooltip?
                const shortDef = def.length > 200 ? def.substring(0, 197) + "..." : def;
                return `<span class="glossary-term" data-tooltip="${shortDef.replace(/"/g, '&quot;')}">${match}</span>`;
            });

            while (div.firstChild) {
                fragment.appendChild(div.firstChild);
            }
            textNode.parentNode.replaceChild(fragment, textNode);
        });

        setupTooltipUI();
    }

    function setupTooltipUI() {
        const tooltip = document.createElement('div');
        tooltip.id = 'glossary-tooltip';
        document.body.appendChild(tooltip);

        document.querySelectorAll('.glossary-term').forEach(term => {
            term.addEventListener('mouseenter', (e) => {
                tooltip.textContent = term.getAttribute('data-tooltip');
                tooltip.classList.add('visible');
                positionTooltip(e.target, tooltip);
            });

            term.addEventListener('mouseleave', () => {
                tooltip.classList.remove('visible');
            });
        });
    }

    function positionTooltip(target, tooltip) {
        const rect = target.getBoundingClientRect();
        const tooltipRect = tooltip.getBoundingClientRect();

        let top = rect.bottom + 5;
        let left = rect.left + (rect.width / 2) - (tooltipRect.width / 2);

        // Bounds check
        if (left < 10) left = 10;
        if (left + tooltipRect.width > window.innerWidth - 10) left = window.innerWidth - 10 - tooltipRect.width;

        tooltip.style.top = `${top + window.scrollY}px`;
        tooltip.style.left = `${left}px`;
    }
});

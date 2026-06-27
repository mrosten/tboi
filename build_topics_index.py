import os
import json
import re

# Paths
script_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = script_dir
split_book_path = os.path.join(base_dir, "split_book")
split_book_he_path = os.path.join(base_dir, "split_book_he")
topics_json_path = os.path.join(split_book_path, "topics_data.json")

# Part targets mapping to Source directories (English)
part_mappings_en = [
    {"source": "part_i-Philosophy and Faith", "target": "part_i", "title": "Part I — Philosophy and Faith"},
    {"source": "part_ii-Halachah", "target": "part_ii", "title": "Part II — Halachah"},
    {"source": "part_iii-life", "target": "part_iii_life", "title": "Part III — Life"},
    {"source": "part_iv-politics", "target": "part_iv_politics", "title": "Part IV — Politics"},
    {"source": "part_v-ideas", "target": "part_v_ideas", "title": "Part V — Ideas"},
    {"source": "part_vi-christianity", "target": "part_vi_christianity", "title": "Part VI — Christianity"}
]

# Part targets mapping to Source directories (Hebrew)
part_mappings_he = [
    {"source": "part_i-Philosophy and Faith", "target": "part_i", "title": "חלק א — פילוסופיה ואמונה"},
    {"source": "part_ii-Halachah", "target": "part_ii", "title": "חלק ב — הלכה"},
    {"source": "part_iii-life", "target": "part_iii_life", "title": "חלק ג — חיים"},
    {"source": "part_iv-politics", "target": "part_iv_politics", "title": "חלק ד — פוליטיקה"},
    {"source": "part_v-ideas", "target": "part_v_ideas", "title": "חלק ה — רעיונות"},
    {"source": "part_vi-christianity", "target": "part_vi_christianity", "title": "חלק ו — נצרות"}
]

roman_numerals = {
    'i': 'I', 'ii': 'II', 'iii': 'III', 'iv': 'IV', 'v': 'V',
    'vi': 'VI', 'vii': 'VII', 'viii': 'VIII', 'ix': 'IX', 'x': 'X',
    'xi': 'XI', 'xii': 'XII', 'xiii': 'XIII', 'xiv': 'XIV', 'xv': 'XV',
    'xvi': 'XVI', 'xvii': 'XVII', 'xviii': 'XVIII', 'xix': 'XIX', 'xx': 'XX'
}

def load_topics():
    with open(topics_json_path, 'r', encoding='utf-8') as f:
        return json.load(f)

def clean_text_for_search(text):
    # Remove spacing and standard punctuation for more reliable matching
    return re.sub(r'\s+', ' ', text).lower()

def extract_section_title(file_content, default_title):
    match = re.search(r'\[TITLE:\s*(.*?)\]', file_content)
    if match:
        return match.group(1).strip()
    return default_title

def scan_text_files(split_path, part_mappings, lang):
    sections_db = []
    
    for part in part_mappings:
        part_dir = os.path.join(split_path, part["source"])
        if not os.path.exists(part_dir):
            continue
            
        # Get chapter directories
        chapter_dirs = sorted([d for d in os.listdir(part_dir) if os.path.isdir(os.path.join(part_dir, d)) and d.startswith("chapter_")])
        for ch_dir in chapter_dirs:
            ch_path = os.path.join(part_dir, ch_dir)
            ch_num_match = re.match(r'chapter_(\d+)', ch_dir)
            ch_num = ch_num_match.group(1) if ch_num_match else "00"
            
            # Retrieve clean chapter name
            ch_title_raw = ch_dir.replace(f"chapter_{ch_num}-", "").replace("-", " ").strip()
            ch_title_raw = ch_title_raw.title()
            
            # Section text files
            sec_files = sorted([f for f in os.listdir(ch_path) if f.startswith("section_") and f.endswith(".txt")])
            for sec_file in sec_files:
                sec_num_match = re.match(r'section_([ivx]+)\.txt', sec_file)
                sec_num_roman = sec_num_match.group(1) if sec_num_match else "i"
                sec_num = roman_numerals.get(sec_num_roman, sec_num_roman.upper())
                
                sec_filepath = os.path.join(ch_path, sec_file)
                with open(sec_filepath, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                
                default_title = f"Section {sec_num}" if lang == 'en' else f"סעיף {sec_num}"
                sec_title = extract_section_title(content, default_title)
                
                # HTML url path
                html_filename = sec_file.replace(".txt", ".html")
                html_url = f"parts/{part['target']}/{ch_dir.split('-')[0]}/{html_filename}"
                
                sections_db.append({
                    "part_title": part["title"],
                    "chapter_title": f"Chapter {int(ch_num)}" if lang == 'en' else f"פרק {int(ch_num)}",
                    "section_num": sec_num,
                    "section_title": sec_title,
                    "url": html_url,
                    "clean_content": clean_text_for_search(content)
                })
                
    return sections_db

def build_index(topics, sections_db, lang):
    indexed_topics = []
    
    for topic in topics:
        keys = topic["search_keys"] if lang == 'en' else topic["search_keys_he"]
        term = topic["term"] if lang == 'en' else topic["term_he"]
        essay = topic["essay"] if lang == 'en' else topic["essay_he"]
        
        references = []
        for sec in sections_db:
            # Check if any search key appears in the section content
            matched = False
            for key in keys:
                # Use regex with boundary to match whole words/phrases
                escaped_key = re.escape(key.lower())
                # For Hebrew, boundary \b might not work perfectly, so simple sub-string is safer, or check boundaries manually
                if lang == 'he':
                    if escaped_key in sec["clean_content"]:
                        matched = True
                        break
                else:
                    if re.search(r'\b' + escaped_key + r'\b', sec["clean_content"]):
                        matched = True
                        break
                        
            if matched:
                ref_title = f"{sec['part_title']}, {sec['chapter_title']}, {sec['section_title']}"
                references.append({
                    "title": ref_title,
                    "url": sec["url"]
                })
        
        # Determine sorting key
        sort_key = term.lower()
        first_letter = sort_key[0].upper() if sort_key else "A"
        
        indexed_topics.append({
            "id": topic["id"],
            "term": term,
            "essay": essay,
            "references": references,
            "first_letter": first_letter,
            "sort_key": sort_key
        })
        
    return sorted(indexed_topics, key=lambda x: x["sort_key"])

def generate_html_page(indexed_topics, sidebar_html, lang):
    # Localization values
    loc = {
        'en': {
            'title': 'Index of Topics — The Torah Book of Ideas',
            'header_title': 'The Torah Book of Ideas',
            'subtitle': 'Index of Topics',
            'home': 'Home',
            'contents': 'Table of Contents',
            'search': 'Search',
            'lang_toggle': 'HE',
            'lang_label': 'Switch to Hebrew',
            'footer': 'The Torah Book of Ideas — A journey through wisdom, faith, and understanding',
            'search_placeholder': 'Search index...',
            'discussed_in': 'Discussed in:',
            'dir': 'ltr',
            'lang_code': 'en',
            'no_results': 'No matching terms found.'
        },
        'he': {
            'title': 'אינדקס נושאים — ספר הרעיונות של התורה',
            'header_title': 'ספר הרעיונות של התורה',
            'subtitle': 'מפתח נושאים',
            'home': 'בית',
            'contents': 'תוכן העניינים',
            'search': 'חיפוש',
            'lang_toggle': 'עב',
            'lang_label': 'Switch to English',
            'footer': 'ספר הרעיונות של התורה — מסע דרך חוכמה, אמונה והבנה',
            'search_placeholder': 'חפש במפתח...',
            'discussed_in': 'מוזכר ב:',
            'dir': 'rtl',
            'lang_code': 'he',
            'no_results': 'לא נמצאו נושאים מתאימים.'
        }
    }[lang]
    
    # Generate A-Z index navigation
    letters = sorted(list(set(t["first_letter"] for t in indexed_topics)))
    az_nav_items = []
    for letter in letters:
        az_nav_items.append(f'<a href="#letter-{letter}" style="margin: 0 0.5rem; text-decoration: none; color: var(--primary-royal-blue); font-weight: bold; font-size: 1.1rem;">{letter}</a>')
    az_nav_html = f'<div style="text-align: center; margin-bottom: 2rem; padding: 0.5rem; background: var(--background-parchment); border-radius: 8px; border: 1px solid var(--border-ornate);">{" | ".join(az_nav_items)}</div>'
    
    # Generate cards grouped by letter
    cards_html = []
    current_letter = None
    
    for topic in indexed_topics:
        if topic["first_letter"] != current_letter:
            if current_letter is not None:
                cards_html.append('</div><!-- close previous alphabet-group -->')
            current_letter = topic["first_letter"]
            cards_html.append(f'<div class="alphabet-group" id="letter-{current_letter}">')
            cards_html.append(f'<h3 style="font-family: var(--font-heading); color: var(--accent-gold); font-size: 1.8rem; margin: 1.5rem 0 0.8rem 0; border-bottom: 2px solid var(--accent-gold); padding-bottom: 0.3rem;">{current_letter}</h3>')
            
        ref_items = []
        for ref in topic["references"]:
            ref_items.append(f'<li style="margin-bottom: 0.4rem; font-family: var(--font-body);"><a href="{ref["url"]}" style="color: var(--primary-royal-blue); text-decoration: none; font-weight: 500; transition: color 0.2s;">{ref["title"]}</a></li>')
            
        ref_list_html = ""
        if ref_items:
            ref_list_html = f'''
            <div class="topic-references" style="margin-top: 1rem; border-top: 1px dashed var(--border-ornate); padding-top: 0.8rem;">
                <h4 style="font-family: var(--font-heading); font-size: 1rem; color: var(--text-medium); margin-bottom: 0.4rem;">{loc['discussed_in']}</h4>
                <ul style="list-style-type: square; padding-left: 1.2rem; margin-bottom: 0;">
                    {"".join(ref_items)}
                </ul>
            </div>
            '''
        
        essay_html = ""
        if topic["essay"]:
            essay_html = f'<p class="topic-essay" style="color: var(--text-dark); line-height: 1.7; font-size: 1.05rem; margin-bottom: 0.5rem; text-align: justify; font-family: var(--font-body);">{topic["essay"]}</p>'
            
        cards_html.append(f'''
        <div class="topic-card" id="topic-{topic['id']}" data-term="{topic['term'].lower()}" style="background: var(--background-parchment); border-left: 4px solid var(--accent-gold); padding: 1.5rem; margin-bottom: 1.5rem; border-radius: 8px; box-shadow: var(--shadow-soft); transition: transform 0.2s ease, box-shadow 0.2s ease;">
            <h4 style="font-family: var(--font-heading); color: var(--primary-deep-blue); font-size: 1.4rem; margin-top: 0; margin-bottom: 0.8rem; font-weight: bold;">{topic['term']}</h4>
            {essay_html}
            {ref_list_html}
        </div>
        ''')
        
    if current_letter is not None:
        cards_html.append('</div><!-- close last alphabet-group -->')
        
    # Generate Glance links
    glance_items = []
    for topic in indexed_topics:
        glance_items.append(f'<a href="#topic-{topic["id"]}" class="glance-link" data-term="{topic["term"].lower()}" style="color: var(--primary-royal-blue); text-decoration: none; font-family: var(--font-body); font-weight: 500; font-size: 0.95rem; padding: 0.3rem 0.5rem; background: rgba(0,0,0,0.02); border-radius: 4px; border: 1px solid rgba(0,0,0,0.05); transition: background 0.2s, color 0.2s, border-color 0.2s; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; text-align: center;">{topic["term"]}</a>')
        
    glance_title = "Index at a Glance" if lang == "en" else "מפתח במבט מהיר"
    glance_html = f'''
        <div style="margin-bottom: 2rem; border-top: 1px dashed var(--border-ornate); padding-top: 1.5rem;">
            <h4 style="font-family: var(--font-heading); color: var(--text-medium); margin-top: 0; margin-bottom: 0.8rem; font-size: 1.1rem; text-align: center;">✡ {glance_title} ✡</h4>
            <div class="index-glance-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 0.5rem; max-height: 250px; overflow-y: auto; padding: 0.5rem; border: 1px solid rgba(0,0,0,0.1); border-radius: 6px; background: rgba(0,0,0,0.01);">
                {"".join(glance_items)}
            </div>
        </div>
    '''
        
    main_content = f'''
    <div class="content-card">
        <h2 style="font-family: var(--font-heading); text-align: center; color: var(--primary-deep-blue); margin-bottom: 1.5rem;">✡ {loc['subtitle']} ✡</h2>
        
        <div class="search-box-container" style="margin-bottom: 2rem; position: relative;">
            <input type="text" id="topic-search-input" placeholder="{loc['search_placeholder']}" style="width: 100%; padding: 0.8rem 1.2rem; font-size: 1.1rem; border: 2px solid var(--accent-gold); border-radius: 8px; background-color: var(--background-parchment); color: var(--text-dark); font-family: var(--font-body); box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);">
        </div>
        
        {glance_html}
        
        {az_nav_html}
        
        <div id="topics-list-container">
            {"".join(cards_html)}
            <div id="no-results-message" style="display: none; text-align: center; padding: 2rem; color: var(--text-medium); font-size: 1.2rem; font-style: italic;">
                {loc['no_results']}
            </div>
        </div>
    </div>
    '''
    
    asset_depth = "../" if lang == 'he' else ""
    
    # Complete HTML Page
    html = f'''<!DOCTYPE html>
<html lang="{loc['lang_code']}" dir="{loc['dir']}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{loc['title']}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="{asset_depth}manifest.json">
    <link rel="stylesheet" href="{asset_depth}styles.css">
    <style>
        .topic-card:hover {{
            transform: translateY(-3px);
            box-shadow: var(--shadow-medium), var(--shadow-gold) !important;
            border-left-color: var(--accent-gold-light) !important;
        }}
        .topic-references a:hover {{
            color: var(--accent-gold) !important;
            text-decoration: underline !important;
        }}
        .glance-link:hover {{
            background-color: var(--accent-gold) !important;
            color: var(--text-dark) !important;
            border-color: var(--accent-gold) !important;
        }}
    </style>
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">{sidebar_html}</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="search.html" id="search-link" aria-label="{loc['search']}" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="Toggle Dark Mode">🌙</button>
        <button id="lang-toggle" aria-label="{loc['lang_label']}">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">{loc['lang_toggle']}</span>
        </button>
        <h1>{loc['header_title']}</h1>
        <p class="subtitle">{loc['subtitle']}</p>
    </header>
    <nav>
        <a href="index.html">{loc['home']}</a>
        <a href="contents.html">{loc['contents']}</a>
        <a href="topics.html" class="active">{loc['subtitle']}</a>
    </nav>
    <main class="container">
        {main_content}
    </main>
    <footer>
        <p>{loc['footer']}</p>
    </footer>
    <script src="{asset_depth}sidebar.js"></script>
    <script src="{asset_depth}search.js"></script>
    <script src="{asset_depth}language_toggle.js"></script>
    <script src="{asset_depth}audio.js"></script>
    <script src="{asset_depth}bookmarks.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {{
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        }} else {{
            toggleBtn.textContent = '🌙';
        }}
        toggleBtn.addEventListener('click', () => {{
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {{
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            }} else {{
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }}
        }});

        // Real-time client-side search filtering
        document.getElementById('topic-search-input').addEventListener('input', function(e) {{
            const query = e.target.value.toLowerCase().trim();
            let visibleCardsCount = 0;
            
            // Filter Glance links
            document.querySelectorAll('.glance-link').forEach(link => {{
                const term = link.getAttribute('data-term').toLowerCase();
                if (term.includes(query)) {{
                    link.style.display = 'inline-block';
                }} else {{
                    link.style.display = 'none';
                }}
            }});

            // Filter Topic cards
            document.querySelectorAll('.topic-card').forEach(card => {{
                const term = card.getAttribute('data-term').toLowerCase();
                const essay = card.querySelector('.topic-essay') ? card.querySelector('.topic-essay').textContent.toLowerCase() : '';
                if (term.includes(query) || essay.includes(query)) {{
                    card.style.display = 'block';
                    visibleCardsCount++;
                }} else {{
                    card.style.display = 'none';
                }}
            }});
            
            // Hide alphabet headers if no cards under them are visible
            document.querySelectorAll('.alphabet-group').forEach(group => {{
                const visibleCards = group.querySelectorAll('.topic-card[style="display: block;"], .topic-card:not([style*="display: none"])');
                if (visibleCards.length === 0) {{
                    group.style.display = 'none';
                }} else {{
                    group.style.display = 'block';
                }}
            }});
            
            // Show no results message if needed
            const noResultsMsg = document.getElementById('no-results-message');
            if (visibleCardsCount === 0) {{
                noResultsMsg.style.display = 'block';
            }} else {{
                noResultsMsg.style.display = 'none';
            }}
        }});
    </script>
</body>
</html>
'''
    return html

def main():
    topics = load_topics()
    
    # Build English Page
    print("Indexing English files...")
    sections_db_en = scan_text_files(split_book_path, part_mappings_en, 'en')
    indexed_topics_en = build_index(topics, sections_db_en, 'en')
    
    sidebar_en_path = os.path.join(base_dir, "sidebar_content.html")
    with open(sidebar_en_path, 'r', encoding='utf-8') as f:
        sidebar_en = f.read()
        
    html_en = generate_html_page(indexed_topics_en, sidebar_en, 'en')
    output_en_path = os.path.join(base_dir, "topics.html")
    with open(output_en_path, 'w', encoding='utf-8') as f:
        f.write(html_en)
    print(f"Generated {output_en_path}")
    
    # Build Hebrew Page
    print("Indexing Hebrew files...")
    sections_db_he = scan_text_files(split_book_he_path, part_mappings_he, 'he')
    indexed_topics_he = build_index(topics, sections_db_he, 'he')
    
    sidebar_he_path = os.path.join(base_dir, "he", "sidebar_content.html")
    with open(sidebar_he_path, 'r', encoding='utf-8') as f:
        sidebar_he = f.read()
        
    html_he = generate_html_page(indexed_topics_he, sidebar_he, 'he')
    output_he_path = os.path.join(base_dir, "he", "topics.html")
    with open(output_he_path, 'w', encoding='utf-8') as f:
        f.write(html_he)
    print(f"Generated {output_he_path}")

if __name__ == "__main__":
    main()

# SITE NOTES — Torah Book of Ideas (tboi)

Summary of repository structure and build/runtime notes for later reference.

- **Top-level:** static site composed of HTML/CSS/JS. Main entry: `index.html`.
- **Content folders:** `parts/` holds per-part site content (nested chapter/section HTML). `he/` is the Hebrew site mirror.
- **Source text:** `split_book/` and `split_book_he/` contain plaintext source, split sections, `x-footnotes.txt`, and helper scripts.
- **Generation:** `generate_website.ps1` produces HTML from files in `split_book` or `split_book_he`. It contains the templating logic (functions: `New-SectionHTML`, `Convert-CrossReferences`, footnote parsing) and localization mappings for `en`/`he`.
- **Localization:** two languages supported (`en` and `he`). Generated site for Hebrew is under `he/`. The PS script embeds translations and direction (`ltr`/`rtl`).
- **Search:** `search.js` loads `search_index.json` (root or relative path computed at runtime) and implements client-side instant search. `search_index.json` exists per site (root and `he/`).
- **Service worker / PWA:** `manifest.json` and `service-worker.js` implement a basic offline strategy: network-first for HTML, cache-first for static assets. Icons in `images/`.
- **Styling:** `styles.css` is the main stylesheet with CSS variables and extensive layout rules.
- **UI scripts:** `sidebar.js`, `language_toggle.js`, `glossary_tooltip.js`, `bookmarks.js`, `audio.js`, `breadcrumb_mobile.js` handle navigation, language toggle, tooltips, bookmarks, audio, and responsive breadcrumb behavior.
- **Sidebar/content snippets:** `sidebar_content.html`, `contents.html`, `glossary_content.html`, `bibliography_content.html` appear used to build the site navigation and sidebars.
- **Footnotes & cross-references:** `generate_website.ps1` parses `x-footnotes.txt` and converts `[REF: ...]` and `[TITLE: ...]` markup into links and HTML during generation.
- **Platform notes:** generation script is PowerShell and references absolute Windows paths; it is intended to be run in a Windows environment (or adapted for cross-platform PowerShell Core). There are also Python utilities (`format_bibliography.py`, `format_glossary.py`) used for preprocessing.
- **Assets:** images in `images/`. Icons referenced in `manifest.json`.

Quick file pointers:

- Template/generator: [generate_website.ps1](generate_website.ps1)
- Main page: [index.html](index.html)
- Styles: [styles.css](styles.css)
- Service worker: [service-worker.js](service-worker.js)
- Search client: [search.js](search.js)
- Source text + split tooling: `split_book/` and `split_book_he/`
- Hebrew site root: `he/`

Notes / next actions you might want later:
- Run or adapt `generate_website.ps1` (PowerShell Core) to regenerate HTML from `split_book`.
- Add a small Node/Python wrapper if you want cross-platform generation automation.
- Inspect `sidebar.js` and `sidebar_content.html` if you need to change navigation structure.

Generated on: 2026-01-11

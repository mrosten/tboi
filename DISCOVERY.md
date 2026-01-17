# The Torah Book of Ideas — Project Discovery

**Discovery Date:** 2026-01-17  
**Repository:** https://github.com/mrosten/tboi  
**Live Site:** https://mrosten.github.io/tboi/

---

## 📖 Project Overview

**The Torah Book of Ideas** is a multi-part religious/philosophical book presented as a static website. It aims to provide "a unified system of science, philosophy, and Kabbalah" through a hierarchical, navigable web experience.

### Author & Dedication
- Authored by **Philip Rosenblum** (父), dedicated to his parents Philip and Leila Rosenblum
- Acknowledgements to sons **Moshe** and **Nachman Isaac** for their contributions
- Inspired by the book *Genesis and the Big Bang*

---

## 🗂️ Project Structure

```
tboi/
├── index.html                    # Home page (dedication, acknowledgements, intro)
├── contents.html                 # Full table of contents
├── search.html                   # Client-side search page
├── glossary.html                 # Glossary of terms
├── bibliography.html             # Bibliography/references
├── styles.css                    # Main stylesheet (3,814 lines)
├── generate_website.ps1          # Main site generator (1,941 lines)
│
├── split_book/                   # SOURCE: English plaintext content
│   ├── part_i-Philosophy and Faith/
│   ├── part_ii-Halachah/
│   ├── part_iii-life/
│   ├── part_iv-politics/
│   ├── part_v-ideas/
│   ├── part_vi-christianity/
│   └── x-footnotes.txt           # Footnote definitions
│
├── split_book_he/                # SOURCE: Hebrew plaintext content
│   └── [same structure as split_book]
│
├── parts/                        # OUTPUT: Generated English HTML
│   ├── part_i/                   # 12 chapters, ~115 files
│   ├── part_ii/                  # ~36 files
│   ├── part_iii_life/            # ~44 files
│   ├── part_iii_politics/        # ~23 files
│   ├── part_iv/                  # ~55 files
│   ├── part_iv_politics/         # ~10 files
│   ├── part_v/                   # ~34 files
│   ├── part_v_ideas/             # ~18 files
│   └── part_vi_christianity/     # ~13 files
│
├── he/                           # OUTPUT: Generated Hebrew HTML (236 files)
│   └── [mirrored structure]
│
├── images/                       # Book images and diagrams (79 files)
│   ├── icon-192.png, icon-512.png  # PWA icons
│   └── [concept illustrations, diagrams]
│
└── [JavaScript modules]
    ├── sidebar.js                # Navigation sidebar
    ├── search.js                 # Search functionality
    ├── glossary_tooltip.js       # Term tooltips
    ├── language_toggle.js        # EN/HE language switching
    ├── bookmarks.js              # User bookmarks
    ├── audio.js                  # Audio features
    └── breadcrumb_mobile.js      # Mobile navigation
```

**Total Files:** ~933 files

---

## 📚 Book Structure

### Six Parts

| Part | Title | Theme |
|------|-------|-------|
| **Part I** | Philosophy and Faith | 12 chapters covering God, faith, philosophy, piety, happiness, reward/punishment, eras, redemption, Torah learning, Gemara, science, decisions |
| **Part II** | Halachah | Principles of Jewish law |
| **Part III** | Life | Family, marriage, sex, ways of life, friendship, success, saints |
| **Part IV** | Politics | Politics and the Torah |
| **Part V** | Ideas | Ideas in Kabbalah |
| **Part VI** | Christianity | Jesus Christ and Christian theology from Jewish perspective |

### Hierarchy
```
Part → Chapters → Sections
```
- Each section is a standalone HTML page
- Navigation via breadcrumbs, sidebars, prev/next buttons

---

## 🔧 Build System

### Two-Pass Generation (`generate_website.ps1`)

1. **Pass 1 — Metadata Collection**
   - Scans all parts → chapters → sections
   - Builds navigation structure (`$allPartsData`)
   - Collects titles from `[TITLE: ...]` markup

2. **Pass 2 — HTML Generation**
   - Creates directory structure in `/parts/` (or `/he/`)
   - Converts plaintext to HTML with:
     - Paragraph formatting
     - Footnote parsing (from `x-footnotes.txt`)
     - Cross-reference links (`[REF: Part I, Ch 3, Sec II]`)
     - Image insertions (`[IMG: filename.png]`)
     - Concept boxes, blockquotes
   - Generates index pages, search index, sidebars

### Build Commands
```powershell
# English site
./generate_website.ps1

# Hebrew site
./generate_website.ps1 -Language he

# Single page rebuild
./build_one.ps1
```

---

## 🌐 Features

### Bilingual Support
- **English** (`/`) and **Hebrew** (`/he/`) versions
- RTL support for Hebrew with `dir="rtl"`
- Language toggle in header

### Navigation
- **Breadcrumb dropdowns** — Part/Chapter/Section navigation
- **Sidebar** — Collapsible table of contents
- **Prev/Next buttons** — Cross-chapter, cross-part navigation
- **Mobile-optimized** — Touch-friendly breadcrumbs, responsive layout

### Search
- Client-side search using `search_index.json`
- Instant results as you type
- Separate indices for each language

### User Features
- **Dark mode** — Toggle with localStorage persistence
- **Bookmarks** — Save reading progress
- **Glossary tooltips** — Inline term definitions

### PWA Support
- `manifest.json` for installability
- `service-worker.js` — Offline access (network-first HTML, cache-first assets)

---

## 🎨 Design System

### Color Palette
- **Primary:** Deep blues (`#1a237e`, `#283593`)
- **Accent:** Gold (`#d4af37`, `#b8860b`)
- **Background:** Cream/parchment tones
- **Dark mode:** Deep blue backgrounds with gold accents

### Typography
- **Headings:** Playfair Display
- **Body:** Lora
- **Hebrew:** Frank Ruhl Libre

### Key Components
- `.content-card` — Main content container with gold top border
- `.breadcrumb` — Navigation with dropdown menus
- `.concept-box` — Highlighted concept explanations
- `.fancy-quote` — Styled blockquotes
- `.nav-btn` — Previous/Next navigation buttons

---

## 🔄 Translation Status

(As of 2026-01-11)

| Part | Status |
|------|--------|
| Part I | ✅ Complete |
| Part II | ✅ Complete |
| Part III | 🚧 In Progress (Ch 1-6 done, Ch 7 pending) |
| Part IV-VI | ⬜ Not started |

---

## 📁 Key Files Reference

| File | Purpose |
|------|---------|
| `generate_website.ps1` | Main PowerShell generator |
| `split_book/x-footnotes.txt` | Footnote definitions |
| `styles.css` | All styling (3,814 lines) |
| `search_index.json` | Search data |
| `sidebar_content.html` | Navigation sidebar content |
| `glossary_terms.json` | Glossary term definitions |

---

## 🚀 Deployment

- Hosted on **GitHub Pages** at `https://mrosten.github.io/tboi/`
- Deploy via:
  ```bash
  git add -A && git commit -m "Update" && git push
  ```

---

## 📝 Source File Markup

Plaintext files in `split_book/` support:

```
[TITLE: Section Title]           → Page title
[IMG: filename.png]              → Image insertion
[REF: Part I, Ch 3, Sec II]     → Cross-reference link
[1], [2]...                      → Footnote references

<blockquote class="fancy-quote">  → Styled quote
<div class="concept-box">         → Concept explanation
```

---

## 🔗 Related Documentation

- `ARCHITECTURE.md` — Technical architecture details
- `SITE_NOTES.md` — Quick reference notes
- `TRANSLATION_UPDATE.md` — Translation progress tracking

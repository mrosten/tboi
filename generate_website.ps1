param([string]$Language = "en")

# Generate HTML pages for all sections in the Torah Book of Ideas
# This script reads section text files and generates corresponding HTML pages


$splitBookPath = if ($Language -eq "he") { "c:\myantigravity\cantorwilliam\src\tboi\split_book_he" } else { "c:\myantigravity\cantorwilliam\src\tboi\split_book" }
$websitePath = if ($Language -eq "he") { "c:\myantigravity\cantorwilliam\src\tboi\he" } else { "c:\myantigravity\cantorwilliam\src\tboi" }

# Localization Dictionary
$L = @{
    'en' = @{
        'Dir'              = 'ltr'
        'Lang'             = 'en'
        'Home'             = 'Home'
        'Contents'         = 'Contents'
        'Search'           = 'Search'
        'Bibliography'     = 'Bibliography'
        'Glossary'         = 'Glossary'
        'Appendices'       = 'Appendices'
        'CloseNavigation'  = 'Close Navigation'
        'ToggleDarkMode'   = 'Toggle Dark Mode'
        'BookTitle'        = 'The Torah Book of Ideas'
        'Subtitle'         = 'A Unified System of Science, Philosophy, and Kabbalah'
        'Dedication'       = 'Dedication'
        'Acknowledgements' = 'Acknowledgements'
        'Introduction'     = 'Introduction'
        'BeginReading'     = 'Begin Reading: Table of Contents'
        'FooterText'       = 'The Torah Book of Ideas — A journey through wisdom, faith, and understanding'
        'Part'             = 'Part'
        'Chapter'          = 'Chapter'
        'Section'          = 'Section'
        'Chapters'         = 'Chapters'
        'Previous'         = 'Previous'
        'Next'             = 'Next'
        'NextChapter'      = 'Next Chapter'
        'Start'            = 'Start'
        'TableOfContents'  = 'Table of Contents'
        'TypeToSearch'     = 'Type to search...'
        'NoResults'        = 'No results found.'
        'SearchResults'    = 'Search Results'
        'ViewPartIndex'    = 'View Part Index'
        'Sections'         = 'Sections'
        'TypeTwoChars'     = 'Type at least 2 characters to search...'
        'LangToggleText'   = 'HE'
        'LangToggleLabel'  = 'Switch to Hebrew'
    }
    'he' = @{
        'Dir'              = 'rtl'
        'Lang'             = 'he'
        'Home'             = 'בית'
        'Contents'         = 'תוכן העניינים'
        'Search'           = 'חיפוש'
        'Bibliography'     = 'ביבליוגרפיה'
        'Glossary'         = 'מילון מונחים'
        'Appendices'       = 'נספחים'
        'CloseNavigation'  = 'סגור תפריט'
        'ToggleDarkMode'   = 'מצב לילה'
        'BookTitle'        = 'ספר הרעיונות של התורה'
        'Subtitle'         = 'מערכת מאוחדת של מדע, פילוסופיה וקבלה'
        'Dedication'       = 'הקדשה'
        'Acknowledgements' = 'תודות'
        'Introduction'     = 'מבוא'
        'BeginReading'     = 'התחל לקרוא: תוכן העניינים'
        'FooterText'       = 'ספר הרעיונות של התורה — מסע דרך חוכמה, אמונה והבנה'
        'Part'             = 'חלק'
        'Chapter'          = 'פרק'
        'Chapters'         = 'פרקים'
        'Section'          = 'סעיף'
        'Sections'         = 'סעיפים'
        'Previous'         = 'הקודם'
        'Next'             = 'הבא'
        'NextChapter'      = 'הפרק הבא'
        'Start'            = 'התחל את'
        'TableOfContents'  = 'תוכן העניינים'
        'TypeToSearch'     = 'הקלד לחיפוש...'
        'TypeTwoChars'     = 'הקלד לפחות 2 תווים לחיפוש...'
        'NoResults'        = 'לא נמצאו תוצאות.'
        'SearchResults'    = 'תוצאות חיפוש'
        'ViewPartIndex'    = 'צפה באינדקס חלק'
        'LangToggleText'   = 'EN'
        'LangToggleLabel'  = 'החלף לאנגלית'
    }
}

$Loc = $L[$Language]

# Title Translations
$PartTranslations = @{
    'Part I — Philosophy and Faith' = 'חלק א'' — פילוסופיה ואמונה'
    'Part II — Halachah'            = 'חלק ב'' — הלכה'
    'Part III — Life'               = 'חלק ג'' — חיים'
    'Part IV — Politics'            = 'חלק ד'' — פוליטיקה'
    'Part V — Ideas'                = 'חלק ה'' — רעיונות'
    'Part VI — Christianity'        = 'חלק ו'' — נצרות'
}

$ChapterTranslations = @{
    'The Song Of Creation'   = 'שירת הבריאה'
    'The Song Of Faith'      = 'שירת האמונה'
    'The Sabbath'            = 'השבת'
    'The Song Of Philosophy' = 'שירת הפילוסופיה'
    'Piety'                  = 'חסידות'
    'Happiness'              = 'שמחה'
    'Reward And Punishment'  = 'שכר ועונש'
    'Eras Of Man'            = 'תקופות האדם'
    'The Redemption'         = 'הגאולה'
    'On Learning Torah'      = 'על לימוד תורה'
    'Gemarah'                = 'גמרא'
    'On Science'             = 'על המדע'
    'Decisions'              = 'החלטות'
    "Principles of Halacha"  = "עקרונות ההלכה"
    "Prayer"                 = "תפילה"
}

# Ensure output directory exists
if (-not (Test-Path $websitePath)) {
    New-Item -ItemType Directory -Path $websitePath -Force | Out-Null
}

$footnotesContent = Get-Content "$splitBookPath\x-footnotes.txt" -Raw -Encoding UTF8

# Parse footnotes into hash table
$footnotes = @{}
$currentFootnoteNum = ""
$currentFootnoteText = ""

$fLines = $footnotesContent -split "`r?`n"
foreach ($line in $fLines) {
    if ($line -match '^\[(\d+)\]$') {
        if ($currentFootnoteNum) {
            $footnotes[$currentFootnoteNum] = $currentFootnoteText.Trim()
        }
        $currentFootnoteNum = $matches[1]
        $currentFootnoteText = ""
    }
    elseif ($currentFootnoteNum) {
        $currentFootnoteText += "$line "
    }
}
# Add last footnote
if ($currentFootnoteNum) {
    $footnotes[$currentFootnoteNum] = $currentFootnoteText.Trim()
}

# Helper function to extract title from section file
function Get-SectionTitle {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        if ($content -match '\[TITLE:\s*(.*?)\]') {
            return $matches[1].Trim()
        }
    }
    return ""
}

# Convert [REF: ...] markup to hyperlinks
function Convert-CrossReferences {
    param(
        [string]$Content,
        [hashtable]$RefIndex
    )
    
    # Pattern: [REF: Part I, Chapter 3, Section II] or [REF: Part I, Ch 3, Sec II "Optional Title"]
    $pattern = '\[REF:\s*([^\]"]+?)(?:\s*"([^"]+)")?\s*\]'
    
    $result = [regex]::Replace($Content, $pattern, {
            param($match)
            $refKey = $match.Groups[1].Value.Trim().ToLower()
            $customTitle = $match.Groups[2].Value
        
            # Normalize the key (handle various formats)
            $refKey = $refKey -replace '\s+', ' '
            $refKey = $refKey -replace 'chapter', 'ch' -replace 'section', 'sec'
        
            if ($RefIndex.ContainsKey($refKey)) {
                $ref = $RefIndex[$refKey]
                $displayText = if ($customTitle) { $customTitle } else { $ref.Title }
                return "<a href='$($ref.Url)' class='cross-ref' title='$($ref.ChapterTitle)'>$displayText</a>"
            }
            else {
                # Return original text with warning class if not found
                Write-Host "  Warning: Reference not found: $refKey" -ForegroundColor Yellow
                return "<span class='cross-ref-missing'>$($match.Value)</span>"
            }
        })
    
    return $result
}

# HTML template function
function New-SectionHTML {
    param(
        [string]$PartName,
        [string]$PartTitle,
        [string]$ChapterNum,
        [string]$ChapterTitle,
        [string]$SectionNum,
        [string]$Content,
        [string]$PrevLink,
        [string]$PrevLabel = "Previous",
        [string]$NextLink,
        [string]$NextLabel,
        [array]$SectionList,
        [array]$ChapterList,
        [array]$PartList,
        [hashtable]$Footnotes,
        [string]$SidebarContent = ""
    )
    
    # Extract Title if present
    $sectionTitleText = ""
    if ($Content -match '\[TITLE:\s*(.*?)\]') {
        $sectionTitleText = " — " + $matches[1].Trim()
        $Content = $Content -replace '\[TITLE:\s*.*?\]', ''
    }

    # Clean and format content
    $lines = $Content -split "`r?`n" | Where-Object { $_.Trim() -ne '' -and $_.Trim() -ne '·' -and $_.Trim() -ne '●' }
    $paragraphs = @()
    $currentPara = ""
    
    $pageFootnotes = @()
    $inRawBlock = $false
    
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '\[(\d+)\]') {
            # Footnote reference - likely inline or end of line
            # We need to process the whole line to keep the marker in text, and also collect the footnote content
            
            # Simple approach: assume marker is separate or part of line. 
            # Better approach: Regex replace to add superscript AND collect ID.
            
            $processedLine = $trimmed -replace '\[(\d+)\]', '<sup>[$1]</sup>'
            $currentPara += "$processedLine "
            
            # Extract IDs for footer
            $matchesResult = [regex]::Matches($trimmed, '\[(\d+)\]')
            foreach ($m in $matchesResult) {
                $fid = $m.Groups[1].Value
                if ($Footnotes.ContainsKey($fid)) {
                    $pageFootnotes += @{ ID = $fid; Text = $Footnotes[$fid] }
                }
            }
        }
        elseif ($trimmed -match '\[IMAGE:\s*(.*?)\]') {
            # Image tag - convert to div with img
            if ($currentPara.Trim()) {
                $paragraphs += "<p>$($currentPara.Trim())</p>"
                $currentPara = ""
            }
            $imageFile = $matches[1].Trim()
            $paragraphs += "<div class='image-container'><img src='../../../images/$imageFile' alt='Book Image' class='book-image'></div>"
        }
        elseif ($trimmed -match '^Chapter \d+') {
            # Skip chapter headers in content
            continue
        }
        elseif ($trimmed -match '^Section [IVX]+') {
            # Skip section headers
            continue
        }
        elseif ($trimmed -match '^<(script|style|table|thead|tbody|tfoot|div|blockquote|h[1-6]|p|ul|ol|li|hr|section|aside|nav|header|footer|hr)') {
            # Start of raw block
            if ($currentPara.Trim()) {
                $paragraphs += "<p>$($currentPara.Trim())</p>"
                $currentPara = ""
            }
            $inRawBlock = $true
            $paragraphs += $trimmed
        }
        else {
            if ($inRawBlock) {
                $paragraphs += $trimmed
            }
            else {
                $currentPara += "$trimmed "
            }
        }
        
        if ($trimmed -match '^</(script|style|table|div|blockquote|h[1-6]|p|ul|ol|li|section|aside|nav|header|footer)') {
            $inRawBlock = $false
        }
        
        # Check for sentence endings to potentially break paragraphs
        if (-not $inRawBlock -and $currentPara.Length -gt 500 -and $trimmed -match '\.$') {
            $paragraphs += "<p>$($currentPara.Trim())</p>"
            $currentPara = ""
        }
    }
    if ($currentPara.Trim()) {
        $paragraphs += "<p>$($currentPara.Trim())</p>"
    }
    
    $contentHtml = $paragraphs -join "`n            "
    
    # Wrap tables in responsive container
    $contentHtml = $contentHtml -replace '(?s)(<table[^>]*class=["'']data-table["''][^>]*>.*?</table>)', '<div class="table-wrapper">$1</div>'

    # Calculate relative path depth
    $depth = "../../../"
    $assetDepth = if ($Language -eq "he") { "../$depth" } else { $depth }
    
    $html = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ChapterTitle — $($Loc['Section']) $SectionNum</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$SidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="${depth}search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['LangToggleLabel'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangToggleText'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$PartTitle</p>
    </header>
    <nav>
        <a href="${depth}index.html">$($Loc['Home'])</a>
        <a href="${depth}contents.html">$($Loc['Contents'])</a>
        <a href="../index.html" class="active">$PartTitle</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="${depth}index.html">$($Loc['Home'])</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="../index.html">$PartTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $PartList) {
                            $activeClass = if ($p.Target -eq $PartName) { "class='active'" } else { "" }
                            # Path to part index from current section (depth is ../../../ or ../../../../)
                            # Actually depth variable handles getting to site root.
                            # From site root, parts are at parts/part_name/index.html
                            $pPath = "${depth}parts/$($p.Target)/index.html"
                            $pLinks += "<a href='$pPath' $activeClass>$($p.Title)</a>"
                        }
                        $pLinks
                    )
                </div>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="index.html">$ChapterTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $cLinks = ""
                        foreach ($c in $ChapterList) {
                            $activeClass = if ($c.Num -eq $ChapterNum) { "class='active'" } else { "" }
                            # Path to chapter index from current section is just index.html, but we want the first section
                            $cPath = "../$($c.Folder)/section_i.html"
                            $cLinks += "<a href='$cPath' $activeClass>$($c.Title)</a>"
                        }
                        $cLinks
                    )
                </div>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="section_i.html">$($Loc['Section']) $SectionNum</a>
                <div class="breadcrumb-dropdown">
                    <div class="section-grid">
                        $(
                            $links = ""
                            foreach ($sec in $SectionList) {
                                $activeClass = if ($sec.Num -eq $SectionNum) { "class='active'" } else { "" }
                                $links += "<a href='$($sec.Filename)' $activeClass>$($sec.Num)</a>"
                            }
                            $links
                        )
                    </div>
                </div>
            </div>
        </div>

        <div class="content-card">
            <h3>$($Loc['Section']) $SectionNum$sectionTitleText</h3>
            $contentHtml
            
            $(
                if ($pageFootnotes.Count -gt 0) {
                    "<hr class='divider'>"
                    "<div class='footnotes'>"
                    foreach ($fn in $pageFootnotes) {
                        "<p class='footnote-item'><sup>[$($fn.ID)]</sup> $($fn.Text)</p>"
                    }
                    "</div>"
                }
            )
        </div>

        <div class="page-nav">
            <a href="$PrevLink" class="nav-btn prev"><span>$PrevLabel</span></a>
            <a href="$NextLink" class="nav-btn next"><span>$NextLabel</span></a>
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}language_toggle.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script src="${assetDepth}breadcrumb_mobile.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const images = document.querySelectorAll('.book-image');

        images.forEach(img => {
            img.style.cursor = 'zoom-in';
            img.addEventListener('click', function() {
                lightbox.style.display = 'block';
                lightboxImg.src = this.src;
            });
        });

        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) {
            closeSpan.onclick = function() {
                lightbox.style.display = 'none';
            }
        }

        window.onclick = function(event) {
            if (event.target == lightbox) {
                lightbox.style.display = 'none';
            }
        }
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
    return $html
}

# Part index page template
function New-PartIndexHTML {
    param(
        [string]$PartName,
        [string]$PartTitle,
        [array]$Chapters,
        [array]$PartList,
        [string]$SidebarContent = ""
    )
    
    $chapterLinks = ""
    foreach ($ch in $Chapters) {
        $sectionLinks = ""
        foreach ($sec in $ch.Sections) {
            $sectionLinks += "                        <li><a href=`"$($ch.Folder)/$($sec.Filename)`"><span class='sec-num'>$($sec.Num)</span> <span class='sec-title'>$($sec.Title)</span></a></li>`n"
        }
        
        $chapterLinks += @"
                <details class="chapter-folder">
                    <summary class="chapter-header">$($ch.Title)</summary>
                    <ul class="section-list">
$sectionLinks
                    </ul>
                </details>
"@
    }
    
    
    # Calculate asset depth for part index (depth is always ../../ from root)
    $depth = "../../"
    $assetDepth = if ($Language -eq "he") { "../$depth" } else { $depth }

    $html = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PartTitle — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$SidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="${depth}search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['LangToggleLabel'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangToggleText'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$PartTitle</p>
    </header>
    <nav>
        <a href="${depth}index.html">$($Loc['Home'])</a>
        <a href="${depth}contents.html">$($Loc['Contents'])</a>
        <a href="index.html" class="active">$PartTitle</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="${depth}index.html">$($Loc['Home'])</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="index.html">$PartTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $PartList) {
                            $activeClass = if ($p.Target -eq $PartName) { "class='active'" } else { "" }
                            # Link to part index
                            $pPath = "../../parts/$($p.Target)/index.html"
                            $pLinks += "<a href='$pPath' $activeClass>$($p.Title)</a>"
                        }
                        $pLinks
                    )
                </div>
            </div>
        </div>
        <div class="content-card">
            <h2>$PartTitle</h2>
            <div class="toc">
                <h3>$($Loc['Chapters'])</h3>
                <div class="toc-chapters">
$chapterLinks
                </div>
            </div>
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}language_toggle.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const images = document.querySelectorAll('.book-image');

        images.forEach(img => {
            img.style.cursor = 'zoom-in';
            img.addEventListener('click', function() {
                lightbox.style.display = 'block';
                lightboxImg.src = this.src;
            });
        });

        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) {
            closeSpan.onclick = function() {
                lightbox.style.display = 'none';
            }
        }

        window.onclick = function(event) {
            if (event.target == lightbox) {
                lightbox.style.display = 'none';
            }
        }
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
    return $html
}


# Bibliography page template
function New-BibliographyPage {
    param(
        [string]$Content,
        [string]$SidebarContent = ""
    )
    
    
    # Calculate asset depth for root page
    $assetDepth = if ($Language -eq "he") { "../" } else { "" }

    $html = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Loc['Bibliography']) — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$SidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['ToggleLanguage'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangCode'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$($Loc['Bibliography'])</p>
    </header>
    <nav>
        <a href="index.html">$($Loc['Home'])</a>
        <a href="contents.html">$($Loc['Contents'])</a>
        <a href="bibliography.html" class="active">$($Loc['Bibliography'])</a>
    </nav>
    <main class="container">
        <div class="content-card">
            <h2>$($Loc['Bibliography'])</h2>
            $Content
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox (just in case)
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) { closeSpan.onclick = () => lightbox.style.display = 'none'; }
        window.onclick = (e) => { if (e.target == lightbox) lightbox.style.display = 'none'; }
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
    return $html
}


# Glossary page template
function New-GlossaryPage {
    param(
        [string]$Content,
        [string]$SidebarContent = ""
    )
    
    
    # Calculate asset depth for root page
    $assetDepth = if ($Language -eq "he") { "../" } else { "" }

    $html = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Loc['Glossary']) — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$SidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['ToggleLanguage'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangCode'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$($Loc['Glossary'])</p>
    </header>
    <nav>
        <a href="index.html">$($Loc['Home'])</a>
        <a href="contents.html">$($Loc['Contents'])</a>
        <a href="glossary.html" class="active">$($Loc['Glossary'])</a>
    </nav>
    <main class="container">
        <div class="content-card">
            <h2>$($Loc['Glossary'])</h2>
            $Content
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox (just in case)
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) { closeSpan.onclick = () => lightbox.style.display = 'none'; }
        window.onclick = (e) => { if (e.target == lightbox) lightbox.style.display = 'none'; }
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
    return $html
}

# Full table of contents template
function New-MainContentsHTML {
    param(
        [array]$PartDataList,
        [string]$SidebarContent = ""
    )
    
    $fullContents = ""
    foreach ($part in $PartDataList) {
        $chapterLinks = ""
        foreach ($ch in $part.Chapters) {
            $sectionLinks = ""
            foreach ($sec in $ch.Sections) {
                # Links are relative to contents.html (root) which is same depth for En and He
                $sectionLinks += "                        <li><a href=`"parts/$($part.Target)/$($ch.Folder)/$($sec.Filename)`"><span class='sec-num'>$($sec.Num)</span> <span class='sec-title'>$($sec.Title)</span></a></li>`n"
            }
            
            $chapterLinks += @"
                <details class="chapter-folder">
                    <summary class="chapter-header">$($ch.Title)</summary>
                    <ul class="section-list">
$sectionLinks
                    </ul>
                </details>
"@
        }
        
        $partOpen = if ($part.Target -eq "part_i") { "open" } else { "" }

        $fullContents += @"
                <details class="toc-part-group" $partOpen>
                    <summary class="toc-part-title">
                        <span>$($part.Title)</span>
                        <span class="toc-toggle-icon"></span>
                    </summary>
                    <div class="toc-part-links">
                        <a href="parts/$($part.Target)/index.html">$($Loc['ViewPartIndex'])$nextArrow</a>
                    </div>
                    <div class="toc-chapters">
$chapterLinks
                    </div>
                </details>
"@
    }
    
    # Calculate asset depth for root page
    $assetDepth = if ($Language -eq "he") { "../" } else { "" }
    
    $html = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Loc['TableOfContents']) — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$SidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['LangToggleLabel'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangToggleText'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$($Loc['TableOfContents'])</p>
    </header>
    <nav>
        <a href="index.html">$($Loc['Home'])</a>
        <a href="contents.html" class="active">$($Loc['Contents'])</a>
        <a href="search.html">$($Loc['Search'])</a>
    </nav>
    <main class="container">
        <div class="content-card">
            <h2>✡ $($Loc['Contents']) ✡</h2>
            <div class="toc">
$fullContents
                
                <div class="toc-special-section" style="margin-top: 2rem; border-top: 1px dashed var(--accent-gold); padding-top: 1rem;">
                    <h3>$($Loc['Appendices'])</h3>
                    <ul class="section-list">
                        <li><a href="glossary.html"><span class="sec-title">$($Loc['Glossary'])</span></a></li>
                        <li><a href="bibliography.html"><span class="sec-title">$($Loc['Bibliography'])</span></a></li>
                    </ul>
                </div>
            </div>
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}language_toggle.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox (just in case)
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) { closeSpan.onclick = () => lightbox.style.display = 'none'; }
        window.onclick = (e) => { if (e.target == lightbox) lightbox.style.display = 'none'; }
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
    return $html
}

function New-SidebarContent {
    param(
        [array]$PartDataList,
        [string]$RootPath = ""  # e.g., "../../../" for section pages
    )
    
    $sidebarSelect = @"
    <div class="sidebar-header">
        <h3>$($Loc['Contents'])</h3>
        <button id="close-sidebar" aria-label="$($Loc['CloseNavigation'])">×</button>
    </div>
    <div class="sidebar-scroll">
"@

    foreach ($part in $PartDataList) {
        $sidebarSelect += @"
        <div class="sidebar-part">
            <h4 class="sidebar-part-title">$($part.Title)</h4>
            <ul class="sidebar-chapter-list">
"@
        foreach ($ch in $part.Chapters) {
            $sidebarSelect += @"
                <li class="sidebar-chapter">
                    <details>
                        <summary>$($ch.Title)</summary>
                        <ul class="sidebar-section-list">
"@
            foreach ($sec in $ch.Sections) {
                $linkPath = "${RootPath}parts/$($part.Target)/$($ch.Folder)/$($sec.Filename)"
                $sidebarSelect += "                            <li><a href='$linkPath'>$($sec.Title)</a></li>`n"
            }
            $sidebarSelect += @"
                        </ul>
                    </details>
                </li>
"@
        }
        $sidebarSelect += @"
            </ul>
        </div>
"@
    }

    $sidebarSelect += "</div>"
    return $sidebarSelect
}

# Roman numeral conversion
$romanNumerals = @{
    'i' = 'I'; 'ii' = 'II'; 'iii' = 'III'; 'iv' = 'IV'; 'v' = 'V';
    'vi' = 'VI'; 'vii' = 'VII'; 'viii' = 'VIII'; 'ix' = 'IX'; 'x' = 'X';
    'xi' = 'XI'; 'xii' = 'XII'; 'xiii' = 'XIII'; 'xiv' = 'XIV'; 'xv' = 'XV';
    'xvi' = 'XVI'; 'xvii' = 'XVII'; 'xviii' = 'XVIII'; 'xix' = 'XIX'; 'xx' = 'XX';
    'xxi' = 'XXI'; 'xxii' = 'XXII'; 'xxiii' = 'XXIII'; 'xxiv' = 'XXIV'; 'xxv' = 'XXV'
}

$romanToInt = @{
    'i' = 1; 'ii' = 2; 'iii' = 3; 'iv' = 4; 'v' = 5;
    'vi' = 6; 'vii' = 7; 'viii' = 8; 'ix' = 9; 'x' = 10;
    'xi' = 11; 'xii' = 12; 'xiii' = 13; 'xiv' = 14; 'xv' = 15;
    'xvi' = 16; 'xvii' = 17; 'xviii' = 18; 'xix' = 19; 'xx' = 20;
    'xxi' = 21; 'xxii' = 22; 'xxiii' = 23; 'xxiv' = 24; 'xxv' = 25
}

# Process parts
$partMappings = @(
    @{Source = "part_i-Philosophy and Faith"; Target = "part_i"; Title = "Part I — Philosophy and Faith" },
    @{Source = "part_ii-Halachah"; Target = "part_ii"; Title = "Part II — Halachah" },
    @{Source = "part_iii-life"; Target = "part_iii_life"; Title = "Part III — Life" },
    @{Source = "part_iv-politics"; Target = "part_iv_politics"; Title = "Part IV — Politics" },
    @{Source = "part_v-ideas"; Target = "part_v_ideas"; Title = "Part V — Ideas" },
    @{Source = "part_vi-christianity"; Target = "part_vi_christianity"; Title = "Part VI — Christianity" }
)

$totalSections = 0
$totalChapters = 0
$allPartsData = @()

$prevArrow = "← "
$nextArrow = " →"

if ($Language -eq "he") {
    # User requested arrows to match English direction (Left for Prev, Right for Next)
    # Standard RTL usually swaps them, but users find it confusing with mixed text.
    # So we force them to match the visual position.
    $prevArrow = "← "
    $nextArrow = " →"
    foreach ($p in $partMappings) {
        if ($PartTranslations.ContainsKey($p.Title)) {
            $p.Title = $PartTranslations[$p.Title]
        }
    }
}

$prevArrow = ""
$nextArrow = ""

# FIRST PASS: Collect all parts/chapters/sections metadata (needed for sidebar)
Write-Host "Collecting navigation structure..." -ForegroundColor Cyan
foreach ($part in $partMappings) {
    $sourcePath = Join-Path $splitBookPath $part.Source
    if (-not (Test-Path $sourcePath)) { continue }
    
    $chapters = Get-ChildItem $sourcePath -Directory | Sort-Object Name
    $chapterList = @()
    
    foreach ($chapter in $chapters) {
        $chapterNum = if ($chapter.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
        $chapterTitleRaw = ($chapter.Name -replace 'chapter_\d+-', '' -replace '-', ' ').Trim()
        $chapterTitle = (Get-Culture).TextInfo.ToTitleCase($chapterTitleRaw)
        
        if ($Language -eq "he" -and $ChapterTranslations.ContainsKey($chapterTitle)) {
            $chapterTitle = $ChapterTranslations[$chapterTitle]
        }
        
        $chapterTitle = "$($Loc['Chapter']) $([int]$chapterNum): $chapterTitle"
        $chapterFolder = "chapter_$chapterNum"
        
        $sections = Get-ChildItem $chapter.FullName -Filter "section_*.txt" | Sort-Object { 
            if ($_.Name -match 'section_([ivx]+)\.txt') { 
                $num = $matches[1]
                if ($romanToInt.ContainsKey($num)) { return $romanToInt[$num] }
            }
            return 999 
        }
        
        $sectionList = @()
        foreach ($secFile in $sections) {
            $secNumStr = if ($secFile.Name -match 'section_([ivx]+)\.txt') { $romanNumerals[$matches[1]] } else { "I" }
            $secFilename = $secFile.Name.Replace('.txt', '.html')
            $tmpContent = Get-Content $secFile.FullName -Raw -Encoding UTF8
            $secTitle = "$($Loc['Section']) $secNumStr"
            if ($tmpContent -match '\[TITLE:\s*(.*?)\]') {
                $secTitle = $matches[1].Trim()
            }
            $sectionList += @{ Num = $secNumStr; Filename = $secFilename; Title = $secTitle }
        }
        
        $chapterList += @{ Folder = $chapterFolder; Title = $chapterTitle; Num = $chapterNum; Sections = $sectionList }
    }
    
    $allPartsData += @{ Target = $part.Target; Title = $part.Title; Chapters = $chapterList }
}

Write-Host "Found $($allPartsData.Count) parts with navigation data" -ForegroundColor Cyan

# Build reference index for cross-references
$referenceIndex = @{}
foreach ($partInfo in $allPartsData) {
    $partNum = if ($partInfo.Title -match 'Part\s+([IVX]+)') { $matches[1] } else { "" }
    foreach ($ch in $partInfo.Chapters) {
        $chNum = $ch.Num
        foreach ($sec in $ch.Sections) {
            $secNum = $sec.Num
            # Build URL path (relative from section pages)
            $url = "../../../parts/$($partInfo.Target)/$($ch.Folder)/$(($sec.Filename))"
            
            # Create multiple key variations for flexible matching
            $keys = @(
                "Part $partNum, Chapter $([int]$chNum), Section $secNum",
                "Part $partNum, Ch $([int]$chNum), Sec $secNum",
                "P$partNum C$([int]$chNum) S$secNum"
            )
            foreach ($key in $keys) {
                $referenceIndex[$key.ToLower()] = @{
                    Url          = $url
                    Title        = $sec.Title
                    PartTitle    = $partInfo.Title
                    ChapterTitle = $ch.Title
                }
            }
        }
    }
}
Write-Host "Built reference index with $($referenceIndex.Count) entries" -ForegroundColor Cyan

# SECOND PASS: Generate all HTML files

foreach ($part in $partMappings) {
    $sourcePath = Join-Path $splitBookPath $part.Source
    $targetPath = Join-Path $websitePath "parts\$($part.Target)"
    
    if (-not (Test-Path $sourcePath)) {
        Write-Host "Source not found: $sourcePath" -ForegroundColor Yellow
        continue
    }
    
    # Create target directory
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    
    # Get chapters
    $chapters = Get-ChildItem $sourcePath -Directory | Sort-Object Name
    
    # Get pre-collected complete chapter list from first pass for dropdown menus
    $partData = $allPartsData | Where-Object { $_.Target -eq $part.Target }
    $completeChapterList = $partData.Chapters
    
    $chapterList = @()
    
    foreach ($chapter in $chapters) {
        $chapterNum = if ($chapter.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
        $chapterTitleRaw = ($chapter.Name -replace 'chapter_\d+-', '' -replace '-', ' ').Trim()
        $chapterTitle = (Get-Culture).TextInfo.ToTitleCase($chapterTitleRaw)

        if ($Language -eq "he" -and $ChapterTranslations.ContainsKey($chapterTitle)) {
            $chapterTitle = $ChapterTranslations[$chapterTitle]
        }

        $chapterTitle = "$($Loc['Chapter']) $([int]$chapterNum): $chapterTitle"
        
        $chapterFolder = "chapter_$chapterNum"
        # We need to collect sections FIRST
        
        # Get sections and sort by roman numeral
        $sections = Get-ChildItem $chapter.FullName -Filter "section_*.txt" | Sort-Object { 
            if ($_.Name -match 'section_([ivx]+)\.txt') { 
                $num = $matches[1]
                if ($romanToInt.ContainsKey($num)) { return $romanToInt[$num] }
            }
            return 999 
        }
        
        # Pre-calc section list
        $chapterSectionList = @()
        for ($j = 0; $j -lt $sections.Count; $j++) {
            $secFile = $sections[$j]
            $secNumStr = if ($secFile.Name -match 'section_([ivx]+)\.txt') { $romanNumerals[$matches[1]] } else { "I" }
            $secFilename = $secFile.Name.Replace('.txt', '.html')
            
            # Peek for title
            $tmpContent = Get-Content $secFile.FullName -Raw -Encoding UTF8
            $secTitle = "Section $secNumStr"
            if ($tmpContent -match '\[TITLE:\s*(.*?)\]') {
                $secTitle = $matches[1].Trim()
            }
            
            $chapterSectionList += @{ Num = $secNumStr; Filename = $secFilename; Title = $secTitle }
        }
        
        $chapterList += @{Folder = $chapterFolder; Title = $chapterTitle; Num = $chapterNum; Sections = $chapterSectionList }
        $chapterPath = Join-Path $targetPath $chapterFolder
        New-Item -ItemType Directory -Path $chapterPath -Force | Out-Null
        
        # Generate Chapter Index
        # Calculate asset depth for chapter index (depth is ../../../ from root)
        $depth = "../../../"
        $assetDepth = if ($Language -eq "he") { "../$depth" } else { $depth }

        $chapterIndexHtml = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ChapterTitle — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <a href="${depth}search.html" id="search-link" aria-label="$($Loc['Search'])" style="font-size:1.2rem; color:inherit; text-decoration:none; margin-right:10px;">🔍</a>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['LangToggleLabel'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangToggleText'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$($part.Title)</p>
    </header>
    <nav>
        <a href="${depth}index.html">$($Loc['Home'])</a>
        <a href="${depth}contents.html">$($Loc['Contents'])</a>
        <a href="../index.html" class="active">$($part.Title)</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="${depth}index.html">$($Loc['Home'])</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="../../../parts/$($part.Target)/index.html">$($part.Title)</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $partMappings) {
                            $activeClass = if ($p.Target -eq $part.Target) { "class='active'" } else { "" }
                            # Link to part index
                            $pPath = "../../../parts/$($p.Target)/index.html"
                            $pLinks += "<a href='$pPath' $activeClass>$($p.Title)</a>"
                        }
                        $pLinks
                    )
                </div>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="index.html" class="active">$ChapterTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $cLinks = ""
                        foreach ($c in $completeChapterList) {
                            $activeClass = if ($c.Num -eq $chapterNum) { "class='active'" } else { "" }
                            $cPath = "../$($c.Folder)/index.html"
                            $cLinks += "<a href='$cPath' $activeClass>$($c.Title)</a>"
                        }
                        $cLinks
                    )
                </div>
            </div>
        </div>

        <div class="content-card">
            <h2>$ChapterTitle</h2>
            <div class="chapter-toc">
                <h3>$($Loc['Sections'])</h3>
                <ul class="clean-list">
$(
    $idxLinks = ""
    foreach ($sec in $chapterSectionList) {
        $idxLinks += "                    <li><a href='$($sec.Filename)'><span class='sec-num'>$($sec.Num)</span> <span class='sec-title'>$($sec.Title)</span></a></li>`n"
    }
    $idxLinks
)
                </ul>
            </div>
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <div id="lightbox-modal">
        <span class="close-lightbox">&times;</span>
        <img class="lightbox-content" id="lightbox-img" alt="Lightbox Image">
    </div>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}search.js"></script>
    <script src="${assetDepth}language_toggle.js"></script>
    <script src="${assetDepth}glossary_tooltip.js"></script>
    <script src="${assetDepth}audio.js"></script>
    <script src="${assetDepth}bookmarks.js"></script>
    <script src="${assetDepth}breadcrumb_mobile.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Lightbox
        const lightbox = document.getElementById('lightbox-modal');
        const lightboxImg = document.getElementById('lightbox-img');
        const images = document.querySelectorAll('.book-image');

        images.forEach(img => {
            img.style.cursor = 'zoom-in';
            img.addEventListener('click', function() {
                lightbox.style.display = 'block';
                lightboxImg.src = this.src;
            });
        });

        const closeSpan = document.querySelector('.close-lightbox');
        if (closeSpan) {
            closeSpan.onclick = function() {
                lightbox.style.display = 'none';
            }
        }

        window.onclick = function(event) {
            if (event.target == lightbox) {
                lightbox.style.display = 'none';
            }
        }
    </script>
</body>
</html>
"@
        $chapterIndexHtml | Set-Content (Join-Path $chapterPath "index.html") -Encoding UTF8
        
        for ($i = 0; $i -lt $sections.Count; $i++) {
            $section = $sections[$i]
            $sectionNum = $section.Name.Replace('section_', '').Replace('.txt', '').ToUpper()
            $content = Get-Content $section.FullName -Raw -Encoding UTF8
            
            # Convert cross-references to hyperlinks
            $content = Convert-CrossReferences -Content $content -RefIndex $referenceIndex
            
            # Determine prev/next links
            
            # Determine prev/next links and labels
            $prevLabel = "Previous"
            
            if ($i -eq 0) {
                # First section of the chapter
                $prevLabel = "Previous Chapter"
                
                # Find previous chapter
                $currentChapterIndex = [array]::IndexOf($chapters, $chapter)
                
                if ($currentChapterIndex -gt 0) {
                    # Previous Chapter in same Part
                    $prevChapter = $chapters[$currentChapterIndex - 1]
                    # Need to find last section of prevChapter
                    # Re-use logical sort block logic basically or just finding last file
                    # Helper sort block
                    $prevChSections = Get-ChildItem $prevChapter.FullName -Filter "section_*.txt" | Sort-Object { 
                        if ($_.Name -match 'section_([ivx]+)\.txt') { 
                            $num = $matches[1]
                            if ($romanToInt.ContainsKey($num)) { return $romanToInt[$num] }
                        }
                        return 999 
                    }
                     
                    if ($prevChSections.Count -gt 0) {
                        $lastSecFile = $prevChSections[$prevChSections.Count - 1]
                        $lastSecFilename = $lastSecFile.Name.Replace('.txt', '.html')
                        $prevChapterNum = if ($prevChapter.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
                        
                        $prevLink = "../chapter_$prevChapterNum/$lastSecFilename"
                        
                        # Extract title from previous chapter
                        $prevChTitle = ($prevChapter.Name -replace 'chapter_\d+-', '' -replace '-', ' ').Trim()
                        $prevChTitle = (Get-Culture).TextInfo.ToTitleCase($prevChTitle)
                        
                        if ($Language -eq "he" -and $ChapterTranslations.ContainsKey($prevChTitle)) {
                            $prevChTitle = $ChapterTranslations[$prevChTitle]
                        }

                        # Construct link to prev chapter's LAST section
                        # Find last section of previous chapter
                        $prevChSecs = Get-ChildItem $prevChapter.FullName -Filter "section_*.txt"
                        if ($prevChSecs.Count -gt 0) {
                            $lastSec = $prevChSecs | Sort-Object Name | Select-Object -Last 1
                            $lastSecNum = $lastSec.Name.Replace("section_", "").Replace(".txt", "").ToUpper()
                            $prevLink = "../chapter_$prevChapterNum/section_$lastSecNum.html"
                            
                            $prevSecTitle = Get-SectionTitle -FilePath $lastSec.FullName
                            if ($prevSecTitle) {
                                $prevLabel = "$prevArrow$prevChTitle - $($Loc['Section']) ${lastSecNum}: $prevSecTitle"
                            }
                            else {
                                $prevLabel = "$prevArrow$($Loc['PreviousChapter']): $prevChTitle"
                            }
                        }
                        else {
                            $prevLabel = "$prevArrow$($Loc['PreviousChapter']): $prevChTitle"
                            $prevLink = "../chapter_$prevChapterNum/section_i.html"
                        }
                    }
                    else {
                        $prevLink = "../index.html" # Fallback
                    }
                }
                else {
                    # First chapter of the Part -> Previous Part
                    $currentPartIndex = [array]::IndexOf($partMappings, $part)
                    if ($currentPartIndex -gt 0) {
                        # Previous Part
                        $prevPart = $partMappings[$currentPartIndex - 1]
                        $prevPartPath = Join-Path $splitBookPath $prevPart.Source
                        $prevPartChapters = Get-ChildItem $prevPartPath -Directory | Sort-Object Name
                        if ($prevPartChapters.Count -gt 0) {
                            $lastCh = $prevPartChapters[$prevPartChapters.Count - 1]
                            $lastChNum = if ($lastCh.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
                             
                            $lastChSections = Get-ChildItem $lastCh.FullName -Filter "section_*.txt" | Sort-Object { 
                                if ($_.Name -match 'section_([ivx]+)\.txt') { 
                                    $num = $matches[1]
                                    if ($romanToInt.ContainsKey($num)) { return $romanToInt[$num] }
                                }
                                return 999 
                            }
                             
                            if ($lastChSections.Count -gt 0) {
                                $lastSecFile = $lastChSections[$lastChSections.Count - 1]
                                $lastSecFilename = $lastSecFile.Name.Replace('.txt', '.html')
                                $prevLink = "../../$($prevPart.Target)/chapter_$lastChNum/$lastSecFilename"
                                
                                # Get section title if available
                                $prevSecTitle = Get-SectionTitle -FilePath $lastSecFile.FullName
                                if ($prevSecTitle) {
                                    $prevSecNum = if ($lastSecFile.Name -match 'section_([ivx]+)\.txt') { $romanNumerals[$matches[1]] } else { "" }
                                    $prevLabel = "$($prevPart.Title) - $($Loc['Section']) ${prevSecNum}: $prevSecTitle"
                                }
                                else {
                                    $prevLabel = "$prevArrow$($Loc['Previous']) $($Loc['Part']): $($prevPart.Title)"
                                }
                            }
                            else {
                                $prevLink = "../../$($prevPart.Target)/index.html"
                                $prevLabel = "$prevArrow$($Loc['Previous']) $($Loc['Part']): $($prevPart.Title)"
                            }
                        }
                        else {
                            $prevLink = "../../$($prevPart.Target)/index.html"
                            $prevLabel = "$prevArrow$($Loc['Previous']) $($Loc['Part']): $($prevPart.Title)"
                        }
                    }
                    else {
                        # First Part of Book
                        $prevLink = "../../../contents.html"
                        $prevLabel = "$prevArrow$($Loc['TableOfContents'])"
                    }
                }
            }
            else {
                # Previous section in same chapter
                $prevSec = $chapterSectionList[$i - 1]
                $prevLink = $prevSec.Filename
                if ($prevSec.Title) {
                    $prevLabel = "$prevArrow$($Loc['Section']) $($prevSec.Num): $($prevSec.Title)"
                }
                else {
                    $prevLabel = "$prevArrow$($Loc['Section']) $($prevSec.Num)"
                }
            }            
            $nextLink = ""
            $nextLabel = "$($Loc['Next'])"
            
            if ($i -lt $sections.Count - 1) {
                # Next section in same chapter
                $nextSec = $chapterSectionList[$i + 1]
                $nextLink = $nextSec.Filename
                if ($nextSec.Title) {
                    $nextLabel = "$($Loc['Section']) $($nextSec.Num): $($nextSec.Title)$nextArrow"
                }
                else {
                    $nextLabel = "$($Loc['Section']) $($nextSec.Num)$nextArrow"
                }
            }
            else {
                # Last section in chapter
                # Find next chapter
                $currentChapterIndex = [array]::IndexOf($chapters, $chapter)
                if ($currentChapterIndex -lt $chapters.Count - 1) {
                    $nextChapter = $chapters[$currentChapterIndex + 1]
                    $nextChapterNum = if ($nextChapter.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
                    
                    # Normalize next chapter name for display
                    $nextChTitle = ($nextChapter.Name -replace 'chapter_\d+-', '' -replace '-', ' ').Trim()
                    $nextChTitle = (Get-Culture).TextInfo.ToTitleCase($nextChTitle)
                    
                    if ($Language -eq "he" -and $ChapterTranslations.ContainsKey($nextChTitle)) {
                        $nextChTitle = $ChapterTranslations[$nextChTitle]
                    }
                    
                    # Construct link to next chapter's Section I
                    $nextLink = "../chapter_$nextChapterNum/section_i.html"
                    
                    # Try to get Section I title
                    $nextSecFile = Join-Path $nextChapter.FullName "section_i.txt"
                    $nextSecTitle = Get-SectionTitle -FilePath $nextSecFile
                    
                    if ($nextSecTitle) {
                        # Format: Chapter Title - Section I: Section Title
                        $nextLabel = "$nextChTitle - $($Loc['Section']) I: $nextSecTitle$nextArrow"
                    }
                    else {
                        $nextLabel = "$($Loc['NextChapter']): $nextChTitle$nextArrow"
                    }
                }
                else {
                    # Last chapter in part -> Link to Next Part
                    $currentPartIndex = [array]::IndexOf($partMappings, $part)
                    if ($currentPartIndex -lt $partMappings.Count - 1) {
                        $nextPart = $partMappings[$currentPartIndex + 1]
                        
                        # Find first chapter of next part to link directly to section_i
                        $nextPartSource = Join-Path $splitBookPath $nextPart.Source
                        if (Test-Path $nextPartSource) {
                            $nextPartChapters = Get-ChildItem $nextPartSource -Directory | Sort-Object Name
                            if ($nextPartChapters.Count -gt 0) {
                                $firstCh = $nextPartChapters[0]
                                $firstChNum = if ($firstCh.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
                                $nextLink = "../../$($nextPart.Target)/chapter_$firstChNum/section_i.html"
                                
                                # Try to get Section I title
                                $nextSecFile = Join-Path $firstCh.FullName "section_i.txt"
                                $nextSecTitle = Get-SectionTitle -FilePath $nextSecFile
                                if ($nextSecTitle) {
                                    $nextLabel = "$($nextPart.Title) - $($Loc['Section']) I: $nextSecTitle$nextArrow"
                                }
                                else {
                                    $nextLabel = "$($Loc['Start']) $($nextPart.Title)$nextArrow"
                                }
                            }
                        }
                        else {
                            # Fallback to index if no chapters found (unlikely)
                            $nextLink = "../../$($nextPart.Target)/index.html"
                            $nextLabel = "$($Loc['Start']) $($nextPart.Title)$nextArrow"
                        }                    
                    }
                    else {
                        # End of book
                        $nextLink = "../../../contents.html"
                        $nextLabel = "$($Loc['TableOfContents'])$nextArrow"
                    }
                }
            }
            
            # Generate HTML
            # Generate sidebar content with correct relative path for sections (3 levels deep)
            $sectionSidebarContent = New-SidebarContent -PartDataList $allPartsData -RootPath "../../../"
            $html = New-SectionHTML -PartName $part.Target -PartTitle $part.Title -ChapterNum $chapterNum -ChapterTitle $chapterTitle -SectionNum $sectionNum -Content $content -PrevLink $prevLink -PrevLabel $prevLabel -NextLink $nextLink -NextLabel $nextLabel -SectionList $chapterSectionList -ChapterList $completeChapterList -PartList $partMappings -Footnotes $footnotes -SidebarContent $sectionSidebarContent
            
            $outputFile = Join-Path $chapterPath $section.Name.Replace('.txt', '.html')
            $html | Set-Content $outputFile -Encoding UTF8
            $totalSections++
        }
        $totalChapters++
    }
    
    # Generate part index
    $partSidebarContent = New-SidebarContent -PartDataList $allPartsData -RootPath "../../"
    $partIndexHtml = New-PartIndexHTML -PartName $part.Target -PartTitle $part.Title -Chapters $chapterList -PartList $partMappings -SidebarContent $partSidebarContent
    $partIndexHtml | Set-Content (Join-Path $targetPath "index.html") -Encoding UTF8
    
    Write-Host "Processed $($part.Title): $($chapters.Count) chapters" -ForegroundColor Cyan
}

# --- SEARCH INDEX GENERATION ---
Write-Host "Generating Search Index..." -ForegroundColor Cyan
$searchIndex = @()

foreach ($part in $allPartsData) {
    foreach ($ch in $part.Chapters) {
        foreach ($sec in $ch.Sections) {
            # Construct URL
            $url = "parts/$($part.Target)/$($ch.Folder)/$($sec.Filename)"
            
            # Read content from generated HTML file
            $secPath = Join-Path "$websitePath\parts\$($part.Target)\$($ch.Folder)" $sec.Filename
            if (Test-Path $secPath) {
                $rawHtml = Get-Content $secPath -Raw -Encoding UTF8
                # Extract content from content-card div and strip HTML tags
                if ($rawHtml -match '<div class="content-card">([\s\S]*?)</div>\s*<div class="page-nav">') {
                    $contentHtml = $matches[1]
                }
                else {
                    $contentHtml = $rawHtml
                }
                # Strip HTML tags and normalize whitespace
                $cleanText = $contentHtml -replace '<[^>]+>', ' ' -replace '\s+', ' '
                # Truncate to reasonable size for search
                if ($cleanText.Length -gt 2000) {
                    $cleanText = $cleanText.Substring(0, 2000)
                }
                
                $searchIndex += @{
                    id      = "$($part.Target)-$($ch.Folder)-$($sec.Num)"
                    title   = "Section $($sec.Num): $($sec.Title)"
                    part    = $part.Title
                    chapter = $ch.Title
                    url     = $url
                    content = $cleanText.Trim()
                }
            }
        }
    }
}

$searchIndexJson = $searchIndex | ConvertTo-Json -Depth 3 -Compress
$searchIndexJson | Set-Content (Join-Path $websitePath "search_index.json") -Encoding UTF8

# Generate Search Page with embedded index
Write-Host "Generating Search Page..." -ForegroundColor Cyan
$searchSidebarContent = New-SidebarContent -PartDataList $allPartsData -RootPath ""

# Calculate asset depth for search page (root)
$assetDepth = if ($Language -eq "he") { "../" } else { "" }

$searchPageHtml = @"
<!DOCTYPE html>
<html lang="$($Loc['Lang'])" dir="$($Loc['Dir'])">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Loc['Search']) — $($Loc['BookTitle'])</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="manifest" href="${assetDepth}manifest.json">
    <link rel="stylesheet" href="${assetDepth}styles.css">
</head>
<body>
    <!-- Sidebar - Content Embedded -->
    <div id="sidebar-container">$searchSidebarContent</div>
    <div id="sidebar-overlay"></div>

    <header>
        <button id="sidebar-toggle" aria-label="Open Navigation" style="font-size:1.5rem; background:none; border:none; color:inherit; cursor:pointer; margin-right:10px;">☰</button>
        <button id="theme-toggle" aria-label="$($Loc['ToggleDarkMode'])">🌙</button>
        <button id="lang-toggle" aria-label="$($Loc['LangToggleLabel'])">
            <span class="lang-icon">🌐</span>
            <span class="lang-text">$($Loc['LangToggleText'])</span>
        </button>
        <h1>$($Loc['BookTitle'])</h1>
        <p class="subtitle">$($Loc['Search'])</p>
    </header>
    <nav>
        <a href="index.html">$($Loc['Home'])</a>
        <a href="contents.html">$($Loc['Contents'])</a>
        <a href="search.html" class="active">$($Loc['Search'])</a>
    </nav>
    <main class="container">
        <div class="content-card">
            <h3>$($Loc['Search'])</h3>
            <input type="text" id="search-input" placeholder="$($Loc['TypeToSearch'])" style="width:100%; padding:1rem; font-size:1.1rem; border:2px solid var(--accent-gold); border-radius:8px; margin-bottom:1rem; font-family:'Lora',serif;">
            <div id="search-results"></div>
        </div>
    </main>
    <footer>
        <p>$($Loc['FooterText'])</p>
    </footer>
    <script src="${assetDepth}sidebar.js"></script>
    <script src="${assetDepth}language_toggle.js"></script>
    <script>
        // Theme Toggle
        const toggleBtn = document.getElementById('theme-toggle');
        const body = document.body;
        if (localStorage.getItem('theme') === 'dark') {
            body.classList.add('dark-mode');
            toggleBtn.textContent = '☀️';
        } else {
            toggleBtn.textContent = '🌙';
        }
        toggleBtn.addEventListener('click', () => {
            body.classList.toggle('dark-mode');
            if (body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
                toggleBtn.textContent = '☀️';
            } else {
                localStorage.setItem('theme', 'light');
                toggleBtn.textContent = '🌙';
            }
        });

        // Embedded Search Index
        const searchIndex = $searchIndexJson;

        // Search Logic
        const searchInput = document.getElementById('search-input');
        const searchResults = document.getElementById('search-results');

        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase().trim();
            if (query.length < 2) {
                searchResults.innerHTML = '<p style="color:#999;">$($Loc['TypeTwoChars'])</p>';
                return;
            }

            const results = searchIndex.filter(item =>
                item.title.toLowerCase().includes(query) ||
                (item.content && item.content.toLowerCase().includes(query))
            ).slice(0, 15);

            if (results.length === 0) {
                searchResults.innerHTML = '<p style="color:#999;">$($Loc['NoResults'])</p>';
            } else {
                searchResults.innerHTML = results.map(item => {
                    let snippet = '';
                    if (item.content) {
                        const idx = item.content.toLowerCase().indexOf(query);
                        const start = Math.max(0, idx - 40);
                        const end = Math.min(item.content.length, idx + 100);
                        snippet = item.content.substring(start, end) + '...';
                        snippet = snippet.replace(new RegExp(query, 'gi'), match => '<mark>' + match + '</mark>');
                    }
                    return '<div class="search-result-item"><a href="' + item.url + '"><strong>' + item.title + '</strong><span class="result-path">' + item.part + ' > ' + item.chapter + '</span><p>' + snippet + '</p></a></div>';
                }).join('');
            }
        });

        // Auto-focus
        searchInput.focus();
    </script>
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('${assetDepth}service-worker.js').then(registration => {
                    console.log('SW registered: ', registration.scope);
                }).catch(err => {
                    console.log('SW registration failed: ', err);
                });
            });
        }
    </script>
</body>
</html>
"@
$searchPageHtml | Set-Content (Join-Path $websitePath "search.html") -Encoding UTF8

# Generate Sidebar Content
Write-Host "Generating Sidebar Content..." -ForegroundColor Cyan
$sidebarContent = New-SidebarContent -PartDataList $allPartsData
$sidebarContent | Set-Content (Join-Path $websitePath "sidebar_content.html") -Encoding UTF8

# Generate main contents page
$mainContentsHtml = New-MainContentsHTML -PartDataList $allPartsData -SidebarContent $sidebarContent
$mainContentsHtml | Set-Content (Join-Path $websitePath "contents.html") -Encoding UTF8

# Generate Bibliography
$bibContentPath = Join-Path $websitePath "bibliography_content.html"
if (Test-Path $bibContentPath) {
    $bibRaw = Get-Content $bibContentPath -Raw -Encoding UTF8
    $bibHtml = New-BibliographyPage -Content $bibRaw -SidebarContent $sidebarContent
    $bibHtml | Set-Content (Join-Path $websitePath "bibliography.html") -Encoding UTF8
    Write-Host "Generated Bibliography" -ForegroundColor Cyan
}

# Generate Glossary
$glossContentPath = Join-Path $websitePath "glossary_content.html"
if (Test-Path $glossContentPath) {
    $glossRaw = Get-Content $glossContentPath -Raw -Encoding UTF8
    $glossHtml = New-GlossaryPage -Content $glossRaw -SidebarContent $sidebarContent
    $glossHtml | Set-Content (Join-Path $websitePath "glossary.html") -Encoding UTF8
    Write-Host "Generated Glossary" -ForegroundColor Cyan
}

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Total chapters: $totalChapters"
Write-Host "Total sections: $totalSections"

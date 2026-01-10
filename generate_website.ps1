# Generate HTML pages for all sections in the Torah Book of Ideas
# This script reads section text files and generates corresponding HTML pages

$splitBookPath = "c:\myantigravity\cantorwilliam\src\tboi\split_book"
$websitePath = "c:\myantigravity\cantorwilliam\src\tboi"
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

# HTML template function
function Generate-SectionHTML {
    param(
        [string]$PartName,
        [string]$PartTitle,
        [string]$ChapterNum,
        [string]$ChapterTitle,
        [string]$SectionNum,
        [string]$Content,
        [string]$PrevLink,
        [string]$NextLink,
        [string]$NextLabel,
        [array]$SectionList,
        [array]$ChapterList,
        [array]$PartList,
        [hashtable]$Footnotes
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
    
    # Calculate relative path depth
    $depth = "../../../"
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ChapterTitle — Section $SectionNum</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="${depth}styles.css">
</head>
<body>
    <header>
        <h1>The Torah Book of Ideas</h1>
        <p class="subtitle">$PartTitle</p>
    </header>
    <nav>
        <a href="${depth}index.html">Home</a>
        <a href="${depth}contents.html">Contents</a>
        <a href="../index.html" class="active">$PartTitle</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="${depth}index.html">Home</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="../index.html">$PartTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $PartList) {
                            $activeClass = if ($p.Target -eq $PartName) { "class='active'" } else { "" }
                            # Path to part index from current section (depth is ../../../)
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
                <a href="section_i.html">Section $SectionNum</a>
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
            <h3>Section $SectionNum$sectionTitleText</h3>
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
            <a href="$PrevLink" class="nav-btn prev">Previous</a>
            <a href="$NextLink" class="nav-btn next">$NextLabel</a>
        </div>
    </main>
    <footer>
        <p>The Torah Book of Ideas — A journey through wisdom, faith, and understanding</p>
    </footer>
</body>
</html>
"@
    return $html
}

# Part index page template
function Generate-PartIndexHTML {
    param(
        [string]$PartName,
        [string]$PartTitle,
        [array]$Chapters,
        [array]$PartList
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
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$PartTitle — The Torah Book of Ideas</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="../../styles.css">
</head>
<body>
    <header>
        <h1>The Torah Book of Ideas</h1>
        <p class="subtitle">$PartTitle</p>
    </header>
    <nav>
        <a href="../../index.html">Home</a>
        <a href="../../contents.html">Contents</a>
        <a href="index.html" class="active">$PartTitle</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="../../index.html">Home</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="index.html">$PartTitle</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $PartList) {
                            $activeClass = if ($p.Target -eq $PartName) { "class='active'" } else { "" }
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
                <h3>Chapters</h3>
                <div class="toc-chapters">
$chapterLinks
                </div>
            </div>
        </div>
    </main>
    <footer>
        <p>The Torah Book of Ideas — A journey through wisdom, faith, and understanding</p>
    </footer>
</body>
</html>
"@
    return $html
}

# Full table of contents template
function Generate-MainContentsHTML {
    param(
        [array]$PartDataList
    )
    
    $fullContents = ""
    foreach ($part in $PartDataList) {
        $chapterLinks = ""
        foreach ($ch in $part.Chapters) {
            $sectionLinks = ""
            foreach ($sec in $ch.Sections) {
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
        
        $fullContents += @"
                <details class="toc-part-group" open style="margin-bottom: 2rem;">
                    <summary class="toc-part-title" style="cursor: pointer; list-style: none; margin-bottom: 1rem;">
                        <span style="font-size: 1.5rem; color: var(--gold-primary); font-family: 'Frank Ruhl Libre', serif; border-bottom: 1px solid rgba(212, 175, 55, 0.3); padding-bottom: 0.5rem; display: inline-block; width: 100%;">$($part.Title)</span>
                    </summary>
                    <div style="margin-bottom: 1rem; margin-left: 1rem;">
                        <a href="parts/$($part.Target)/index.html" style="font-size: 0.9rem; font-style: italic; color: var(--text-muted);">View Part Index →</a>
                    </div>
                    <div class="toc-chapters" style="display: block; padding-left: 0;">
$chapterLinks
                    </div>
                </details>
"@
    }
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Table of Contents — The Torah Book of Ideas</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <header>
        <h1>The Torah Book of Ideas</h1>
        <p class="subtitle">Table of Contents</p>
    </header>
    <nav>
        <a href="index.html">Home</a>
        <a href="contents.html" class="active">Table of Contents</a>
    </nav>
    <main class="container">
        <div class="content-card">
            <h2>✡ Contents ✡</h2>
            <div class="toc">
$fullContents
            </div>
        </div>
    </main>
    <footer>
        <p>The Torah Book of Ideas — A journey through wisdom, faith, and understanding</p>
    </footer>
</body>
</html>
"@
    return $html
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
    $chapterList = @()
    
    foreach ($chapter in $chapters) {
        $chapterNum = if ($chapter.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
        $chapterTitle = ($chapter.Name -replace 'chapter_\d+-', '' -replace '-', ' ').Trim()
        $chapterTitle = (Get-Culture).TextInfo.ToTitleCase($chapterTitle)
        $chapterTitle = "Chapter $([int]$chapterNum): $chapterTitle"
        
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
        $chapterIndexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ChapterTitle — Index</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Frank+Ruhl+Libre:wght@400;700&family=Lora:ital,wght@0,400;0,600;1,400&family=Playfair+Display:wght@400;600;700&display=swap" rel="stylesheet">
    <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    <link rel="stylesheet" href="../../../styles.css">
</head>
<body>
    <header>
        <h1>The Torah Book of Ideas</h1>
        <p class="subtitle">$($part.Title)</p>
    </header>
    <nav>
        <a href="../../../index.html">Home</a>
        <a href="../../../contents.html">Contents</a>
        <a href="../index.html" class="active">$($part.Title)</a>
    </nav>
    <main class="container">
        <div class="breadcrumb">
            <div class="breadcrumb-item">
                <a href="../../../index.html">Home</a>
            </div>
            <span class="separator">›</span>
            <div class="breadcrumb-item has-dropdown">
                <a href="../index.html">$($part.Title)</a>
                <div class="breadcrumb-dropdown">
                    $(
                        $pLinks = ""
                        foreach ($p in $partMappings) {
                            $activeClass = if ($p.Target -eq $part.Target) { "class='active'" } else { "" }
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
                        foreach ($c in $chapterList) {
                            $activeClass = if ($c.Num -eq $chapterNum) { "class='active'" } else { "" }
                            # Link to chapter index
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
                <h3>Sections</h3>
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
        <p>The Torah Book of Ideas — A journey through wisdom, faith, and understanding</p>
    </footer>
</body>
</html>
"@
        $chapterIndexHtml | Set-Content (Join-Path $chapterPath "index.html") -Encoding UTF8
        
        for ($i = 0; $i -lt $sections.Count; $i++) {
            $section = $sections[$i]
            $sectionNum = if ($section.Name -match 'section_([ivx]+)\.txt') { $romanNumerals[$matches[1]] } else { "I" }
            $content = Get-Content $section.FullName -Raw -Encoding UTF8
            
            # Determine prev/next links
            $sectionFilename = $section.Name.Replace('.txt', '.html')
            
            # Determine prev/next links and labels
            if ($i -eq 0) {
                # First section of the chapter
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
                            }
                            else {
                                $prevLink = "../../$($prevPart.Target)/index.html"
                            }
                        }
                        else {
                            $prevLink = "../../$($prevPart.Target)/index.html"
                        }
                    }
                    else {
                        # First Part of Book
                        $prevLink = "../../../contents.html"
                    }
                }
            }
            else {
                $prevLink = $chapterSectionList[$i - 1].Filename
            }            
            $nextLink = ""
            $nextLabel = "Next"
            
            if ($i -lt $sections.Count - 1) {
                # Next section in same chapter
                $nextLink = $chapterSectionList[$i + 1].Filename
                $nextLabel = "Next Section"
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
                    
                    # Construct link to next chapter's Section I
                    $nextLink = "../chapter_$nextChapterNum/section_i.html"
                    $nextLabel = "Next Chapter: $nextChTitle"
                }
                else {
                    # Last chapter in part -> Link to Next Part
                    $currentPartIndex = [array]::IndexOf($partMappings, $part)
                    if ($currentPartIndex -lt $partMappings.Count - 1) {
                        $nextPart = $partMappings[$currentPartIndex + 1]
                        
                        # Find first chapter of next part to link directly to section_i
                        $nextPartSource = Join-Path $splitBookPath $nextPart.Source
                        $nextPartChapters = Get-ChildItem $nextPartSource -Directory | Sort-Object Name
                        if ($nextPartChapters.Count -gt 0) {
                            $firstCh = $nextPartChapters[0]
                            $firstChNum = if ($firstCh.Name -match 'chapter_(\d+)') { $matches[1] } else { "00" }
                            $nextLink = "../../$($nextPart.Target)/chapter_$firstChNum/section_i.html"
                            $nextLabel = "Start $($nextPart.Title)"
                        }
                        else {
                            # Fallback to index if no chapters found (unlikely)
                            $nextLink = "../../$($nextPart.Target)/index.html"
                            $nextLabel = "Start $($nextPart.Title)"
                        }                    
                    }
                    else {
                        # End of book
                        $nextLink = "../../../contents.html"
                        $nextLabel = "Table of Contents"
                    }
                }
            }
            
            # Generate HTML
            $html = Generate-SectionHTML -PartName $part.Target -PartTitle $part.Title -ChapterNum $chapterNum -ChapterTitle $chapterTitle -SectionNum $sectionNum -Content $content -PrevLink $prevLink -NextLink $nextLink -NextLabel $nextLabel -SectionList $chapterSectionList -ChapterList $chapterList -PartList $partMappings -Footnotes $footnotes
            
            $outputFile = Join-Path $chapterPath $section.Name.Replace('.txt', '.html')
            $html | Set-Content $outputFile -Encoding UTF8
            $totalSections++
        }
        $totalChapters++
    }
    
    # Generate part index
    $partIndexHtml = Generate-PartIndexHTML -PartName $part.Target -PartTitle $part.Title -Chapters $chapterList -PartList $partMappings
    $partIndexHtml | Set-Content (Join-Path $targetPath "index.html") -Encoding UTF8
    
    Write-Host "Processed $($part.Title): $($chapters.Count) chapters" -ForegroundColor Cyan
    
    # Store for main contents
    $allPartsData += @{ Target = $part.Target; Title = $part.Title; Chapters = $chapterList }
}

# Generate main contents page
$mainContentsHtml = Generate-MainContentsHTML -PartDataList $allPartsData
$mainContentsHtml | Set-Content (Join-Path $websitePath "contents.html") -Encoding UTF8

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Total chapters: $totalChapters"
Write-Host "Total sections: $totalSections"

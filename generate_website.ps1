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
        [hashtable]$Footnotes
    )
    
    # Clean and format content
    $lines = $Content -split "`r?`n" | Where-Object { $_.Trim() -ne '' -and $_.Trim() -ne '·' -and $_.Trim() -ne '●' }
    $paragraphs = @()
    $currentPara = ""
    
    $pageFootnotes = @()
    
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
        elseif ($trimmed -match '^<(div|blockquote|aside|/div|/blockquote|/aside)') {
            # Raw HTML pass-through for manual layout
            if ($currentPara.Trim()) {
                $paragraphs += "<p>$($currentPara.Trim())</p>"
                $currentPara = ""
            }
            $paragraphs += $trimmed
        }
        else {
            $currentPara += "$trimmed "
        }
        
        # Check for sentence endings to potentially break paragraphs
        if ($currentPara.Length -gt 500 -and $trimmed -match '\.$') {
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
            <a href="${depth}index.html">Home</a>
            <span class="separator">›</span>
            <a href="../index.html">$PartTitle</a>
            <span class="separator">›</span>
            <span>$ChapterTitle</span>
            <span class="separator">›</span>
            <div class="section-selector">
                Section $SectionNum
                <div class="section-dropdown">
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
            <h3>Section $SectionNum</h3>
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
        [array]$Chapters
    )
    
    $chapterLinks = ""
    foreach ($ch in $Chapters) {
        $chapterLinks += "                    <a href=`"$($ch.Folder)/section_i.html`">$($ch.Title)</a>`n"
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
            <a href="../../index.html">Home</a>
            <span class="separator">›</span>
            <span>$PartTitle</span>
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
    @{Source = "part_iii-politics"; Target = "part_iii_politics"; Title = "Part III — Politics" },
    @{Source = "part_iv-ideas"; Target = "part_iv"; Title = "Part IV — Ideas" },
    @{Source = "part_v-christianity"; Target = "part_v"; Title = "Part V — Christianity" }
)

$totalSections = 0
$totalChapters = 0

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
        $chapterPath = Join-Path $targetPath $chapterFolder
        New-Item -ItemType Directory -Path $chapterPath -Force | Out-Null
        
        $chapterList += @{Folder = $chapterFolder; Title = $chapterTitle; Num = $chapterNum }
        
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
            $chapterSectionList += @{ Num = $secNumStr; Filename = $secFilename }
        }
        
        for ($i = 0; $i -lt $sections.Count; $i++) {
            $section = $sections[$i]
            $sectionNum = if ($section.Name -match 'section_([ivx]+)\.txt') { $romanNumerals[$matches[1]] } else { "I" }
            $content = Get-Content $section.FullName -Raw -Encoding UTF8
            
            # Determine prev/next links
            $sectionFilename = $section.Name.Replace('.txt', '.html')
            
            # Determine prev/next links and labels
            $prevLink = if ($i -eq 0) { "../index.html" } else { $chapterSectionList[$i - 1].Filename }
            
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
                    # Assume section_i.html exists for next chapter
                    $nextLink = "../$($nextChapter.Name.Split('-')[0])/section_i.html" 
                    # Note: Folder name logic in script loop was manual 'chapter_$chapterNum'
                    # Better: use the loop variables we already have
                    # Actually we are inside chapter loop. Let's look at $chapterList
                     
                    # Simple logic: We don't have easy access to next chapter's folder name in this scope without re-deriving
                    # But we know $chapterList is being built.
                    # Wait, $chapterList is incomplete in current iteration.
                     
                    # Simpler: Link to Part Index
                    $nextLink = "../index.html"
                    $nextLabel = "Next Chapter (Index)"
                }
                else {
                    # Last chapter in part -> Link to Table of Contents or Next Part
                    $nextLink = "../../../contents.html"
                    $nextLabel = "Table of Contents"
                }
            }
            
            # Generate HTML
            $html = Generate-SectionHTML -PartName $part.Target -PartTitle $part.Title -ChapterNum $chapterNum -ChapterTitle $chapterTitle -SectionNum $sectionNum -Content $content -PrevLink $prevLink -NextLink $nextLink -NextLabel $nextLabel -SectionList $chapterSectionList -Footnotes $footnotes
            
            $outputFile = Join-Path $chapterPath $section.Name.Replace('.txt', '.html')
            $html | Set-Content $outputFile -Encoding UTF8
            $totalSections++
        }
        $totalChapters++
    }
    
    # Generate part index
    $partIndexHtml = Generate-PartIndexHTML -PartName $part.Target -PartTitle $part.Title -Chapters $chapterList
    $partIndexHtml | Set-Content (Join-Path $targetPath "index.html") -Encoding UTF8
    
    Write-Host "Processed $($part.Title): $($chapters.Count) chapters" -ForegroundColor Cyan
}

Write-Host "`n=== COMPLETE ===" -ForegroundColor Green
Write-Host "Total chapters: $totalChapters"
Write-Host "Total sections: $totalSections"

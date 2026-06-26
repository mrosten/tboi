param(
    [ValidateSet('en', 'he')]
    [string]$Language = 'he',          # Default to Hebrew for this task
    [Parameter(Mandatory = $true)]
    [string]$FilePath                  # Relative path to HTML file, e.g. parts/part_i/chapter_09/section_ii.html
)

$ErrorActionPreference = 'Stop'
Write-Host "Starting Quick Build for $FilePath ($Language)..."

# 1. Setup Paths (Relative to script folder)
if ($PSBoundParameters.ContainsKey('PSCommandPath')) {
    $scriptRoot = Split-Path -Parent $PSBoundParameters['PSCommandPath']
}
if (-not $scriptRoot) {
    if ($PSScriptRoot) {
        $scriptRoot = $PSScriptRoot
    }
    elseif ($MyInvocation -and $MyInvocation.MyCommand.Path) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $scriptRoot = (Get-Location).Path
    }
}
$rootDir = $scriptRoot

# Handle language-specific output paths
# Hebrew goes to src\tboi\he\...
# English goes to src\tboi\... (Root)
if ($Language -eq 'he') {
    $destFile = Join-Path $rootDir "he\$FilePath"
    $splitBookDir = Join-Path $rootDir "split_book_he"
}
else {
    $destFile = Join-Path $rootDir $FilePath
    $splitBookDir = Join-Path $rootDir "split_book"
}

$destDir = Split-Path $destFile -Parent

# Source text file logic
$filename = Split-Path $FilePath -LeafBase
$chapterFolder = (Split-Path $FilePath -Parent) | Split-Path -Leaf

# Find the specific text file
$srcFileObj = Get-ChildItem -Path $splitBookDir -Recurse -Filter "$filename.txt" | Where-Object { $_.Directory.Name -like "*$chapterFolder*" } | Select-Object -First 1

if (-not $srcFileObj) {
    Write-Error "Could not find source text file for $filename in $splitBookDir matching chapter $chapterFolder"
    exit 1
}
$srcFile = $srcFileObj.FullName
Write-Host "Found source: $srcFile"

# 2. Read Source Content and Process
$content = Get-Content -Path $srcFile -Raw -Encoding UTF8
Write-Host "Read $($content.Length) chars from $srcFile"

# --- Convert content to HTML Fragment ---
# Handle Title
$content = $content -replace '\[TITLE:\s*(.*?)\]', '<h1>$1</h1>'

# Handle Images
# English (parts/part_i/chapter_09/section_ii.html) -> 3 levels up (../../..)
# Hebrew (he/parts/part_i/chapter_09/section_ii.html) -> 4 levels up (../../../..)
if ($Language -eq 'he') {
    $depth = "../../../.."
}
else {
    $depth = "../../.."
}

$content = $content -replace '\[IMAGE:\s*(.*?)\]', "<div class='image-container'><img src='$depth/images/`$1' alt='Book Image' class='book-image'></div>"
Write-Host "Content length after processing: $($content.Length) chars"

# Simple formatting
$content = $content -replace '\*\*(.*?)\*\*', '<strong>$1</strong>'
$content = $content -replace '\*(.*?)\*', '<em>$1</em>'

# 3. Inject into Existing HTML
if (-not (Test-Path $destFile)) {
    Write-Error "Destination HTML file not found: $destFile. Run full build first to generate key structure."
    exit 1
}

$html = Get-Content -Path $destFile -Raw -Encoding UTF8

# Regex to find the content area
# We look for <main> ... </main> but specifically want to replace the body of it BEFORE the page-nav.
# Pattern: Find (Start of Main or after sidebar) ... (Page Nav)
# We'll use a precise split on <div class="page-nav"> and the H1 tag or similar.

# Strategy: Find everything before the FIRST <h1> (which corresponds to [TITLE]) inside the file (ignoring sidebar h3/h4)
# Actually, sidebar has h3/h4. The main content usually starts with <h1>.
# Let's locate the <main> tag.

$mainStartIdx = $html.IndexOf("<main")
if ($mainStartIdx -eq -1) {
    Write-Error "Could not find <main> tag in $destFile"
    exit 1
}

# Find the CLOSING bracket of <main ... >
$mainTagEndIdx = $html.IndexOf(">", $mainStartIdx)
if ($mainTagEndIdx -eq -1) {
    Write-Error "Could not find closing bracket of <main> tag"
    exit 1
}

# Check for validation: does main have container class?
$mainTagContent = $html.Substring($mainStartIdx, $mainTagEndIdx - $mainStartIdx + 1)
# Regex to check if 'container' is inside a class attribute
# Matches: class="...container..." or class='...container...'
if ($mainTagContent -notmatch "class\s*=\s*['`"][^'`"]*container") {
    Write-Warning "The <main> tag was missing 'container' class (strict check). Fixing it."
    
    $preMain = $html.Substring(0, $mainTagEndIdx + 1)
    
    if ($preMain -match "<main\s*>") {
        $preMain = $preMain -replace "<main\s*>", "<main class='container'>"
    }
    elseif ($preMain -match "class\s*=\s*['`"]") {
        # Has class but not container? Append to class.
        # This is complex to regex replace safely.
        # Easiest: If it has class, maybe just add container?
        # But usually <main> has no other classes in this project.
        # So fallback to appending class attribute if it doesn't have class="container"
        # But wait, if it has class="foo", we want class="foo container".
        # For now, simplistic approach: if it has attributes but not class container,
        # we might just replace the whole tag if we can identify it, OR
        # just append class='container' which is invalid if class already exists.
        # Given the project scope, <main> is simple.
        # If strict check failed, and we are here:
        # Assume we need to ADD it.
        if ($preMain -notmatch "class=") {
            $preMain = $preMain.Substring(0, $preMain.Length - 1) + " class='container'>"
        }
        else {
            # Has class but not container. Append container to class?
            # Too risky to parse with regex. PROPOSE USER WARNING instead?
            # Or just replace class=" with class="container 
            $preMain = $preMain -replace "class\s*=\s*['`"]", "class='container "
        }
    }
    else {
        # Has attributes (like id) but NO class.
        $preMain = $preMain.Substring(0, $preMain.Length - 1) + " class='container'>"
    }
}
else {
    $preMain = $html.Substring(0, $mainTagEndIdx + 1)
}

# Find <div class="page-nav"> OR <div class='page-nav'>
$pageNavIdx = $html.IndexOf('<div class="page-nav">')
if ($pageNavIdx -eq -1) {
    $pageNavIdx = $html.IndexOf("<div class='page-nav'>")
}

if ($pageNavIdx -eq -1) {
    Write-Error "Could not find <div class='page-nav'> (checked single/double quotes) in $destFile"
    exit 1
}

# Check if pageNav is AFTER main
if ($pageNavIdx -lt $mainTagEndIdx) {
    Write-Error "Found page-nav BEFORE main content start? Something is wrong."
    exit 1
}

# Extract parts
$preMain = $html.Substring(0, $mainTagEndIdx + 1) # Includes <main ... >
$postContent = $html.Substring($pageNavIdx)        # Includes <div class="page-nav"> ...

# Construct new HTML
$newHtml = $preMain + "`n" + $content + "`n" + $postContent

Set-Content -Path $destFile -Value $newHtml -Encoding UTF8
Write-Host "Updated HTML content in $destFile"

# 4. Copy Assets
# Correct path for images based on Language
if ($Language -eq 'he') {
    $imagesDir = Join-Path $rootDir "he\images"
    $cssDest = Join-Path $rootDir "he\styles.css"
}
else {
    $imagesDir = Join-Path $rootDir "images"
    $cssDest = $null # styles.css is already in root for English
}

if (-not (Test-Path $imagesDir)) { New-Item -Type Directory -Path $imagesDir -Force | Out-Null }

# Copy Images (Skip if src == dest)
$srcImages = Join-Path $rootDir "images"
if ($srcImages -ne $imagesDir) {
    Copy-Item -Path "$srcImages\*" -Destination $imagesDir -Recurse -Force
    Write-Host "Copied images to $imagesDir"
}
else {
    Write-Host "Skipping image copy (Source == Destination)"
}

if ($cssDest) {
    Copy-Item -Path (Join-Path $rootDir "styles.css") -Destination $cssDest -Force
    Write-Host "Copied styles.css to $cssDest"
}

Write-Host "Done."

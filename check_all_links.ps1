# Comprehensive check for broken links in both English and Hebrew sites
# Checks all href attributes that point to local .html files

param(
    [switch]$Verbose = $false
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$sitePaths = @(
    @{ Name = "English"; Path = Join-Path $scriptRoot "parts"; Root = $scriptRoot },
    @{ Name = "Hebrew"; Path = Join-Path $scriptRoot "he\parts"; Root = Join-Path $scriptRoot "he" }
)

$brokenLinks = @()
$totalChecked = 0
$totalLinks = 0

foreach ($site in $sitePaths) {
    if (-not (Test-Path $site.Path)) {
        Write-Host "Skipping $($site.Name) - path not found: $($site.Path)" -ForegroundColor Yellow
        continue
    }
    
    Write-Host "`n=== Checking $($site.Name) site ===" -ForegroundColor Cyan
    
    $htmlFiles = Get-ChildItem -Path $site.Path -Recurse -Filter "*.html"
    
    foreach ($file in $htmlFiles) {
        $totalChecked++
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        
        # Find all href attributes pointing to .html files
        $pattern = 'href="([^"]*\.html)"'
        $matches = [regex]::Matches($content, $pattern)
        
        foreach ($match in $matches) {
            $href = $match.Groups[1].Value
            $totalLinks++
            
            # Skip external links
            if ($href -match "^(https?://|mailto:|#)") {
                continue
            }
            
            # Resolve relative path
            $fileDir = Split-Path $file.FullName -Parent
            $targetPath = Join-Path $fileDir $href
            $targetPath = [System.IO.Path]::GetFullPath($targetPath)
            
            # Normalize path separators
            $targetPath = $targetPath -replace '/', '\'
            
            if (-not (Test-Path $targetPath)) {
                $brokenLinks += [PSCustomObject]@{
                    Site         = $site.Name
                    SourceFile   = $file.FullName.Replace($scriptRoot, ".")
                    BrokenHref   = $href
                    ExpectedPath = $targetPath.Replace($scriptRoot, ".")
                    LineInFile   = ($content.Substring(0, $match.Index).Split("`n")).Count
                }
            }
        }
    }
}

Write-Host "`n" 
Write-Host "================================" -ForegroundColor Yellow
Write-Host "COMPREHENSIVE BROKEN LINK REPORT" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Total files checked: $totalChecked"
Write-Host "Total links checked: $totalLinks"
Write-Host "Total broken links found: $($brokenLinks.Count)"

if ($brokenLinks.Count -gt 0) {
    Write-Host "`nBroken links:" -ForegroundColor Red
    
    # Group by site
    $grouped = $brokenLinks | Group-Object -Property Site
    
    foreach ($group in $grouped) {
        Write-Host "`n--- $($group.Name) Site ---" -ForegroundColor Magenta
        
        # Group by source file to reduce output
        $byFile = $group.Group | Group-Object -Property SourceFile
        
        foreach ($fileGroup in $byFile) {
            Write-Host "`n  File: $($fileGroup.Name)" -ForegroundColor White
            
            foreach ($link in $fileGroup.Group) {
                Write-Host "    Line ~$($link.LineInFile): $($link.BrokenHref)" -ForegroundColor Red
            }
        }
    }
    
    # Export to JSON for further processing
    $reportPath = Join-Path $scriptRoot "broken_links_full_report.json"
    $brokenLinks | ConvertTo-Json -Depth 3 | Out-File $reportPath -Encoding UTF8
    Write-Host "`nFull report saved to: $reportPath" -ForegroundColor Green
}
else {
    Write-Host "`nNo broken links found!" -ForegroundColor Green
}

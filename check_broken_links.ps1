# Check for broken prev/next navigation links in both English and Hebrew sites
# Outputs a report of all broken links found

param(
    [switch]$Fix = $false
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$sitePaths = @(
    @{ Name = "English"; Path = Join-Path $scriptRoot "parts"; Root = $scriptRoot },
    @{ Name = "Hebrew"; Path = Join-Path $scriptRoot "he\parts"; Root = Join-Path $scriptRoot "he" }
)

$brokenLinks = @()
$totalChecked = 0

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
        
        # Find all nav-btn links (prev and next)
        $pattern = '<a\s+href="([^"]+)"\s+class="nav-btn\s+(prev|next)"'
        $matches = [regex]::Matches($content, $pattern)
        
        foreach ($match in $matches) {
            $href = $match.Groups[1].Value
            $direction = $match.Groups[2].Value
            
            # Skip external links and anchors
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
                    Site = $site.Name
                    SourceFile = $file.FullName.Replace($scriptRoot, ".")
                    Direction = $direction
                    BrokenHref = $href
                    ExpectedPath = $targetPath.Replace($scriptRoot, ".")
                }
            }
        }
    }
}

Write-Host "`n" 
Write-Host "================================" -ForegroundColor Yellow
Write-Host "BROKEN LINK REPORT" -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Yellow
Write-Host "Total files checked: $totalChecked"
Write-Host "Total broken links found: $($brokenLinks.Count)"

if ($brokenLinks.Count -gt 0) {
    Write-Host "`nBroken links:" -ForegroundColor Red
    
    # Group by site
    $grouped = $brokenLinks | Group-Object -Property Site
    
    foreach ($group in $grouped) {
        Write-Host "`n--- $($group.Name) Site ---" -ForegroundColor Magenta
        
        foreach ($link in $group.Group) {
            Write-Host "`n  File: $($link.SourceFile)" -ForegroundColor White
            Write-Host "    Direction: $($link.Direction)" -ForegroundColor Gray
            Write-Host "    Broken href: $($link.BrokenHref)" -ForegroundColor Red
            Write-Host "    Expected: $($link.ExpectedPath)" -ForegroundColor Yellow
        }
    }
    
    # Export to JSON for further processing
    $reportPath = Join-Path $scriptRoot "broken_links_report.json"
    $brokenLinks | ConvertTo-Json -Depth 3 | Out-File $reportPath -Encoding UTF8
    Write-Host "`nReport saved to: $reportPath" -ForegroundColor Green
} else {
    Write-Host "`nNo broken links found!" -ForegroundColor Green
}

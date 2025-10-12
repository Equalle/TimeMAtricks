param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

# Define branch name
$branch = "release-$Version"

Write-Host "==> Preparing release $Version ..." -ForegroundColor Cyan

# Ensure we're on main
git checkout main
git pull

# Create new branch
git checkout -b $branch

# Files you want to keep
$keepPatterns = @(
    "TimeMAtricks.lua",
    "TimeMAtricks.xml"
)

Write-Host "==> Cleaning up unnecessary files..." -ForegroundColor Yellow

# Remove everything except the files we want to keep
Get-ChildItem -Recurse | ForEach-Object {
    $keep = $false
    foreach ($pattern in $keepPatterns) {
        if ($_.Name -match $pattern) {
            $keep = $true
            break
        }
    }
    if (-not $keep -and $_.FullName -notmatch "\\.git") {
        try {
            Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop
        } catch {
            Write-Host "Skipping locked or protected file: $($_.FullName)"
        }
    }
}

# Remove release scripts (self-clean)
Remove-Item -Force "release.ps1" -ErrorAction SilentlyContinue
Remove-Item -Force "release.sh" -ErrorAction SilentlyContinue

# Stage and commit
git add .
git commit -m "Release $Version"

# Tag the release
git tag -a $Version -m "Release $Version"

# Push branch and tag
Write-Host "==> Pushing to origin..." -ForegroundColor Yellow
git push -u origin $branch
git push origin $Version

# Switch back to main and delete branch locally
git checkout main
git branch -D $branch

Write-Host "`n✅ Release $Version completed successfully!" -ForegroundColor Green
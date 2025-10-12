param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

Write-Host "==> Creating release branch for version $Version..."

git checkout main
git pull
$branch = "release-$Version"
git checkout -b $branch

Write-Host "==> Cleaning up unnecessary files..."
Get-ChildItem -Recurse | Where-Object {
    $_.Name -notmatch "TimeMAtricks\.lua|TimeMAtricks\.xml|release\.ps1|release\.sh|\.git"
} | Remove-Item -Force -Recurse

git add .
git commit -m "Release $Version"
git tag -a $Version -m "Release $Version"
git push -u origin $branch
git push origin $Version

git checkout main
git branch -D $branch

Write-Host "==> Release $Version completed!"
#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./release.sh <version>"
  exit 1
fi

VERSION=$1
BRANCH="release-$VERSION"

echo "==> Creating release branch for version $VERSION..."

git checkout main
git pull
git checkout -b "$BRANCH"

echo "==> Cleaning up unnecessary files..."
find . -type f ! -name "TimeMAtricks.lua" ! -name "TimeMAtricks.xml" \
  ! -name "release.ps1" ! -name "release.sh" ! -path "./.git/*" -delete

git add .
git commit -m "Release $VERSION"
git tag -a "$VERSION" -m "Release $VERSION"
git push -u origin "$BRANCH"
git push origin "$VERSION"

git checkout main
git branch -D "$BRANCH"

echo "==> Release $VERSION completed!"
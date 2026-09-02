#!/usr/bin/env bash
set -e

# Usage: sh deploy.sh -v 0.1.0

VERSION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version)
      VERSION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: sh deploy.sh -v <version>"
      exit 1
      ;;
  esac
done

if [ -z "$VERSION" ]; then
  PACKAGE_NAME=$(node -p "require('./package.json').name")
  echo "🔍 No version specified. Fetching latest version from NPM for $PACKAGE_NAME..."
  
  # Fetch latest version from NPM
  LATEST_VERSION=$(npm view "$PACKAGE_NAME" version 2>/dev/null || echo "")
  
  if [ -z "$LATEST_VERSION" ]; then
    echo "⚠️  Package not found on NPM. Falling back to local package.json patch increment."
    VERSION=$(npm version patch --no-git-tag-version)
    VERSION=${VERSION#v}
  else
    # Increment patch version
    IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST_VERSION"
    NEW_PATCH=$((PATCH + 1))
    VERSION="$MAJOR.$MINOR.$NEW_PATCH"
    echo "📈 Latest version on NPM is $LATEST_VERSION. Auto-incrementing to $VERSION"
  fi
fi

echo "🚀 Preparing deployment for version: $VERSION"

# 1. Update version in package.json
echo "📦 Updating package.json version to $VERSION..."
npm version "$VERSION" --allow-same-version --no-git-tag-version

# 2. Commit the version bump
echo "🔧 Committing version bump..."
git add package.json
git commit -m "chore(release): v$VERSION" || echo "No changes to commit"

# 3. Create a git tag
echo "🏷️  Creating git tag v$VERSION..."
git tag -a "v$VERSION" -m "Release v$VERSION" || echo "Tag already exists"

# 4. Publish to npm
echo "☁️  Publishing to NPM..."
npm publish --access public

# 5. Push to GitHub
echo "🔄 Pushing changes and tags to GitHub..."
git push origin master
git push origin "v$VERSION"

echo ""
echo "✅ Successfully deployed v$VERSION to NPM and pushed to GitHub!"

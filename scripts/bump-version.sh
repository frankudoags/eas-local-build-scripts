#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
  echo -e "${BLUE}Usage:${NC}"
  echo "  $0 <major|minor|patch>"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo "  $0 major    # 1.0.0 -> 2.0.0"
  echo "  $0 minor    # 1.0.0 -> 1.1.0"
  echo "  $0 patch    # 1.0.0 -> 1.0.1"
  exit 1
}

# Check if bump type is provided
if [ -z "$1" ]; then
  echo -e "${RED}❌ Error: Bump type not specified${NC}\n"
  usage
fi

BUMP_TYPE=$1

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
  echo -e "${RED}❌ Error: Invalid bump type '$BUMP_TYPE'${NC}"
  echo -e "${YELLOW}Must be one of: major, minor, patch${NC}\n"
  usage
fi

# Check if app.config.ts exists
if [ ! -f "app.config.ts" ]; then
  echo -e "${RED}❌ Error: app.config.ts not found${NC}"
  echo "Make sure you're running this script from the project root"
  exit 1
fi

echo -e "${BLUE}🔍 Reading current version from app.config.ts...${NC}"

# Extract current version from app.config.ts
CURRENT_VERSION=$(node -e "
  const fs = require('fs');
  const content = fs.readFileSync('app.config.ts', 'utf8');
  const versionMatch = content.match(/version: ['\"]([^'\"]*)['\"],?/);
  if (versionMatch) {
    console.log(versionMatch[1]);
  } else {
    console.error('Version not found');
    process.exit(1);
  }
")

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error: Could not extract version from app.config.ts${NC}"
  exit 1
fi

echo -e "${GREEN}Current version: ${CURRENT_VERSION}${NC}"

# Parse version into major, minor, patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Validate version format
if [[ ! "$MAJOR" =~ ^[0-9]+$ ]] || [[ ! "$MINOR" =~ ^[0-9]+$ ]] || [[ ! "$PATCH" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}❌ Error: Invalid version format '${CURRENT_VERSION}'${NC}"
  echo "Expected format: MAJOR.MINOR.PATCH (e.g., 1.0.0)"
  exit 1
fi

# Calculate new version based on bump type
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

echo -e "${BLUE}New version: ${NEW_VERSION}${NC}"

# Confirm the version bump
echo ""
echo -e "${YELLOW}⚠️  About to bump version:${NC}"
echo -e "  ${CURRENT_VERSION} -> ${NEW_VERSION}"
echo ""
read -p "Continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo -e "${YELLOW}❌ Version bump cancelled${NC}"
  exit 0
fi

# Update version in app.config.ts
echo -e "${BLUE}📝 Updating app.config.ts...${NC}"

# Create a backup
cp app.config.ts app.config.ts.backup

# Use Node.js to replace the version
node -e "
  const fs = require('fs');
  const content = fs.readFileSync('app.config.ts', 'utf8');
  const newContent = content.replace(
    /version: ['\"]([^'\"]*)['\"],?/,
    \"version: '${NEW_VERSION}',\"
  );
  fs.writeFileSync('app.config.ts', newContent, 'utf8');
"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Error: Failed to update app.config.ts${NC}"
  mv app.config.ts.backup app.config.ts
  exit 1
fi

# Remove backup if successful
rm app.config.ts.backup

echo -e "${GREEN}✅ Successfully updated version to ${NEW_VERSION}${NC}"

# Update package.json if it exists
if [ -f "package.json" ]; then
  echo -e "${BLUE}📝 Updating package.json...${NC}"

  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    pkg.version = '${NEW_VERSION}';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n', 'utf8');
  "

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Successfully updated package.json${NC}"
  else
    echo -e "${YELLOW}⚠️  Warning: Could not update package.json${NC}"
  fi
fi

# Ask if user wants to commit the version bump
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "  1. Review the changes in app.config.ts"
echo "  2. Commit the version bump:"
echo -e "     ${GREEN}git add app.config.ts package.json${NC}"
echo -e "     ${GREEN}git commit -m \"chore: bump version to ${NEW_VERSION}\"${NC}"
echo ""

# Optional: Automatically stage and commit
read -p "Do you want to commit these changes now? (yes/no): " -r
echo ""

if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo -e "${BLUE}📦 Staging changes...${NC}"
  git add app.config.ts package.json

  echo -e "${BLUE}💾 Creating commit...${NC}"
  git commit -m "chore: bump version to ${NEW_VERSION}"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Changes committed successfully${NC}"
    echo ""
    echo -e "${BLUE}📋 You can now:${NC}"
    echo "  - Push changes: ${GREEN}git push${NC}"
    echo "  - Create a tag: ${GREEN}git tag v${NEW_VERSION}${NC}"
    echo "  - Deploy: ${GREEN}pnpm deploy:prod${NC}"
  else
    echo -e "${RED}❌ Error: Failed to commit changes${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}⏭️  Skipping commit${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Version bump complete!${NC}"

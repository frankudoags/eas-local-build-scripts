#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🏷️  GitHub Release Creation Script${NC}\n"

# Parse command line arguments
RELEASE_TYPE="preview"
DRAFT=false
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --type)
      RELEASE_TYPE="$2"
      shift 2
      ;;
    --draft)
      DRAFT=true
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--type preview|production|development] [--draft] [--non-interactive]"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) not found.${NC}"
  echo -e "${YELLOW}   Install it with: brew install gh${NC}"
  exit 1
fi

# Extract version from app.config.ts
echo -e "${BLUE}📋 Extracting version information...${NC}"

VERSION=$(node -e "
  const fs = require('fs');
  const content = fs.readFileSync('app.config.ts', 'utf8');
  const versionMatch = content.match(/version: ['\"]([^'\"]*)['\"],?/);
  console.log(versionMatch ? versionMatch[1] : '1.0.0');
")

BUILD_NUMBER=$(date +%Y%m%d%H%M)

# Set tag name based on release type
case $RELEASE_TYPE in
  preview)
    TAG_NAME="preview-v${VERSION}-${BUILD_NUMBER}"
    RELEASE_TITLE="Preview Release v${VERSION}-${BUILD_NUMBER}"
    ;;
  production)
    TAG_NAME="v${VERSION}-${BUILD_NUMBER}"
    RELEASE_TITLE="Production Release v${VERSION}"
    ;;
  development)
    TAG_NAME="dev-v${VERSION}-${BUILD_NUMBER}"
    RELEASE_TITLE="Development Release v${VERSION}-${BUILD_NUMBER}"
    ;;
  *)
    echo -e "${RED}❌ Invalid release type: $RELEASE_TYPE${NC}"
    echo "Valid types: preview, production, development"
    exit 1
    ;;
esac

echo -e "${GREEN}Version: ${VERSION}${NC}"
echo -e "${GREEN}Build Number: ${BUILD_NUMBER}${NC}"
echo -e "${GREEN}Tag: ${TAG_NAME}${NC}"
echo -e "${GREEN}Type: ${RELEASE_TYPE}${NC}"
echo -e "${GREEN}Draft: ${DRAFT}${NC}\n"

# Confirmation prompt for production releases (unless non-interactive)
if [ "$RELEASE_TYPE" = "production" ] && [ "$NON_INTERACTIVE" = false ]; then
  echo -e "${YELLOW}⚠️  You are about to create a PRODUCTION release${NC}"
  read -p "Are you sure you want to continue? (yes/no): " -r
  echo
  if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo -e "${RED}❌ Release creation cancelled${NC}"
    exit 1
  fi
fi

# Generate changelog
echo -e "${BLUE}📝 Generating changelog...${NC}"

if git describe --tags --abbrev=0 > /dev/null 2>&1; then
  LAST_TAG=$(git describe --tags --abbrev=0)
  git log $LAST_TAG..HEAD --pretty=format:"- %s" > changelog.md 2>/dev/null || echo "- Release for ${RELEASE_TYPE}" > changelog.md
else
  git log --pretty=format:"- %s" -n 10 > changelog.md 2>/dev/null || echo "- Release for ${RELEASE_TYPE}" > changelog.md
fi

echo -e "${GREEN}✅ Changelog generated${NC}\n"

# Create the release
echo -e "${BLUE}🚀 Creating GitHub release...${NC}"

if [ "$DRAFT" = true ]; then
  gh release create "$TAG_NAME" \
    --title "$RELEASE_TITLE" \
    --notes-file changelog.md \
    --draft
else
  gh release create "$TAG_NAME" \
    --title "$RELEASE_TITLE" \
    --notes-file changelog.md
fi

echo -e "${GREEN}✅ GitHub release created: $TAG_NAME${NC}"

# Get the repository URL and construct release URL
REPO_URL=$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's/.*github\.com[:/]/https:\/\/github.com\//')
RELEASE_URL="${REPO_URL}/releases/tag/${TAG_NAME}"
echo -e "${BLUE}   View it at: ${RELEASE_URL}${NC}"

# Cleanup temporary files
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -f changelog.md
echo -e "${GREEN}✅ Cleanup completed${NC}"

echo -e "\n${GREEN}🎉 Release creation completed!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Version:${NC} ${VERSION}"
echo -e "${GREEN}Build Number:${NC} ${BUILD_NUMBER}"
echo -e "${GREEN}Tag:${NC} ${TAG_NAME}"
echo -e "${GREEN}Draft:${NC} ${DRAFT}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
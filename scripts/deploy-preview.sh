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

echo -e "${BLUE}🚀 Preview Deployment Script${NC}\n"

# Parse command line arguments
PLATFORM="all"
SKIP_TESTS=false
CREATE_RELEASE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --release)
      CREATE_RELEASE=true
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--platform android|ios|all] [--skip-tests] [--release]"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Step 0: Clean up old build files
echo -e "${BLUE}🧹 Cleaning up old build files...${NC}"
rm -f *.ipa *.apk *.aab build-*.ipa build-*.apk build-*.aab 2>/dev/null || true
echo -e "${GREEN}✅ Cleanup completed${NC}\n"

# Step 1: Run tests (unless skipped)
if [ "$SKIP_TESTS" = false ]; then
  echo -e "${BLUE}📋 Running tests...${NC}"
  pnpm install --frozen-lockfile 

  echo -e "${BLUE}🧪 Running TypeScript check...${NC}"
  pnpm tsc

  echo -e "${BLUE}🧹 Running Lint checks...${NC}"
  pnpm lint-all

  echo -e "${BLUE}🧪 Running tests...${NC}"
  pnpm test

  echo -e "${GREEN}✅ All tests passed!${NC}\n"
else
  echo -e "${YELLOW}⚠️  Skipping tests${NC}\n"
fi

# Step 2: Build and submit
echo -e "${BLUE}📱 Building and submitting preview builds...${NC}\n"

# Build Android
if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "all" ]; then
  echo -e "${BLUE}🤖 Building Android Preview...${NC}"
  eas build --platform android --profile preview --local --non-interactive --output=./android-preview.aab

  echo -e "${BLUE}📤 Submitting to Google Play...${NC}"
  eas submit -p android --path ./android-preview.aab --profile preview --non-interactive

  echo -e "${GREEN}✅ Android build completed!${NC}\n"
fi

# Build iOS
if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
  echo -e "${BLUE}🍎 Building iOS Preview...${NC}"
  eas build --platform ios --profile preview --local --non-interactive --output=./ios-preview.ipa

  echo -e "${BLUE}📤 Submitting to TestFlight...${NC}"
  eas submit -p ios --path ./ios-preview.ipa --profile preview --non-interactive

  echo -e "${GREEN}✅ iOS build completed!${NC}\n"
fi

echo -e "\n${GREEN}🎉 Preview deployment completed!${NC}"

# Step 3: Create GitHub release if requested
if [ "$CREATE_RELEASE" = true ]; then
  echo -e "\n${BLUE}🏷️  Creating GitHub release...${NC}"
  "$SCRIPT_DIR/create-release.sh" --type preview --non-interactive
  echo -e "${GREEN}✅ GitHub release created!${NC}"
else
  echo -e "${YELLOW}💡 To create a GitHub release, run:${NC}"
  echo -e "${BLUE}   ./scripts/create-release.sh --type preview${NC}"
fi

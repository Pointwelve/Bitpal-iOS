#!/bin/bash

# Bitpal iOS Build Script
# Supports both Legacy and SwiftUI v2 implementations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PROJECT_TYPE="v2"
CONFIGURATION="Debug"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
CLEAN=false
TEST=false
ARCHIVE=false
VERBOSE=false

# Help function
show_help() {
    cat << EOF
Bitpal iOS Build Script

Usage: $0 [OPTIONS]

OPTIONS:
    -t, --type TYPE          Project type: 'v2' (SwiftUI) or 'legacy' (default: v2)
    -c, --configuration CFG  Build configuration: Debug or Release (default: Debug)
    -d, --destination DEST   Build destination (default: iPhone 16 Pro simulator)
    -l, --clean             Clean before build
    -e, --test              Run tests after build
    -a, --archive           Create archive (Release builds only)
    -v, --verbose           Verbose output
    -h, --help              Show this help

EXAMPLES:
    $0                                          # Build SwiftUI v2 in Debug
    $0 -t legacy -c Release                     # Build Legacy in Release
    $0 -t v2 -c Release -e -a                   # Build SwiftUI v2, test, and archive
    $0 -d "platform=iOS,name=iPhone"           # Build for physical device

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            PROJECT_TYPE="$2"
            shift 2
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION="$2"
            shift 2
            ;;
        -l|--clean)
            CLEAN=true
            shift
            ;;
        -e|--test)
            TEST=true
            shift
            ;;
        -a|--archive)
            ARCHIVE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ "$PROJECT_TYPE" != "v2" && "$PROJECT_TYPE" != "legacy" ]]; then
    echo -e "${RED}Error: Project type must be 'v2' or 'legacy'${NC}"
    exit 1
fi

if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}Error: Configuration must be 'Debug' or 'Release'${NC}"
    exit 1
fi

if [[ "$ARCHIVE" == "true" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}Error: Archive builds require Release configuration${NC}"
    exit 1
fi

# Set project-specific variables
if [[ "$PROJECT_TYPE" == "v2" ]]; then
    PROJECT_DIR="Bitpal-v2"
    PROJECT_FILE="Bitpal-v2.xcodeproj"
    SCHEME="Bitpal-v2"
    echo -e "${BLUE}Building SwiftUI v2 implementation${NC}"
else
    PROJECT_DIR="Legacy"
    PROJECT_FILE="Bitpal.xcodeproj"
    SCHEME="Bitpal"
    echo -e "${BLUE}Building Legacy UIKit implementation${NC}"
fi

# Verbose flag for xcodebuild
XCODE_VERBOSE=""
if [[ "$VERBOSE" == "true" ]]; then
    XCODE_VERBOSE="-verbose"
fi

# Navigate to project directory
cd "$PROJECT_DIR"

echo -e "${YELLOW}Configuration:${NC}"
echo "  Project: $PROJECT_TYPE"
echo "  Configuration: $CONFIGURATION"
echo "  Destination: $DESTINATION"
echo "  Clean: $CLEAN"
echo "  Test: $TEST"
echo "  Archive: $ARCHIVE"
echo ""

# Clean if requested
if [[ "$CLEAN" == "true" ]]; then
    echo -e "${YELLOW}🧹 Cleaning project...${NC}"
    xcodebuild clean \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        $XCODE_VERBOSE
    echo -e "${GREEN}✅ Clean completed${NC}"
    echo ""
fi

# Resolve dependencies (SPM for v2, Carthage for legacy)
if [[ "$PROJECT_TYPE" == "v2" ]]; then
    echo -e "${YELLOW}📦 Resolving SPM dependencies...${NC}"
    xcodebuild -resolvePackageDependencies \
        -project "$PROJECT_FILE" \
        $XCODE_VERBOSE
    echo -e "${GREEN}✅ SPM dependencies resolved${NC}"
elif [[ "$PROJECT_TYPE" == "legacy" ]]; then
    if command -v carthage &> /dev/null; then
        echo -e "${YELLOW}📦 Updating Carthage dependencies...${NC}"
        carthage update --cache-builds --platform iOS --use-xcframeworks
        echo -e "${GREEN}✅ Carthage dependencies updated${NC}"
    else
        echo -e "${YELLOW}⚠️  Carthage not installed, skipping dependency update${NC}"
    fi
fi
echo ""

# Build
echo -e "${YELLOW}🔨 Building $SCHEME ($CONFIGURATION)...${NC}"

BUILD_CMD="xcodebuild build \
    -project \"$PROJECT_FILE\" \
    -scheme \"$SCHEME\" \
    -configuration \"$CONFIGURATION\" \
    -destination \"$DESTINATION\" \
    $XCODE_VERBOSE"

if [[ "$DESTINATION" == *"Simulator"* ]]; then
    BUILD_CMD="$BUILD_CMD CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"
fi

eval $BUILD_CMD

echo -e "${GREEN}✅ Build completed successfully${NC}"
echo ""

# Test if requested
if [[ "$TEST" == "true" ]]; then
    echo -e "${YELLOW}🧪 Running tests...${NC}"
    
    TEST_CMD="xcodebuild test \
        -project \"$PROJECT_FILE\" \
        -scheme \"$SCHEME\" \
        -configuration \"$CONFIGURATION\" \
        -destination \"$DESTINATION\" \
        $XCODE_VERBOSE \
        -resultBundlePath \"TestResults-$(date +%Y%m%d-%H%M%S).xcresult\""
    
    if [[ "$DESTINATION" == *"Simulator"* ]]; then
        TEST_CMD="$TEST_CMD CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"
    fi
    
    eval $TEST_CMD
    
    echo -e "${GREEN}✅ Tests completed${NC}"
    echo ""
fi

# Archive if requested
if [[ "$ARCHIVE" == "true" ]]; then
    echo -e "${YELLOW}📦 Creating archive...${NC}"
    
    ARCHIVE_PATH="../build/$(date +%Y%m%d-%H%M%S)-$SCHEME.xcarchive"
    mkdir -p ../build
    
    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -destination "generic/platform=iOS" \
        -archivePath "$ARCHIVE_PATH" \
        $XCODE_VERBOSE
    
    echo -e "${GREEN}✅ Archive created: $ARCHIVE_PATH${NC}"
    echo ""
fi

echo -e "${GREEN}🎉 Build process completed successfully!${NC}"

# Summary
echo -e "${BLUE}Summary:${NC}"
echo "  ✅ Project: $PROJECT_TYPE"
echo "  ✅ Configuration: $CONFIGURATION"
if [[ "$TEST" == "true" ]]; then
    echo "  ✅ Tests: Passed"
fi
if [[ "$ARCHIVE" == "true" ]]; then
    echo "  ✅ Archive: Created"
fi
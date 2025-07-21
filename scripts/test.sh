#!/bin/bash

# Bitpal iOS Test Script
# Comprehensive testing for both Legacy and SwiftUI v2 implementations

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
COVERAGE=false
PARALLEL=true
VERBOSE=false
OUTPUT_DIR="test-results"

# Test destinations
DESTINATIONS=(
    "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1"
    "platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=18.1"
)

# Help function
show_help() {
    cat << EOF
Bitpal iOS Test Script

Usage: $0 [OPTIONS]

OPTIONS:
    -t, --type TYPE          Project type: 'v2' (SwiftUI), 'legacy', or 'all' (default: v2)
    -c, --configuration CFG  Build configuration: Debug or Release (default: Debug)
    -o, --coverage          Generate code coverage report
    -s, --sequential        Run tests sequentially (default: parallel)
    -d, --output-dir DIR    Output directory for test results (default: test-results)
    -v, --verbose           Verbose output
    -h, --help              Show this help

EXAMPLES:
    $0                                  # Test SwiftUI v2 in Debug
    $0 -t all -o                        # Test both projects with coverage
    $0 -t legacy -c Release -s          # Test Legacy sequentially in Release

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
        -o|--coverage)
            COVERAGE=true
            shift
            ;;
        -s|--sequential)
            PARALLEL=false
            shift
            ;;
        -d|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
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
if [[ "$PROJECT_TYPE" != "v2" && "$PROJECT_TYPE" != "legacy" && "$PROJECT_TYPE" != "all" ]]; then
    echo -e "${RED}Error: Project type must be 'v2', 'legacy', or 'all'${NC}"
    exit 1
fi

if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}Error: Configuration must be 'Debug' or 'Release'${NC}"
    exit 1
fi

# Create output directory (excluded from git)
mkdir -p "$OUTPUT_DIR"

# Ensure output directory is in gitignore
if ! grep -q "^${OUTPUT_DIR}/" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Test script output (auto-added)" >> .gitignore
    echo "${OUTPUT_DIR}/" >> .gitignore
fi

# Verbose flag for xcodebuild
XCODE_VERBOSE=""
if [[ "$VERBOSE" == "true" ]]; then
    XCODE_VERBOSE="-verbose"
fi

# Function to run tests for a specific project
run_tests() {
    local project_type=$1
    local project_dir=""
    local project_file=""
    local scheme=""
    
    if [[ "$project_type" == "v2" ]]; then
        project_dir="Bitpal-v2"
        project_file="Bitpal-v2.xcodeproj"
        scheme="Bitpal-v2"
        echo -e "${BLUE}Testing SwiftUI v2 implementation${NC}"
    else
        project_dir="Legacy"
        project_file="Bitpal.xcodeproj"
        scheme="Bitpal"
        echo -e "${BLUE}Testing Legacy UIKit implementation${NC}"
    fi
    
    cd "$project_dir"
    
    # Resolve dependencies
    if [[ "$project_type" == "v2" ]]; then
        echo -e "${YELLOW}📦 Resolving SPM dependencies...${NC}"
        xcodebuild -resolvePackageDependencies -project "$project_file" $XCODE_VERBOSE
    elif [[ "$project_type" == "legacy" && -f "Cartfile" ]]; then
        if command -v carthage &> /dev/null; then
            echo -e "${YELLOW}📦 Updating Carthage dependencies...${NC}"
            carthage update --cache-builds --platform iOS --use-xcframeworks
        fi
    fi
    
    local overall_success=true
    local test_count=0
    
    # Run tests on each destination
    for destination in "${DESTINATIONS[@]}"; do
        test_count=$((test_count + 1))
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local result_bundle="../$OUTPUT_DIR/${project_type}-${test_count}-${timestamp}.xcresult"
        
        echo -e "${YELLOW}🧪 Running tests on: $destination${NC}"
        
        # Build test command
        local test_cmd="xcodebuild test \
            -project \"$project_file\" \
            -scheme \"$scheme\" \
            -configuration \"$CONFIGURATION\" \
            -destination \"$destination\" \
            -resultBundlePath \"$result_bundle\" \
            $XCODE_VERBOSE \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO"
        
        # Add code coverage if requested
        if [[ "$COVERAGE" == "true" ]]; then
            test_cmd="$test_cmd -enableCodeCoverage YES"
        fi
        
        # Run tests
        if eval $test_cmd; then
            echo -e "${GREEN}✅ Tests passed for $destination${NC}"
        else
            echo -e "${RED}❌ Tests failed for $destination${NC}"
            overall_success=false
        fi
        
        echo ""
        
        # If running sequentially, wait for completion before next test
        if [[ "$PARALLEL" == "false" ]]; then
            sleep 2
        fi
    done
    
    cd ..
    
    # Generate coverage report if requested
    if [[ "$COVERAGE" == "true" && "$overall_success" == "true" ]]; then
        echo -e "${YELLOW}📊 Generating code coverage report...${NC}"
        generate_coverage_report "$project_type"
    fi
    
    return $overall_success
}

# Function to generate coverage report
generate_coverage_report() {
    local project_type=$1
    local coverage_dir="$OUTPUT_DIR/coverage-$project_type"
    mkdir -p "$coverage_dir"
    
    # Find the most recent xcresult bundle
    local latest_result=$(find "$OUTPUT_DIR" -name "${project_type}-*.xcresult" -type d | head -1)
    
    if [[ -n "$latest_result" ]]; then
        echo -e "${YELLOW}Extracting coverage from: $latest_result${NC}"
        
        # Extract coverage data
        xcrun xccov view --report --json "$latest_result" > "$coverage_dir/coverage.json"
        xcrun xccov view --report "$latest_result" > "$coverage_dir/coverage.txt"
        
        # Generate HTML report if possible
        if command -v xcov &> /dev/null; then
            xcov --project "$latest_result" --output_directory "$coverage_dir/html"
            echo -e "${GREEN}📊 HTML coverage report generated: $coverage_dir/html/index.html${NC}"
        fi
        
        # Extract key metrics
        local coverage_percentage=$(xcrun xccov view --report --json "$latest_result" | grep -o '"lineCoverage":[0-9.]*' | cut -d':' -f2 | head -1)
        if [[ -n "$coverage_percentage" ]]; then
            local coverage_percent=$(echo "$coverage_percentage * 100" | bc -l | cut -d'.' -f1)
            echo -e "${GREEN}📈 Code Coverage: ${coverage_percent}%${NC}"
            
            # Coverage threshold check
            if (( coverage_percent >= 80 )); then
                echo -e "${GREEN}✅ Coverage meets minimum threshold (80%)${NC}"
            else
                echo -e "${YELLOW}⚠️  Coverage below recommended threshold (80%)${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  No test results found for coverage report${NC}"
    fi
}

# Function to cleanup test artifacts
cleanup_test_results() {
    local keep_results=${1:-false}
    
    if [[ "$keep_results" == "false" ]]; then
        echo -e "${YELLOW}🧹 Cleaning up test artifacts...${NC}"
        
        # Remove .xcresult bundles from project directories
        find Bitpal-v2 -name "*.xcresult" -type d -exec rm -rf {} + 2>/dev/null || true
        find Legacy -name "*.xcresult" -type d -exec rm -rf {} + 2>/dev/null || true
        
        # Clean up any test output directories
        rm -rf test_output/ 2>/dev/null || true
        rm -rf test-output/ 2>/dev/null || true
        
        echo -e "${GREEN}✅ Test artifacts cleaned${NC}"
    fi
}

# Function to generate test summary
generate_summary() {
    echo -e "${BLUE}📋 Test Summary${NC}"
    echo "=================="
    
    local total_bundles=$(find "$OUTPUT_DIR" -name "*.xcresult" -type d | wc -l)
    echo "Test result bundles: $total_bundles"
    
    if [[ "$COVERAGE" == "true" ]]; then
        if [[ -f "$OUTPUT_DIR/coverage-v2/coverage.json" ]]; then
            echo "SwiftUI v2 coverage report: $OUTPUT_DIR/coverage-v2/"
        fi
        if [[ -f "$OUTPUT_DIR/coverage-legacy/coverage.json" ]]; then
            echo "Legacy coverage report: $OUTPUT_DIR/coverage-legacy/"
        fi
    fi
    
    echo ""
    echo -e "${GREEN}📁 All test results saved to: $OUTPUT_DIR${NC}"
}

# Main execution
echo -e "${BLUE}🧪 Bitpal iOS Test Runner${NC}"
echo "=========================="
echo ""

echo -e "${YELLOW}Configuration:${NC}"
echo "  Project(s): $PROJECT_TYPE"
echo "  Configuration: $CONFIGURATION"
echo "  Coverage: $COVERAGE"
echo "  Parallel: $PARALLEL"
echo "  Output: $OUTPUT_DIR"
echo ""

# Track overall success
overall_success=true

# Run tests based on project type
if [[ "$PROJECT_TYPE" == "all" ]]; then
    echo -e "${BLUE}🚀 Running tests for all projects${NC}"
    echo ""
    
    if ! run_tests "v2"; then
        overall_success=false
    fi
    
    if ! run_tests "legacy"; then
        overall_success=false
    fi
    
elif [[ "$PROJECT_TYPE" == "v2" || "$PROJECT_TYPE" == "legacy" ]]; then
    if ! run_tests "$PROJECT_TYPE"; then
        overall_success=false
    fi
fi

# Generate summary
generate_summary

# Cleanup test artifacts (but keep results in output directory)
cleanup_test_results false

# Final result
echo ""
if [[ "$overall_success" == "true" ]]; then
    echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
    echo -e "${BLUE}📁 Test results preserved in: $OUTPUT_DIR${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check results in $OUTPUT_DIR${NC}"
    exit 1
fi
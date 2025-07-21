#!/bin/bash

# Bitpal iOS Development Environment Setup Script
# Sets up everything needed for development

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SETUP_HOMEBREW=true
SETUP_TOOLS=true
SETUP_DEPENDENCIES=true
SETUP_HOOKS=true
VERBOSE=false

# Help function
show_help() {
    cat << EOF
Bitpal iOS Development Setup Script

Usage: $0 [OPTIONS]

OPTIONS:
    --skip-homebrew         Skip Homebrew installation/update
    --skip-tools           Skip development tools installation
    --skip-dependencies    Skip project dependencies
    --skip-hooks           Skip git hooks setup
    -v, --verbose          Verbose output
    -h, --help             Show this help

EXAMPLES:
    $0                              # Full setup
    $0 --skip-homebrew             # Skip Homebrew setup
    $0 --skip-dependencies         # Skip dependency installation

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-homebrew)
            SETUP_HOMEBREW=false
            shift
            ;;
        --skip-tools)
            SETUP_TOOLS=false
            shift
            ;;
        --skip-dependencies)
            SETUP_DEPENDENCIES=false
            shift
            ;;
        --skip-hooks)
            SETUP_HOOKS=false
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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is designed for macOS only${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Bitpal iOS Development Environment Setup${NC}"
echo "=============================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install or update Homebrew
setup_homebrew() {
    echo -e "${YELLOW}🍺 Setting up Homebrew...${NC}"
    
    if command_exists brew; then
        echo -e "${GREEN}✅ Homebrew already installed${NC}"
        echo -e "${YELLOW}📦 Updating Homebrew...${NC}"
        brew update
    else
        echo -e "${YELLOW}📦 Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    echo -e "${GREEN}✅ Homebrew setup complete${NC}"
    echo ""
}

# Function to install development tools
setup_tools() {
    echo -e "${YELLOW}🛠️  Installing development tools...${NC}"
    
    # Essential tools
    local tools=(
        "swiftlint"          # Swift linting
        "swiftformat"        # Swift formatting
        "carthage"           # Dependency manager for legacy project
        "xcbeautify"         # Xcode build output formatter
        "git-lfs"            # Git Large File Storage
        "gh"                 # GitHub CLI
    )
    
    # Optional tools
    local optional_tools=(
        "xcov"               # Code coverage
        "periphery"          # Unused code detection
        "licenseplist"       # License management
    )
    
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            echo -e "${GREEN}✅ $tool already installed${NC}"
        else
            echo -e "${YELLOW}📦 Installing $tool...${NC}"
            brew install "$tool"
        fi
    done
    
    echo -e "${YELLOW}📦 Installing optional tools...${NC}"
    for tool in "${optional_tools[@]}"; do
        if command_exists "$tool"; then
            echo -e "${GREEN}✅ $tool already installed${NC}"
        else
            echo -e "${YELLOW}📦 Installing $tool...${NC}"
            brew install "$tool" || echo -e "${YELLOW}⚠️  Failed to install $tool (optional)${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Development tools setup complete${NC}"
    echo ""
}

# Function to setup project dependencies
setup_dependencies() {
    echo -e "${YELLOW}📦 Setting up project dependencies...${NC}"
    
    # Setup SwiftUI v2 dependencies (SPM)
    if [[ -d "Bitpal-v2" ]]; then
        echo -e "${YELLOW}📱 Setting up SwiftUI v2 dependencies...${NC}"
        cd Bitpal-v2
        
        if [[ -f "Bitpal-v2.xcodeproj/project.pbxproj" ]]; then
            xcodebuild -resolvePackageDependencies -project Bitpal-v2.xcodeproj
            echo -e "${GREEN}✅ SwiftUI v2 SPM dependencies resolved${NC}"
        fi
        
        cd ..
    fi
    
    # Setup Legacy dependencies (Carthage)
    if [[ -d "Legacy" && -f "Legacy/Cartfile" ]]; then
        echo -e "${YELLOW}🏛️  Setting up Legacy dependencies...${NC}"
        cd Legacy
        
        if command_exists carthage; then
            carthage bootstrap --cache-builds --platform iOS --use-xcframeworks
            echo -e "${GREEN}✅ Legacy Carthage dependencies resolved${NC}"
        else
            echo -e "${RED}❌ Carthage not available for Legacy dependencies${NC}"
        fi
        
        cd ..
    fi
    
    echo -e "${GREEN}✅ Project dependencies setup complete${NC}"
    echo ""
}

# Function to setup git hooks
setup_hooks() {
    echo -e "${YELLOW}🪝 Setting up git hooks...${NC}"
    
    # Create hooks directory if it doesn't exist
    mkdir -p .git/hooks
    
    # Pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "🔍 Running pre-commit checks..."

# Check for SwiftLint
if command -v swiftlint >/dev/null 2>&1; then
    echo "📝 Running SwiftLint..."
    
    # Run SwiftLint on staged files
    git diff --cached --name-only --diff-filter=d | grep -E '\.(swift)$' | while read file; do
        swiftlint lint --path "$file" --config .swiftlint.yml
        if [ $? -ne 0 ]; then
            echo "❌ SwiftLint failed for $file"
            exit 1
        fi
    done
else
    echo "⚠️  SwiftLint not found, skipping..."
fi

# Check for SwiftFormat
if command -v swiftformat >/dev/null 2>&1; then
    echo "🎨 Running SwiftFormat..."
    
    # Run SwiftFormat on staged files
    git diff --cached --name-only --diff-filter=d | grep -E '\.(swift)$' | while read file; do
        swiftformat --config .swiftformat "$file"
        git add "$file"
    done
else
    echo "⚠️  SwiftFormat not found, skipping..."
fi

echo "✅ Pre-commit checks completed"
EOF

    # Pre-push hook
    cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "🚀 Running pre-push checks..."

# Run a quick build check for SwiftUI v2
if [ -d "Bitpal-v2" ]; then
    echo "🔨 Quick build check for SwiftUI v2..."
    cd Bitpal-v2
    xcodebuild -project Bitpal-v2.xcodeproj -scheme Bitpal-v2 -destination "platform=iOS Simulator,name=iPhone 16 Pro" build CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ SwiftUI v2 build failed"
        exit 1
    fi
    cd ..
fi

echo "✅ Pre-push checks completed"
EOF

    # Make hooks executable
    chmod +x .git/hooks/pre-commit
    chmod +x .git/hooks/pre-push
    
    echo -e "${GREEN}✅ Git hooks setup complete${NC}"
    echo ""
}

# Function to verify setup
verify_setup() {
    echo -e "${YELLOW}🔍 Verifying setup...${NC}"
    
    local all_good=true
    
    # Check Xcode
    if command_exists xcodebuild; then
        local xcode_version=$(xcodebuild -version | head -1)
        echo -e "${GREEN}✅ $xcode_version${NC}"
    else
        echo -e "${RED}❌ Xcode not found${NC}"
        all_good=false
    fi
    
    # Check essential tools
    local essential_tools=("swiftlint" "swiftformat" "git")
    for tool in "${essential_tools[@]}"; do
        if command_exists "$tool"; then
            local version=$(${tool} --version 2>/dev/null | head -1 || echo "installed")
            echo -e "${GREEN}✅ $tool ($version)${NC}"
        else
            echo -e "${RED}❌ $tool not found${NC}"
            all_good=false
        fi
    done
    
    # Check project structure
    if [[ -d "Bitpal-v2" ]]; then
        echo -e "${GREEN}✅ SwiftUI v2 project found${NC}"
    else
        echo -e "${YELLOW}⚠️  SwiftUI v2 project not found${NC}"
    fi
    
    if [[ -d "Legacy" ]]; then
        echo -e "${GREEN}✅ Legacy project found${NC}"
    else
        echo -e "${YELLOW}⚠️  Legacy project not found${NC}"
    fi
    
    # Check git hooks
    if [[ -x ".git/hooks/pre-commit" ]]; then
        echo -e "${GREEN}✅ Git pre-commit hook installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Git pre-commit hook not found${NC}"
    fi
    
    echo ""
    if [[ "$all_good" == "true" ]]; then
        echo -e "${GREEN}🎉 Setup verification successful!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some issues detected, but you can still proceed${NC}"
    fi
}

# Function to show next steps
show_next_steps() {
    echo -e "${BLUE}📝 Next Steps${NC}"
    echo "============="
    echo ""
    echo "1. 🏗️  Build the project:"
    echo "   ./scripts/build.sh -t v2                    # Build SwiftUI v2"
    echo "   ./scripts/build.sh -t legacy                # Build Legacy"
    echo ""
    echo "2. 🧪 Run tests:"
    echo "   ./scripts/test.sh -t v2                     # Test SwiftUI v2"
    echo "   ./scripts/test.sh -t all -o                 # Test all with coverage"
    echo ""
    echo "3. 📱 Open in Xcode:"
    echo "   open Bitpal-v2/Bitpal-v2.xcodeproj         # SwiftUI v2"
    echo "   open Legacy/Bitpal.xcodeproj                # Legacy"
    echo ""
    echo "4. 📖 Read documentation:"
    echo "   cat CLAUDE.md                               # Project overview"
    echo "   cat features.md                             # Feature documentation"
    echo ""
    echo -e "${GREEN}Happy coding! 🚀${NC}"
}

# Main execution
echo -e "${YELLOW}Starting setup with the following options:${NC}"
echo "  Homebrew: $SETUP_HOMEBREW"
echo "  Tools: $SETUP_TOOLS" 
echo "  Dependencies: $SETUP_DEPENDENCIES"
echo "  Git Hooks: $SETUP_HOOKS"
echo ""

# Run setup steps
if [[ "$SETUP_HOMEBREW" == "true" ]]; then
    setup_homebrew
fi

if [[ "$SETUP_TOOLS" == "true" ]]; then
    setup_tools
fi

if [[ "$SETUP_DEPENDENCIES" == "true" ]]; then
    setup_dependencies
fi

if [[ "$SETUP_HOOKS" == "true" ]]; then
    setup_hooks
fi

# Verify and show next steps
verify_setup
show_next_steps

echo ""
echo -e "${GREEN}🎉 Bitpal iOS development environment setup complete!${NC}"
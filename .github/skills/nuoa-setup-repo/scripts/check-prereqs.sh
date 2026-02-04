#!/bin/bash

# NUOA Setup Repository - Check Prerequisites Script
# Verifies required development tools are installed

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check tool version
check_tool() {
    local TOOL_NAME=$1
    local COMMAND=$2
    local VERSION_CMD=$3
    local MIN_VERSION=$4
    
    if command_exists "$COMMAND"; then
        local VERSION=$(eval "$VERSION_CMD" 2>&1 | head -n 1)
        echo -e "${GREEN}✓${NC} $TOOL_NAME: $VERSION"
        return 0
    else
        echo -e "${RED}✗${NC} $TOOL_NAME: ${RED}Not installed${NC}"
        return 1
    fi
}

# Print installation instructions
print_install_instructions() {
    local OS=$1
    
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Installation Instructions${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [ "$OS" = "linux" ]; then
        echo -e "${BLUE}For Ubuntu/Debian:${NC}"
        echo ""
        echo "# Java 11"
        echo "sudo apt update"
        echo "sudo apt install openjdk-11-jdk"
        echo ""
        echo "# Maven"
        echo "sudo apt install maven"
        echo ""
        echo "# Python 3.13"
        echo "sudo apt install python3.13 python3.13-venv python3-pip"
        echo ""
        echo "# Node.js (via nvm - recommended)"
        echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "nvm install 18"
        echo "nvm use 18"
        echo ""
        echo "# Yarn"
        echo "npm install -g yarn"
        echo ""
        echo "# AWS CLI"
        echo "curl \"https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip\" -o \"awscliv2.zip\""
        echo "unzip awscliv2.zip"
        echo "sudo ./aws/install"
        
    elif [ "$OS" = "macos" ]; then
        echo -e "${BLUE}For macOS:${NC}"
        echo ""
        echo "# Java 11 (via Homebrew)"
        echo "brew install openjdk@11"
        echo ""
        echo "# Or use SDKMAN (recommended)"
        echo "curl -s \"https://get.sdkman.io\" | bash"
        echo "sdk install java 11.0.20-amzn"
        echo ""
        echo "# Maven"
        echo "brew install maven"
        echo ""
        echo "# Python 3.13"
        echo "brew install python@3.13"
        echo ""
        echo "# Node.js (via nvm - recommended)"
        echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
        echo "nvm install 18"
        echo "nvm use 18"
        echo ""
        echo "# Or via Homebrew"
        echo "brew install node@18"
        echo ""
        echo "# Yarn"
        echo "npm install -g yarn"
        echo ""
        echo "# AWS CLI"
        echo "brew install awscli"
    else
        echo -e "${YELLOW}Please install the following tools manually:${NC}"
        echo "  • Java 11 (OpenJDK or Amazon Corretto)"
        echo "  • Maven 3.6+"
        echo "  • Python 3.13+"
        echo "  • Node.js 18+"
        echo "  • npm 9+"
        echo "  • Yarn 1.22+"
        echo "  • AWS CLI 2.x"
    fi
    
    echo ""
}

# Main execution
main() {
    echo -e "${BLUE}Check Prerequisites${NC}"
    echo ""
    
    local OS=$(detect_os)
    echo -e "${BLUE}Detected OS: ${GREEN}$OS${NC}"
    echo ""
    
    local ALL_OK=true
    
    # Check Git
    if ! check_tool "Git" "git" "git --version"; then
        ALL_OK=false
    fi
    
    # Check Java
    if ! check_tool "Java" "java" "java -version 2>&1 | grep 'version'"; then
        ALL_OK=false
    else
        # Check Java version is 11
        JAVA_VERSION=$(java -version 2>&1 | grep 'version' | awk -F\" '{print $2}' | cut -d'.' -f1)
        if [ "$JAVA_VERSION" != "11" ] && [ "$JAVA_VERSION" != "1" ]; then
            echo -e "${YELLOW}  ⚠ Warning: Java 11 is recommended (found version $JAVA_VERSION)${NC}"
        fi
    fi
    
    # Check Maven
    if ! check_tool "Maven" "mvn" "mvn --version | head -n 1"; then
        ALL_OK=false
    fi
    
    # Check Python
    if command_exists python3.13; then
        check_tool "Python" "python3.13" "python3.13 --version"
    elif command_exists python3; then
        if ! check_tool "Python" "python3" "python3 --version"; then
            ALL_OK=false
        else
            PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d'.' -f1,2)
            if (( $(echo "$PYTHON_VERSION < 3.11" | bc -l) )); then
                echo -e "${YELLOW}  ⚠ Warning: Python 3.13+ is recommended (found $PYTHON_VERSION)${NC}"
            fi
        fi
    else
        echo -e "${RED}✗${NC} Python: ${RED}Not installed${NC}"
        ALL_OK=false
    fi
    
    # Check pip
    if ! check_tool "pip" "pip3" "pip3 --version"; then
        echo -e "${YELLOW}  ⚠ Warning: pip is recommended for Python package management${NC}"
    fi
    
    # Check Node.js
    if ! check_tool "Node.js" "node" "node --version"; then
        ALL_OK=false
    else
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -lt 18 ]; then
            echo -e "${YELLOW}  ⚠ Warning: Node.js 18+ is recommended (found v$NODE_VERSION)${NC}"
        fi
    fi
    
    # Check npm
    if ! check_tool "npm" "npm" "npm --version"; then
        ALL_OK=false
    fi
    
    # Check Yarn
    if ! check_tool "Yarn" "yarn" "yarn --version"; then
        echo -e "${YELLOW}  ⚠ Warning: Yarn is recommended for frontend projects${NC}"
        echo -e "${YELLOW}     Install with: ${GREEN}npm install -g yarn${NC}"
    fi
    
    # Check AWS CLI (optional but recommended)
    if ! check_tool "AWS CLI" "aws" "aws --version"; then
        echo -e "${YELLOW}  ⚠ Optional: AWS CLI is needed for Lambda deployments${NC}"
    fi
    
    echo ""
    
    # Summary
    if [ "$ALL_OK" = true ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✓ All required tools are installed!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        return 0
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}✗ Some required tools are missing${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        print_install_instructions "$OS"
        return 1
    fi
}

# Run main function
main

#!/bin/bash

# NUOA Setup Repository - Install Dependencies Script
# Installs dependencies for all NUOA projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
MONOREPO_ROOT="$(cd "$SKILL_DIR/../../.." && pwd)"

# Configuration
PROJECT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --help)
            echo "NUOA Setup Repository - Install Dependencies"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --project NAME    Install dependencies for specific project only"
            echo "                    (tenant|shared|admin|console)"
            echo "  --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                      # Install all dependencies"
            echo "  $0 --project admin      # Install admin UI dependencies only"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Install Python virtual environment
install_python_venv() {
    echo -e "${BLUE}🐍 Setting up Python virtual environment...${NC}"
    
    cd "$MONOREPO_ROOT"
    
    if [ -d ".venv" ]; then
        echo -e "${YELLOW}⊘ Virtual environment already exists${NC}"
    else
        echo -e "${BLUE}Creating virtual environment...${NC}"
        
        if command -v python3.13 >/dev/null 2>&1; then
            python3.13 -m venv .venv
        elif command -v python3 >/dev/null 2>&1; then
            python3 -m venv .venv
        else
            echo -e "${RED}✗ Python 3 not found${NC}"
            return 1
        fi
        
        echo -e "${GREEN}✓ Created virtual environment${NC}"
    fi
    
    echo -e "${BLUE}Installing Python dependencies...${NC}"
    source .venv/bin/activate
    pip install --upgrade pip --quiet
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt --quiet
        echo -e "${GREEN}✓ Python dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠ requirements.txt not found, skipping${NC}"
    fi
    
    deactivate
    return 0
}

# Install Java backend dependencies
install_java_backend() {
    local PROJECT_NAME=$1
    local PROJECT_DIR=$2
    
    echo -e "${BLUE}☕ Installing $PROJECT_NAME dependencies...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⊘ $PROJECT_NAME not found, skipping${NC}"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    
    echo -e "${BLUE}Running mvn clean install...${NC}"
    if mvn clean install -DskipTests -q; then
        echo -e "${GREEN}✓ $PROJECT_NAME dependencies installed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to install $PROJECT_NAME dependencies${NC}"
        return 1
    fi
}

# Install Python backend dependencies
install_python_backend() {
    local PROJECT_NAME=$1
    local PROJECT_DIR=$2
    
    echo -e "${BLUE}🐍 Installing $PROJECT_NAME dependencies...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⊘ $PROJECT_NAME not found, skipping${NC}"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    
    if [ -f "requirements.txt" ]; then
        source "$MONOREPO_ROOT/.venv/bin/activate"
        pip install -r requirements.txt --quiet
        deactivate
        echo -e "${GREEN}✓ $PROJECT_NAME dependencies installed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ requirements.txt not found in $PROJECT_NAME${NC}"
        return 0
    fi
}

# Install frontend dependencies
install_frontend() {
    local PROJECT_NAME=$1
    local PROJECT_DIR=$2
    
    echo -e "${BLUE}⚛️  Installing $PROJECT_NAME dependencies...${NC}"
    
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${YELLOW}⊘ $PROJECT_NAME not found, skipping${NC}"
        return 0
    fi
    
    cd "$PROJECT_DIR"
    
    if [ ! -f "package.json" ]; then
        echo -e "${YELLOW}⚠ package.json not found in $PROJECT_NAME${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Running yarn install...${NC}"
    if yarn install --silent 2>&1 | grep -v "warning" | grep -E "(error|✓|installed)"; then
        echo -e "${GREEN}✓ $PROJECT_NAME dependencies installed${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to install $PROJECT_NAME dependencies${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Install Dependencies${NC}"
    echo ""
    
    cd "$MONOREPO_ROOT"
    
    local FAILED=false
    
    # Install based on project filter
    if [ -z "$PROJECT" ] || [ "$PROJECT" = "venv" ]; then
        install_python_venv || FAILED=true
        echo ""
    fi
    
    if [ -z "$PROJECT" ] || [ "$PROJECT" = "tenant" ]; then
        install_java_backend "nuoa-io-backend-tenant-services" \
            "$MONOREPO_ROOT/repos/nuoa-io-backend-tenant-services" || FAILED=true
        echo ""
    fi
    
    if [ -z "$PROJECT" ] || [ "$PROJECT" = "shared" ]; then
        install_python_backend "nuoa-io-backend-shared-services" \
            "$MONOREPO_ROOT/repos/nuoa-io-backend-shared-services" || FAILED=true
        echo ""
    fi
    
    if [ -z "$PROJECT" ] || [ "$PROJECT" = "admin" ]; then
        install_frontend "nuoa-io-admin-ui" \
            "$MONOREPO_ROOT/repos/nuoa-io-admin-ui" || FAILED=true
        echo ""
    fi
    
    if [ -z "$PROJECT" ] || [ "$PROJECT" = "console" ]; then
        install_frontend "admin-console-nuoa-react" \
            "$MONOREPO_ROOT/repos/admin-console-nuoa-react" || FAILED=true
        echo ""
    fi
    
    # Summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ "$FAILED" = false ]; then
        echo -e "${GREEN}✓ All dependencies installed successfully!${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Some dependencies failed to install${NC}"
        echo -e "${YELLOW}Please check the output above for details${NC}"
        return 1
    fi
}

# Run main function
main

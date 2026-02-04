#!/bin/bash

# NUOA Setup Repository - Main Setup Script
# Orchestrates the complete setup process for NUOA monorepo development

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
SKIP_CLONE=false
SKIP_PREREQS=false
SKIP_DEPS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-clone)
            SKIP_CLONE=true
            shift
            ;;
        --skip-prereqs)
            SKIP_PREREQS=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --help)
            echo "NUOA Setup Repository - Main Setup Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-clone      Skip repository cloning"
            echo "  --skip-prereqs    Skip prerequisite checks"
            echo "  --skip-deps       Skip dependency installation"
            echo "  --help            Show this help message"
            echo ""
            echo "Example:"
            echo "  $0                    # Full setup"
            echo "  $0 --skip-clone       # Update dependencies only"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print header
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   NUOA Monorepo Setup - Development Environment   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Change to monorepo root
cd "$MONOREPO_ROOT"
echo -e "${BLUE}📁 Working directory: ${NC}$MONOREPO_ROOT"
echo ""

# Step 1: Check Prerequisites
if [ "$SKIP_PREREQS" = false ]; then
    echo -e "${BLUE}▶ Step 1/4: Checking prerequisites...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/check-prereqs.sh"; then
        echo ""
        echo -e "${GREEN}✓ Prerequisites check passed${NC}"
    else
        echo ""
        echo -e "${RED}✗ Prerequisites check failed${NC}"
        echo -e "${YELLOW}Please install missing tools and try again${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ Step 1/4: Skipping prerequisites check${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 2: Clone Repositories
if [ "$SKIP_CLONE" = false ]; then
    echo -e "${BLUE}▶ Step 2/4: Cloning repositories...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/clone-repos.sh"; then
        echo ""
        echo -e "${GREEN}✓ Repository cloning completed${NC}"
    else
        echo ""
        echo -e "${RED}✗ Repository cloning failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⊘ Step 2/4: Skipping repository cloning${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 3: Install Dependencies
if [ "$SKIP_DEPS" = false ]; then
    echo -e "${BLUE}▶ Step 3/4: Installing dependencies...${NC}"
    echo ""
    
    if bash "$SCRIPT_DIR/install-deps.sh"; then
        echo ""
        echo -e "${GREEN}✓ Dependency installation completed${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Some dependencies may have failed to install${NC}"
        echo -e "${YELLOW}Please check the output above for details${NC}"
    fi
else
    echo -e "${YELLOW}⊘ Step 3/4: Skipping dependency installation${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 4: Verify Setup
echo -e "${BLUE}▶ Step 4/4: Verifying setup...${NC}"
echo ""

# Check if repos exist
REPOS_OK=true
if [ ! -d "repos/nuoa-io-backend-tenant-services" ]; then
    echo -e "${RED}✗ Missing: repos/nuoa-io-backend-tenant-services${NC}"
    REPOS_OK=false
else
    echo -e "${GREEN}✓ repos/nuoa-io-backend-tenant-services${NC}"
fi

if [ ! -d "repos/nuoa-io-backend-shared-services" ]; then
    echo -e "${RED}✗ Missing: repos/nuoa-io-backend-shared-services${NC}"
    REPOS_OK=false
else
    echo -e "${GREEN}✓ repos/nuoa-io-backend-shared-services${NC}"
fi

if [ ! -d "repos/nuoa-io-admin-ui" ]; then
    echo -e "${RED}✗ Missing: repos/nuoa-io-admin-ui${NC}"
    REPOS_OK=false
else
    echo -e "${GREEN}✓ repos/nuoa-io-admin-ui${NC}"
fi

if [ ! -d "repos/admin-console-nuoa-react" ]; then
    echo -e "${RED}✗ Missing: repos/admin-console-nuoa-react${NC}"
    REPOS_OK=false
else
    echo -e "${GREEN}✓ repos/admin-console-nuoa-react${NC}"
fi

# Check if venv exists
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}⚠ Python virtual environment not found${NC}"
else
    echo -e "${GREEN}✓ Python virtual environment (.venv)${NC}"
fi

# Check if node_modules exist
DEPS_OK=true
if [ ! -d "repos/nuoa-io-admin-ui/node_modules" ]; then
    echo -e "${YELLOW}⚠ Missing: repos/nuoa-io-admin-ui/node_modules${NC}"
    DEPS_OK=false
else
    echo -e "${GREEN}✓ repos/nuoa-io-admin-ui/node_modules${NC}"
fi

if [ ! -d "repos/admin-console-nuoa-react/node_modules" ]; then
    echo -e "${YELLOW}⚠ Missing: repos/admin-console-nuoa-react/node_modules${NC}"
    DEPS_OK=false
else
    echo -e "${GREEN}✓ repos/admin-console-nuoa-react/node_modules${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Final status
if [ "$REPOS_OK" = true ] && [ "$DEPS_OK" = true ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✓ Setup completed successfully!           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Activate Python environment:  ${GREEN}source .venv/bin/activate${NC}"
    echo "  2. Start admin UI dev server:    ${GREEN}make dev-admin${NC}"
    echo "  3. Start console dev server:     ${GREEN}make dev-console${NC}"
    echo "  4. Run tests:                    ${GREEN}make test-all${NC}"
    echo ""
    echo -e "${BLUE}For more commands: ${GREEN}make help${NC}"
    exit 0
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║     ⚠ Setup completed with warnings            ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Some components may be missing or incomplete.${NC}"
    echo -e "${YELLOW}Please review the output above and fix any issues.${NC}"
    echo ""
    echo -e "${BLUE}To retry:${NC}"
    echo "  ${GREEN}bash $0${NC}"
    exit 0
fi

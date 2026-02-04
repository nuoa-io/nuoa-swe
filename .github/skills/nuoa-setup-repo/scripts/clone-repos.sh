#!/bin/bash

# NUOA Setup Repository - Clone Repositories Script
# Clones all 4 NUOA repositories with SSH config detection

set +e

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

# Repositories to clone
declare -A REPOS=(
    ["nuoa-io-backend-tenant-services"]="nuoa-io/nuoa-io-backend-tenant-services.git"
    ["nuoa-io-backend-shared-services"]="nuoa-io/nuoa-io-backend-shared-services.git"
    ["nuoa-io-admin-ui"]="nuoa-io/nuoa-io-admin-ui.git"
    ["admin-console-nuoa-react"]="nuoa-io/admin-console-nuoa-react.git"
)

# Detect SSH host from ~/.ssh/config
detect_ssh_host() {
    local SSH_HOST="github.com"
    
    if [ -f ~/.ssh/config ]; then
        # Check for NUOA-specific GitHub host first
        if grep -q "^Host github-nuoa" ~/.ssh/config; then
            echo -e "${BLUE}📝 Detected NUOA SSH host in ~/.ssh/config: ${GREEN}github-nuoa${NC}" >&2
            SSH_HOST="github-nuoa"
        else
            # Check for other GitHub custom hosts
            local CUSTOM_HOSTS=$(grep -E "^Host " ~/.ssh/config | grep -i github | awk '{print $2}' | head -n 1)
            
            if [ ! -z "$CUSTOM_HOSTS" ]; then
                echo -e "${BLUE}📝 Detected custom SSH host in ~/.ssh/config: ${GREEN}$CUSTOM_HOSTS${NC}" >&2
                SSH_HOST="$CUSTOM_HOSTS"
            fi
        fi
    fi
    
    echo "$SSH_HOST"
}

# Test SSH connection
test_ssh_connection() {
    local SSH_HOST=$1
    
    echo -e "${BLUE}🔐 Testing SSH connection to $SSH_HOST...${NC}"
    
    if ssh -T git@"$SSH_HOST" 2>&1 | grep -q "successfully authenticated"; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
        return 0
    elif ssh -T git@"$SSH_HOST" 2>&1 | grep -q "Hi"; then
        echo -e "${GREEN}✓ SSH connection successful${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ SSH connection test inconclusive, will try cloning anyway${NC}"
        return 0
    fi
}

# Clone a repository
clone_repo() {
    local REPO_NAME=$1
    local REPO_PATH=$2
    local SSH_HOST=$3
    local TARGET_DIR="$MONOREPO_ROOT/repos/$REPO_NAME"
    
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}⊘ $REPO_NAME already exists, skipping${NC}"
        return 0
    fi
    
    echo -e "${BLUE}📦 Cloning $REPO_NAME...${NC}"
    
    local GIT_URL="git@$SSH_HOST:$REPO_PATH"
    echo -e "   ${BLUE}URL: ${NC}$GIT_URL"
    
    if git clone "$GIT_URL" "$TARGET_DIR" 2>&1 | sed 's/^/   /'; then
        echo -e "${GREEN}✓ Successfully cloned $REPO_NAME${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to clone $REPO_NAME${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Clone NUOA Repositories${NC}"
    echo ""
    
    cd "$MONOREPO_ROOT"
    
    # Create repos directory if it doesn't exist
    if [ ! -d "repos" ]; then
        echo -e "${BLUE}📁 Creating repos directory...${NC}"
        mkdir -p repos
        echo -e "${GREEN}✓ Created repos directory${NC}"
        echo ""
    fi
    
    # Detect SSH host
    SSH_HOST=$(detect_ssh_host)
    echo -e "${BLUE}🔑 Using SSH host: ${GREEN}$SSH_HOST${NC}"
    echo ""
    
    # Test SSH connection
    test_ssh_connection "$SSH_HOST"
    echo ""
    
    # Clone repositories
    local FAILED_REPOS=()
    local SUCCESS_COUNT=0
    local SKIP_COUNT=0
    
    for REPO_NAME in "${!REPOS[@]}"; do
        REPO_PATH="${REPOS[$REPO_NAME]}"
        
        if clone_repo "$REPO_NAME" "$REPO_PATH" "$SSH_HOST"; then
            if [ -d "$MONOREPO_ROOT/repos/$REPO_NAME" ]; then
                ((SUCCESS_COUNT++))
            else
                ((SKIP_COUNT++))
            fi
        else
            FAILED_REPOS+=("$REPO_NAME")
        fi
        
        echo ""
    done
    
    # Summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}📊 Clone Summary${NC}"
    echo ""
    echo -e "  ${GREEN}Cloned:  $SUCCESS_COUNT${NC}"
    echo -e "  ${YELLOW}Skipped: $SKIP_COUNT${NC}"
    echo -e "  ${RED}Failed:  ${#FAILED_REPOS[@]}${NC}"
    
    if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed repositories:${NC}"
        for REPO in "${FAILED_REPOS[@]}"; do
            echo -e "  ${RED}• $REPO${NC}"
        done
        echo ""
        echo -e "${YELLOW}💡 Troubleshooting tips:${NC}"
        echo "  1. Check SSH key: ${GREEN}ssh -T git@$SSH_HOST${NC}"
        echo "  2. Add SSH key: ${GREEN}ssh-add ~/.ssh/id_rsa${NC}"
        echo "  3. Check ~/.ssh/config for custom hosts"
        echo "  4. Verify GitHub access permissions"
        return 1
    fi
    
    return 0
}

# Run main function
main

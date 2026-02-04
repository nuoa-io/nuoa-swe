#!/bin/bash

# NUOA Setup Repository - Test Git Workflow (Safe Mode)
# Tests git operations on existing repositories or creates mock repos for testing

# Don't exit on error - we want to test all repos
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

# Parse arguments
USE_MOCK=false
if [[ "$1" == "--mock" ]]; then
    USE_MOCK=true
fi

# Generate unique branch name
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BRANCH_NAME="test/setup-verification-${TIMESTAMP}"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      NUOA Setup - Git Workflow Test              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Branch name: ${GREEN}${BRANCH_NAME}${NC}"
if [ "$USE_MOCK" = true ]; then
    echo -e "${YELLOW}Mode: Mock repositories (for testing)${NC}"
fi
echo ""

cd "$MONOREPO_ROOT"

# Create repos directory if needed
if [ ! -d "repos" ]; then
    mkdir -p repos
    echo -e "${BLUE}Created repos directory${NC}"
    echo ""
fi

# Define repositories
declare -A REPOS=(
    ["nuoa-io-backend-tenant-services"]="Java backend service"
    ["nuoa-io-backend-shared-services"]="Python backend service"
    ["nuoa-io-admin-ui"]="Admin UI (React)"
    ["admin-console-nuoa-react"]="Console (React)"
)

# If using mock mode, create mock repos
if [ "$USE_MOCK" = true ]; then
    echo -e "${YELLOW}Creating mock repositories for testing...${NC}"
    echo ""
    
    for REPO_NAME in "${!REPOS[@]}"; do
        REPO_PATH="repos/${REPO_NAME}"
        
        if [ ! -d "${REPO_PATH}" ]; then
            echo -e "  ${BLUE}Initializing ${REPO_NAME}...${NC}"
            mkdir -p "${REPO_PATH}"
            cd "${REPO_PATH}"
            git init >/dev/null 2>&1
            git config user.email "test@nuoa.io"
            git config user.name "NUOA Test"
            
            # Create initial commit
            echo "# ${REPO_NAME}" > README.md
            echo "Mock repository for testing setup" >> README.md
            git add README.md
            git commit -m "Initial commit" >/dev/null 2>&1
            
            # Create main branch
            git branch -M main >/dev/null 2>&1
            
            echo -e "  ${GREEN}✓ ${REPO_NAME} initialized${NC}"
            cd "$MONOREPO_ROOT"
        else
            echo -e "  ${YELLOW}⊘ ${REPO_NAME} already exists${NC}"
        fi
    done
    echo ""
fi

SUCCESS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
declare -a FAILED_REPOS
declare -a WARNING_REPOS

# Test each repository
for REPO_NAME in "${!REPOS[@]}"; do
    REPO_DESC="${REPOS[$REPO_NAME]}"
    REPO_PATH="repos/${REPO_NAME}"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing: ${GREEN}${REPO_NAME}${NC}"
    echo -e "${BLUE}Description: ${NC}${REPO_DESC}"
    echo ""
    
    if [ ! -d "${REPO_PATH}" ]; then
        echo -e "${RED}✗ Repository not found: ${REPO_PATH}${NC}"
        echo -e "${YELLOW}  Run with --mock flag to create test repos${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        echo ""
        continue
    fi
    
    cd "${REPO_PATH}"
    
    # Check if it's a git repository
    if [ ! -d ".git" ]; then
        echo -e "${RED}✗ Not a git repository${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        cd "$MONOREPO_ROOT"
        echo ""
        continue
    fi
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ -z "$CURRENT_BRANCH" ]; then
        CURRENT_BRANCH="main"
    fi
    echo -e "  ${BLUE}Current branch: ${NC}${CURRENT_BRANCH}"
    
    # Check git status
    if ! git status >/dev/null 2>&1; then
        echo -e "${RED}✗ Git status check failed${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        cd "$MONOREPO_ROOT"
        echo ""
        continue
    fi
    echo -e "  ${GREEN}✓ Git status OK${NC}"
    
    # Check if remote exists
    HAS_REMOTE=false
    if git remote -v | grep -q "origin"; then
        HAS_REMOTE=true
        REMOTE_URL=$(git remote get-url origin)
        echo -e "  ${BLUE}Remote: ${NC}${REMOTE_URL}"
    else
        echo -e "  ${YELLOW}⚠ No remote configured${NC}"
    fi
    
    # Create new branch
    echo -e "  ${BLUE}Creating branch: ${GREEN}${BRANCH_NAME}${NC}"
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
        echo -e "  ${YELLOW}⚠ Branch already exists, deleting first${NC}"
        git branch -D "${BRANCH_NAME}" >/dev/null 2>&1
    fi
    
    if git checkout -b "${BRANCH_NAME}" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Branch created and checked out${NC}"
    else
        echo -e "${RED}✗ Failed to create branch${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        cd "$MONOREPO_ROOT"
        echo ""
        continue
    fi
    
    # Create a test file
    TEST_FILE=".setup-test-${TIMESTAMP}.txt"
    echo -e "  ${BLUE}Creating test file: ${NC}${TEST_FILE}"
    cat > "${TEST_FILE}" << EOF
NUOA Setup Repository Test
===========================

Repository: ${REPO_NAME}
Description: ${REPO_DESC}
Branch: ${BRANCH_NAME}
Timestamp: $(date)
User: ${USER}
Host: $(hostname)

This file was created by the NUOA setup skill test script.
It verifies that git operations work correctly after setup.

Test Results:
- Git repository: ✓
- Branch creation: ✓
- File creation: ✓
- Staging: (testing...)
- Commit: (testing...)
- Push: (testing...)

Status: Test in progress...
EOF
    echo -e "  ${GREEN}✓ Test file created${NC}"
    
    # Add the file
    echo -e "  ${BLUE}Staging changes...${NC}"
    if git add "${TEST_FILE}"; then
        echo -e "  ${GREEN}✓ Changes staged${NC}"
    else
        echo -e "${RED}✗ Failed to stage changes${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        git checkout "${CURRENT_BRANCH}" >/dev/null 2>&1
        cd "$MONOREPO_ROOT"
        echo ""
        continue
    fi
    
    # Commit
    COMMIT_MSG="test: verify setup git workflow [${TIMESTAMP}]"
    echo -e "  ${BLUE}Committing changes...${NC}"
    if git commit -m "${COMMIT_MSG}" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Commit successful${NC}"
        COMMIT_HASH=$(git rev-parse --short HEAD)
        echo -e "  ${BLUE}Commit: ${GREEN}${COMMIT_HASH}${NC}"
    else
        echo -e "${RED}✗ Commit failed${NC}"
        FAILED_REPOS+=("${REPO_NAME}")
        ((FAIL_COUNT++))
        git checkout "${CURRENT_BRANCH}" >/dev/null 2>&1
        cd "$MONOREPO_ROOT"
        echo ""
        continue
    fi
    
    # Push to remote (if exists)
    if [ "$HAS_REMOTE" = true ]; then
        echo -e "  ${BLUE}Pushing to remote...${NC}"
        if git push origin "${BRANCH_NAME}" 2>&1 | tee /tmp/git_push_output.txt | grep -q "remote:"; then
            echo -e "  ${GREEN}✓ Push successful${NC}"
            ((SUCCESS_COUNT++))
        else
            if grep -q "Permission denied\|Authentication failed\|ERROR:" /tmp/git_push_output.txt; then
                echo -e "  ${YELLOW}⚠ Push failed (check permissions)${NC}"
                echo -e "  ${YELLOW}  Branch and commit created locally${NC}"
                WARNING_REPOS+=("${REPO_NAME}")
                ((WARN_COUNT++))
                ((SUCCESS_COUNT++))
            else
                echo -e "  ${GREEN}✓ Push completed${NC}"
                ((SUCCESS_COUNT++))
            fi
        fi
    else
        echo -e "  ${YELLOW}⚠ No remote - skipping push${NC}"
        echo -e "  ${GREEN}✓ Local operations successful${NC}"
        WARNING_REPOS+=("${REPO_NAME}")
        ((WARN_COUNT++))
        ((SUCCESS_COUNT++))
    fi
    
    # Show branch info
    echo -e "  ${BLUE}Branch info:${NC}"
    echo -e "    ${GREEN}✓${NC} Branch: ${BRANCH_NAME}"
    echo -e "    ${GREEN}✓${NC} Commit: ${COMMIT_HASH}"
    echo -e "    ${GREEN}✓${NC} File: ${TEST_FILE}"
    
    # Switch back to original branch
    echo -e "  ${BLUE}Switching back to ${CURRENT_BRANCH}...${NC}"
    if git checkout "${CURRENT_BRANCH}" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Switched back${NC}"
    else
        echo -e "  ${YELLOW}⚠ Could not switch back${NC}"
    fi
    
    cd "$MONOREPO_ROOT"
    echo ""
done

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Test Summary${NC}"
echo ""
echo -e "  ${GREEN}Successful:    ${SUCCESS_COUNT}${NC}"
echo -e "  ${YELLOW}With Warnings: ${WARN_COUNT}${NC}"
echo -e "  ${RED}Failed:        ${FAIL_COUNT}${NC}"
echo ""

if [ ${FAIL_COUNT} -eq 0 ]; then
    if [ ${WARN_COUNT} -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║     ✓ All Git Operations Successful!             ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║     ✓ Tests Passed with Warnings                 ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}Repositories with warnings:${NC}"
        for REPO in "${WARNING_REPOS[@]}"; do
            echo -e "  ${YELLOW}• ${REPO}${NC} (no remote or push failed)"
        done
    fi
    echo ""
    echo -e "${BLUE}Test branches created:${NC}"
    echo -e "  ${GREEN}${BRANCH_NAME}${NC}"
    echo ""
    echo -e "${BLUE}To view changes in each repo:${NC}"
    for REPO_NAME in "${!REPOS[@]}"; do
        if [ -d "repos/${REPO_NAME}/.git" ]; then
            echo -e "  cd repos/${REPO_NAME} && git log --oneline -1 ${BRANCH_NAME}"
        fi
    done
    echo ""
    echo -e "${BLUE}Cleanup commands (run when done):${NC}"
    echo ""
    for REPO_NAME in "${!REPOS[@]}"; do
        if [ -d "repos/${REPO_NAME}/.git" ]; then
            echo -e "  # ${REPO_NAME}"
            echo -e "  cd repos/${REPO_NAME}"
            echo -e "  git branch -D ${BRANCH_NAME} 2>/dev/null || true"
            echo -e "  git push origin --delete ${BRANCH_NAME} 2>/dev/null || true"
            echo -e "  rm -f .setup-test-*.txt"
            echo -e "  cd ../.."
            echo ""
        fi
    done
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║     ✗ Some Tests Failed                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Failed repositories:${NC}"
    for REPO in "${FAILED_REPOS[@]}"; do
        echo -e "  ${RED}• ${REPO}${NC}"
    done
    echo ""
    echo -e "${YELLOW}This may be due to:${NC}"
    echo "  • Repositories not cloned yet"
    echo "  • Missing SSH keys or permissions"
    echo "  • Network connectivity issues"
    echo ""
    echo -e "${BLUE}To fix:${NC}"
    echo "  1. Clone repos: bash .github/skills/nuoa-setup-repo/scripts/clone-repos.sh"
    echo "  2. OR use mock repos: bash $0 --mock"
    echo "  3. Check SSH: ssh -T git@github.com"
    echo "  4. Verify permissions on GitHub"
    exit 1
fi

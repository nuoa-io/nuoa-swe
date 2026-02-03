#!/bin/bash

# NUOA Feature Development - Plan Generator
# This script helps create a structured plan for a new feature

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Get repository name from path
REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")

echo -e "${BLUE}NUOA Feature Development - Plan Generator${NC}"
echo -e "${BLUE}Repository: ${GREEN}${REPO_NAME}${NC}"
echo -e "${BLUE}Branch: ${GREEN}${BRANCH_NAME}${NC}"
echo ""

# Extract domain from branch name or ask user
extract_domain() {
  local branch=$1
  
  # Try to extract domain from branch name
  if [[ $branch =~ (activity|report|analytics|entity|access|job|notification|tenant|user|monitoring) ]]; then
    echo "${BASH_REMATCH[1]}management"
  else
    # Ask user
    echo -e "${YELLOW}Could not auto-detect domain from branch name.${NC}"
    echo -e "Common domains: activitymanagement, reportmanagement, analyticsmanagement, entitymanagement"
    read -p "Enter domain name: " domain
    echo "$domain"
  fi
}

# Generate plan filename from branch name
generate_plan_name() {
  local branch=$1
  # Remove feature/, fix/, feat/ prefixes
  branch=$(echo "$branch" | sed 's|^feature/||; s|^fix/||; s|^feat/||')
  # Replace slashes and hyphens with underscores
  branch=$(echo "$branch" | tr '/-' '_')
  echo "${branch}.md"
}

# Detect domain
DOMAIN=$(extract_domain "$BRANCH_NAME")
echo -e "${GREEN}Domain: ${DOMAIN}${NC}"

# Generate plan name
PLAN_NAME=$(generate_plan_name "$BRANCH_NAME")
echo -e "${GREEN}Plan filename: ${PLAN_NAME}${NC}"
echo ""

# Create directory structure
AGENT_DIR="agent/${DOMAIN}"
mkdir -p "${AGENT_DIR}/context"
mkdir -p "${AGENT_DIR}/plan"
mkdir -p "${AGENT_DIR}/log"

echo -e "${GREEN}✓ Created directory structure: ${AGENT_DIR}${NC}"

# Check if plan already exists
PLAN_FILE="${AGENT_DIR}/plan/${PLAN_NAME}"
if [ -f "$PLAN_FILE" ]; then
  echo -e "${YELLOW}⚠ Plan file already exists: ${PLAN_FILE}${NC}"
  read -p "Overwrite? (y/n): " overwrite
  if [[ ! $overwrite =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
  fi
fi

# Get feature title
echo ""
read -p "Enter feature title: " FEATURE_TITLE
read -p "Enter brief description: " FEATURE_DESC

# Create plan file
cat > "$PLAN_FILE" << EOF
# Feature: ${FEATURE_TITLE}

## Context
- **Branch**: \`${BRANCH_NAME}\`
- **Domain**: ${DOMAIN}
- **Date**: $(date +%Y-%m-%d)
- **Repository**: ${REPO_NAME}

## Description
${FEATURE_DESC}

## Requirements
<!-- List the requirements from analysis -->
- Requirement 1
- Requirement 2
- Requirement 3

## Technical Approach
<!-- Describe the technical approach to implement this feature -->

### Architecture
<!-- Describe any architectural decisions or patterns -->

### Technology Choices
<!-- List technologies, libraries, or tools to use -->

## Implementation Steps

### Phase 1: Setup
- [ ] Analyze related documentation
- [ ] Identify files to modify
- [ ] Create necessary directories

### Phase 2: Implementation
- [ ] Implement core logic
- [ ] Add error handling
- [ ] Add logging/monitoring

### Phase 3: Testing
- [ ] Write unit tests
- [ ] Write integration tests (if needed)
- [ ] Manual testing

### Phase 4: Deployment
- [ ] Build and verify
- [ ] Update Lambda/Deploy (if applicable)
- [ ] Verify in dev environment

### Phase 5: Documentation
- [ ] Update code comments
- [ ] Update API documentation
- [ ] Update README if needed

## Files to Modify
<!-- List the files that need to be created or modified -->
- \`path/to/file1\`
- \`path/to/file2\`

## Testing Strategy
<!-- Describe how you will test this feature -->

### Unit Tests
- Test case 1
- Test case 2

### Integration Tests
- Integration test 1

### Manual Testing
- Manual test scenario 1

## API Changes
<!-- If this involves API changes, document them here -->

### New Endpoints
\`\`\`
POST /api/endpoint
GET /api/endpoint/:id
\`\`\`

### Modified Endpoints
\`\`\`
PUT /api/existing/:id
\`\`\`

## Deployment Notes
<!-- Any special considerations for deployment -->
- Deployment step 1
- Deployment step 2

## Rollback Plan
<!-- How to rollback if something goes wrong -->

## Dependencies
<!-- List any dependencies on other features or services -->

## Risks & Mitigation
<!-- Identify potential risks and how to mitigate them -->

## Success Criteria
<!-- Define what success looks like -->
- [ ] All tests pass
- [ ] Feature works as expected
- [ ] No performance degradation
- [ ] Documentation updated

## Notes
<!-- Any additional notes -->

## Status
- **Status**: 🔵 Planning
- **Progress**: 0%
- **Last Updated**: $(date +%Y-%m-%d)

<!-- Update status as work progresses:
- 🔵 Planning
- 🟡 In Progress
- 🟢 Complete
- 🔴 Blocked
-->
EOF

echo -e "${GREEN}✓ Created plan file: ${PLAN_FILE}${NC}"

# Open in default editor
if command -v code &> /dev/null; then
  echo -e "${BLUE}Opening plan in VS Code...${NC}"
  code "$PLAN_FILE"
elif command -v nano &> /dev/null; then
  echo -e "${BLUE}Opening plan in nano...${NC}"
  nano "$PLAN_FILE"
else
  echo -e "${YELLOW}Open this file to edit: ${PLAN_FILE}${NC}"
fi

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Edit the plan file: ${PLAN_FILE}"
echo "2. Fill in the requirements and implementation steps"
echo "3. Start implementing following the plan"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  cat ${PLAN_FILE}           # View the plan"
echo "  git add ${AGENT_DIR}        # Stage the plan"
echo "  git commit -m 'Add feature plan'  # Commit the plan"

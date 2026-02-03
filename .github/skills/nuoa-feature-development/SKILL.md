# NUOA Feature Development Skill

## Overview

Structured workflow for implementing features across all NUOA repositories with automatic domain detection and plan generation.

##Quick Start

```bash
# 1. Create branch
git checkout -b feature/your-feature

# 2. Generate plan
bash .github/skills/nuoa-feature-development/scripts/create-plan.sh
# or from monorepo root: make skill-create-plan

# 3. Implement following repository workflow
# 4. Document in agent/{domain}/log/
# 5. Commit
```

## Workflows by Repository

### Frontend (admin-console, admin-ui)

**Step 1: Implement Components**
```bash
cd repos/admin-console-nuoa-react  # or nuoa-io-admin-ui
# Create/modify component in src/sections/{domain}/
# Example: src/sections/reportmanagement/export-dialog.tsx
```

**Step 2: Update Supporting Files**
```bash
# Update routing in src/routes/sections.tsx
# Update API calls in src/api/{domain}.ts
# Update types in src/types/{domain}.ts
```

**Step 3: Run Tests**
```bash
yarn test                    # Run unit tests
yarn tsc --noEmit           # Type checking
yarn lint:fix               # Fix linting issues
```

**Step 4: Manual Testing**
```bash
yarn dev                    # Start dev server
# admin-console: http://localhost:4200
# admin-ui: http://localhost:5173
```

**Test with Chrome MCP (if needed):**
- Navigate to login page
- Fill in credentials:
  - **Domain Name**: [Company name/ten cong ty]
  - **User Email**: [User email address]
  - **Password**: [User password]
- Use Chrome MCP tools to interact with UI:
  - `mcp_chrome_take_snapshot` - Get page structure
  - `mcp_chrome_fill` - Fill form fields
  - `mcp_chrome_click` - Click buttons/links
  - `mcp_chrome_take_screenshot` - Capture visual results
- Test the implemented feature thoroughly

**Step 5: Build**
```bash
yarn build                  # Production build
```

---

### Backend Java (tenant-services)

**Step 1: Implement Handler**
```bash
cd repos/nuoa-io-backend-tenant-services
# Create/modify handler in src/java/{domain}/handlers/
# Example: src/java/reportmanagement/handlers/ExportHandler.java
```

**Step 2: Build & Test**
```bash
mvn clean package -DskipITs        # Build without integration tests
# Check target/ for jar file
```

**Step 3: Update Lambda**
```bash
bash src/java/update_lambda.sh --profile aws-beta --query {FunctionName} --all
# Example: --query ReportExportLambda
```

**Step 4: Test API**
```bash
bash agent/call_api.sh              # Test the API endpoint
# Review response
```

**Step 5: Monitor Logs**
```bash
aws logs tail /aws/lambda/{FunctionName} --follow --profile aws-beta
# Check for errors or issues
```

---

### Backend Python (shared-services)

**Step 1: Implement Lambda**
```bash
cd repos/nuoa-io-backend-shared-services
# Create/modify lambda in src/python/lambdas/{domain}/
# Example: src/python/lambdas/reportmanagement/export.py
```

**Step 2: Activate venv & Test**
```bash
source ../../.venv/bin/activate     # Activate Python virtual env
pytest                               # Run tests
```

**Step 3: Update Lambda**
```bash
bash ../../.github/skills/nuoa-update-lambda/update_lambda.sh --profile aws-beta --query {FunctionName}
# Example: --query ReportExportFunction
```

**Step 4: Monitor Logs**
```bash
aws logs tail /aws/lambda/{FunctionName} --follow --profile aws-beta
# Check execution logs
```

---

### Infrastructure (CDK)

**Step 1: Modify Infrastructure**
```bash
cd repos/nuoa-io-backend-shared-services  # or tenant-services
# Modify construct in lib/*-construct.ts
# Example: lib/report-management-construct.ts
# Or modify stack in lib/stacks/
```

**Step 2: Run Tests**
```bash
npm run test test/{your-test}.test.ts
# Example: npm run test test/constructs/report-management.test.ts
```

**Step 3: Synthesize**
```bash
npx cdk synth --no-staging --context profile=aws-beta
# Review CloudFormation output in cdk.out/
```

**Step 4: DO NOT Deploy**
```bash
# DO NOT run: cdk deploy
# Changes will be deployed via pipeline
# Commit and push to trigger pipeline
```

## Domains

- `activitymanagement` - Activity CRUD, calculations
- `reportmanagement` - Reports, templates, exports
- `analyticsmanagement` - Analytics, metrics
- `entitymanagement` - Entity CRUD, hierarchy
- `accessmanagement` - Auth, permissions
- `jobmanagement` - Background jobs

## Makefile Commands

```bash
make skill-create-plan              # Generate plan
make dev-admin / dev-console        # Start frontends
make test-all                       # All tests
make lint / format                  # Code quality
```

**AWS Profile**: `aws-beta`

# NUOA SWE Monorepo

> Monorepo for NUOA software engineering projects - designed for autonomous agent workflows with minimal human interaction.

### Projects

| Project | Purpose | Tech Stack |
|---------|---------|------------|
| [admin-console-nuoa-react](repos/admin-console-nuoa-react/) | Admin console for staff | React, TypeScript, Vite |
| [nuoa-io-backend-shared-services](repos/nuoa-io-backend-shared-services/) | Shared infrastructure | AWS CDK, Python |
| [nuoa-io-backend-tenant-services](repos/nuoa-io-backend-tenant-services/) | Business logic services | AWS CDK, Java 11, Python |
| [nuoa-io-admin-ui](repos/nuoa-io-admin-ui/) | User dashboard | React, TypeScript, MUI |

## 📋 Prerequisites

### Required Tools

- **Node.js**: 18.x or 20.x LTS
- **Python**: 3.9+ (3.12 recommended)
- **Java**: 11 (for tenant services)
- **AWS CLI**: 2.x
- **Maven**: 3.8+ (for Java projects)
- **Git**: 2.x

### Optional Tools

- **Docker**: For local testing with LocalStack
- **jq**: For JSON processing in scripts
- **GitHub Copilot**: For AI-assisted development with MCP servers

### Install Prerequisites

```bash
# macOS
brew install node python@3.12 openjdk@11 awscli maven git jq

# Ubuntu/Debian
sudo apt update
sudo apt install nodejs python3.12 openjdk-11-jdk awscli maven git jq

# Verify installations
node --version    # Should be 18.x or 20.x
python3 --version # Should be 3.9+
java --version    # Should be 11.x
aws --version     # Should be 2.x
mvn --version     # Should be 3.8+
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/nuoa/nuoa-swe.git
cd nuoa-swe
```

### 2. Setup Python Environment

```bash
# Run setup script to create virtual environment and install dependencies
./setup.sh

# Activate virtual environment
source .venv/bin/activate

# Verify installation
python -c "import boto3; print('✓ boto3 installed')"
python -c "import pytest; print('✓ pytest installed')"
```

### 3. Configure AWS Credentials

```bash
# Configure AWS CLI profiles for different environments
aws configure --profile aws-dev
aws configure --profile aws-beta
aws configure --profile aws-prod

# Verify configuration
aws sts get-caller-identity --profile aws-dev
```

### 4. Setup Environment Variables

```bash
# Create .env file for scripts (copy from template)
cp .env.example .env

# Edit .env with your credentials
nano .env
```

Example `.env` file:
```env
# Admin Base URL
ADMIN_BASE_URL=https://admin.beta.nuoa.io

# Tenant Configuration
TENANT_NAME=your-tenant-name

# User Credentials
USER_EMAIL=user@example.com
USER_PASSWORD=your-password
```

### 5. Build Projects

```bash
# Build Java tenant services
cd repos/nuoa-io-backend-tenant-services
mvn clean package
cd ../..

# Install frontend dependencies
cd repos/nuoa-io-admin-ui
npm install
cd ../..

cd repos/admin-console-nuoa-react
npm install
cd ../..
```

### 6. Configure MCP Servers (Optional)

Model Context Protocol (MCP) servers enhance GitHub Copilot with additional capabilities like browser automation, memory, and documentation access.

```bash
# Copy MCP environment template
cp .mcp/.env.example .mcp/.env

# Edit .mcp/.env with your API keys
nano .mcp/.env
```

#### Get MCP API Keys

**Context7 (Library Documentation)**
1. Visit [Upstash Console](https://console.upstash.com/)
2. Sign up or log in
3. Create a new API key
4. Copy the key to `CONTEXT7_API_KEY` in `.mcp/.env`

**Atlassian (Jira/Confluence)**
1. Visit [Atlassian API Tokens](https://id.atlassian.com/manage-profile/security/api-tokens)
2. Click "Create API token"
3. Name it "GitHub Copilot MCP"
4. Copy the token to `ATLASSIAN_TOKEN` in `.mcp/.env`

**Memory Server**
- No API key needed, uses local file storage
- Default path: `.mcp/memory.json`

**Activate MCP Servers:**

```bash
# 1. Edit the .env file with your actual API keys
cp .mcp/.env.example .mcp/.env
nano .mcp/.env  # Add your API keys here

# 2. Load environment variables (required for each terminal session)
source .mcp/setup-mcp-env.sh

# 3. For persistent setup, add to your shell profile
echo 'source ~/dev-nuoa/nuoa-swe/.mcp/setup-mcp-env.sh' >> ~/.zshrc
source ~/.zshrc
```

**Troubleshooting MCP Not Showing in Copilot:**

If MCP tools don't appear in Copilot Chat:

1. **Check symlink exists:**
   ```bash
   ls -la ~/.config/github-copilot/mcp.json
   # Should point to: /home/datpham-nuoa/dev-nuoa/nuoa-swe/.mcp/config.json
   ```

2. **Verify environment variables are loaded:**
   ```bash
   source .mcp/setup-mcp-env.sh
   echo $MEMORY_FILE_PATH
   echo $CONTEXT7_API_KEY
   ```

3. **Restart VS Code completely:**
   - Close all VS Code windows
   - Reopen from terminal with env vars loaded:
   ```bash
   source .mcp/setup-mcp-env.sh
   code .
   ```

4. **Check VS Code Output:**
   - In VS Code: `View` → `Output` → Select "GitHub Copilot" from dropdown
   - Look for MCP server startup messages

5. **Test MCP tools in Copilot Chat:**
   - Open Copilot Chat (`Ctrl+Alt+I` or `Cmd+Shift+I`)
   - Type `@workspace` and check if MCP tools appear
   - Try: "Use chrome to open google.com" or "Remember this: test note"

**How Detection Works:**

1. **Configuration File**: GitHub Copilot reads `~/.config/github-copilot/mcp.json` (symlinked to `.mcp/config.json`)
2. **Environment Variables**: MCP servers get API keys from shell environment variables
3. **Auto-Start**: When you use Copilot Chat/CLI, it automatically starts the configured MCP servers
4. **Tool Access**: Copilot can then use tools provided by these servers (browser automation, memory, docs, etc.)

**Verify Setup:**

```bash
# Check symlink exists
ls -la ~/.config/github-copilot/mcp.json

# Check environment variables are loaded
echo $CONTEXT7_API_KEY
echo $MEMORY_FILE_PATH

# Test with Copilot CLI
gh copilot suggest "use chrome to navigate to google.com"
```

After configuration, restart VS Code or your terminal for changes to take effect.

## 🛠️ Common Workflows

### Working with Lambda Functions

#### Update Java Lambda

```bash
# Update specific Lambda function
bash repos/nuoa-io-backend-tenant-services/src/java/update_lambda.sh \
  --profile aws-beta \
  --query ActivityManagement

# Rebuild and update
bash repos/nuoa-io-backend-tenant-services/src/java/update_lambda.sh \
  --profile aws-beta \
  --query ReportManagement \
  --rebuild

# Update all matching functions
bash repos/nuoa-io-backend-tenant-services/src/java/update_lambda.sh \
  --profile aws-beta \
  --query Management \
  --all
```

See [nuoa-update-lambda](.github/skills/nuoa-update-lambda/SKILL.md) for details.

#### Call Tenant API

```bash
# Activate virtual environment
source .venv/bin/activate

# Call API endpoint
python repos/nuoa-io-backend-tenant-services/src/python/scripts/call_api.py \
  --path /reports \
  --method GET

# POST with payload
python repos/nuoa-io-backend-tenant-services/src/python/scripts/call_api.py \
  --path /activity \
  --method POST \
  --payload '{"name":"Office Electricity","type":"energy"}'
```

See [nuoa-call-tenant](.github/skills/nuoa-call-tenant/SKILL.md) for details.

#### Reindex DynamoDB Table

```bash
# Dry run first
python repos/nuoa-io-backend-tenant-services/src/python/scripts/increase_version_of_table.py \
  --table-name Activity-beta-pooled \
  --aws-profile aws-beta \
  --dry-run

# Execute reindex
python repos/nuoa-io-backend-tenant-services/src/python/scripts/increase_version_of_table.py \
  --table-name Activity-beta-pooled \
  --aws-profile aws-beta
```

See [nuoa-reindex](.github/skills/nuoa-reindex/SKILL.md) for details.

### Running Tests

#### Python Tests

```bash
# Run all tests
cd repos/nuoa-io-backend-shared-services
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test file
pytest test/python/lambdas/auth/test_tenant_authorizer.py

# Run unit tests only
pytest -m unit
```

See [nuoa-testing-python](.github/skills/nuoa-testing-python/SKILL.md) for details.

#### Java Tests

```bash
# Run all tests
cd repos/nuoa-io-backend-tenant-services
mvn test

# Run specific test
mvn test -Dtest=ActivityGetHandlerTest

# Run with coverage
mvn clean test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

See [nuoa-testing-java](.github/skills/nuoa-testing-java/SKILL.md) for details.

#### Frontend Tests

```bash
# React app tests
cd repos/nuoa-io-admin-ui
npm test

# Run with coverage
npm run test:coverage

# E2E tests
npm run test:e2e
```

### Deploying Services

#### CDK Deployment

```bash
# Deploy shared services
cd repos/nuoa-io-backend-shared-services
npx cdk deploy --all --profile aws-beta

# Deploy tenant services
cd repos/nuoa-io-backend-tenant-services
npx cdk deploy --all --profile aws-beta

# Deploy specific stack
npx cdk deploy TenantServicesStack-beta-pooled --profile aws-beta
```

#### Frontend Deployment

```bash
# Admin UI to Vercel (via GitHub Actions)
git push origin main

# Manual deployment
cd repos/nuoa-io-admin-ui
npm run build
vercel --prod
```

## 📚 Skills and Documentation

### Custom NUOA Skills

Located in [`.github/skills/`](.github/skills/):

- **[nuoa-feature-development](.github/skills/nuoa-feature-development/SKILL.md)**: Structured workflow for implementing features across all repos
- **[nuoa-call-tenant](.github/skills/nuoa-call-tenant/SKILL.md)**: Call tenant API endpoints
- **[nuoa-update-lambda](.github/skills/nuoa-update-lambda/SKILL.md)**: Update Lambda functions
- **[nuoa-reindex](.github/skills/nuoa-reindex/SKILL.md)**: Reindex DynamoDB tables
- **[nuoa-java11](.github/skills/nuoa-java11/SKILL.md)**: Java 11 development patterns
- **[nuoa-python](.github/skills/nuoa-python/SKILL.md)**: Python development patterns
- **[nuoa-testing-java](.github/skills/nuoa-testing-java/SKILL.md)**: Java testing strategies
- **[nuoa-testing-python](.github/skills/nuoa-testing-python/SKILL.md)**: Python testing strategies

### General Skills

The repository includes 50+ general development skills covering:
- Architecture & Design
- Testing & Quality
- AWS & Infrastructure
- Git & Workflows
- Domain-Driven Design
- And more...

Browse all skills in [`.github/skills/`](.github/skills/).

## 🤖 Agent Workflows

This repository is optimized for autonomous agent operations:

### Model Context Protocol (MCP) Servers

GitHub Copilot uses MCP servers to extend its capabilities:

**Available MCP Servers:**
- **Sequential Thinking**: Advanced reasoning for complex tasks
- **Memory**: Knowledge graph for storing project context
- **Chrome DevTools**: Browser automation and web testing
- **Context7**: Access to 1000+ library documentation
- **Atlassian**: Jira and Confluence integration
- **DeepWiki**: Enhanced web search and research

**Configuration:**
- MCP config: `.mcp/config.json`
- API keys: `.mcp/.env` (gitignored)
- Symlink: `~/.config/github-copilot/mcp.json`

See [Setup MCP Servers](#6-configure-mcp-servers-optional) for configuration details.

### GitHub Copilot CLI

```bash
# Use Copilot to execute common tasks
gh copilot suggest "update the ActivityManagement lambda"
gh copilot suggest "call the reports API for tenant test-tenant"
gh copilot suggest "run Python tests with coverage"
```

### Memory and Planning

- **Agent Memory**: Key decisions and context stored in `.agents/`
- **Plans**: Implementation plans in `agent/*/plan/`
- **Logs**: Execution logs in `agent/*/log/`

### Pull Requests

Use the [PR template](.github/pull_request_template.md) which includes:
- Memory/plans update section
- Testing checklist
- Deployment notes
- Breaking changes documentation

## 🏗️ Project Structure

```
nuoa-swe/
├── .github/              # GitHub configuration
│   ├── instructions/    # Agent instructions
│   ├── skills/         # Custom skills
│   └── workflows/      # CI/CD workflows
├── .mcp/                # Model Context Protocol
│   ├── config.json     # MCP server configuration
│   ├── .env           # API keys (gitignored)
│   └── .env.example   # Environment template
├── repos/               # Project repositories
│   ├── admin-console-nuoa-react/
│   ├── nuoa-io-backend-shared-services/
│   ├── nuoa-io-backend-tenant-services/
│   └── nuoa-io-admin-ui/
├── .venv/              # Python virtual environment
├── ARCHITECTURE.md     # Architecture documentation
├── README.md           # This file
├── requirements.txt    # Python dependencies
└── setup.sh           # Setup script
```

## 🧪 Development Best Practices

### Code Quality

- **Linting**: ESLint for TypeScript, Pylint/Flake8 for Python
- **Formatting**: Prettier for frontend, Black for Python
- **Type Safety**: TypeScript strict mode, Python type hints
- **Testing**: Minimum 80% code coverage

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/new-feature
```

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add new report generation feature
fix: Resolve activity calculation bug
docs: Update API documentation
test: Add unit tests for ActivityHandler
chore: Update dependencies
refactor: Simplify authentication logic
```

## 🔒 Security

- **Secrets**: Use AWS Secrets Manager, never commit credentials
- **Environment Variables**: Use `.env` files (gitignored)
- **Access Control**: Principle of least privilege
- **Dependencies**: Regular security audits

```bash
# Audit npm packages
npm audit

# Audit Python packages
pip-audit

# Audit Maven dependencies
mvn dependency-check:check
```

## 📊 Monitoring and Debugging

### CloudWatch Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/ActivityGetHandler --follow --profile aws-beta

# Search logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/ActivityGetHandler \
  --filter-pattern "ERROR" \
  --profile aws-beta
```

### X-Ray Tracing

```bash
# View traces in AWS Console
open https://console.aws.amazon.com/xray/home
```

## 🐛 Troubleshooting

### Common Issues

#### Python Import Errors
```bash
# Ensure virtual environment is activated
source .venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### AWS Authentication Errors
```bash
# Verify credentials
aws sts get-caller-identity --profile aws-beta

# Reconfigure profile
aws configure --profile aws-beta
```

#### Lambda Update Failures
```bash
# Rebuild JAR
cd repos/nuoa-io-backend-tenant-services
mvn clean package

# Verify bucket exists
aws s3 ls s3://deployment-bucket-beta-pooled --profile aws-beta
```

#### CDK Deployment Issues
```bash
# Bootstrap CDK (first time only)
npx cdk bootstrap --profile aws-beta

# Verify CDK version
npx cdk --version

# Update CDK
npm install -g aws-cdk
```

## 📖 Additional Resources

- [Architecture Documentation](ARCHITECTURE.md)
- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [GitHub Copilot Documentation](https://docs.github.com/copilot)
- [Domain-Driven Design](.github/skills/domain-driven-design/SKILL.md)

## 🤝 Contributing

1. Check [PR template](.github/pull_request_template.md)
2. Follow code style guidelines
3. Write tests for new features
4. Update documentation
5. Update agent memory/plans

## 📝 License

Proprietary - © 2024 NUOA. All rights reserved.

## 🆘 Support

- **Internal Slack**: #nuoa-engineering
- **Documentation**: [Confluence](https://nuoa.atlassian.net/wiki)
- **Issues**: Use GitHub Issues for bug reports

---

**Made with ❤️ by the NUOA Engineering Team**

*Last Updated: February 2026*

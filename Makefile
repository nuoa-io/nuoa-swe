.PHONY: help setup venv install-deps dev-admin dev-console dev-both test test-python test-java test-frontend test-all clean lint format

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Directories
ADMIN_UI_DIR := repos/nuoa-io-admin-ui
CONSOLE_DIR := repos/admin-console-nuoa-react
SHARED_BACKEND_DIR := repos/nuoa-io-backend-shared-services
TENANT_BACKEND_DIR := repos/nuoa-io-backend-tenant-services

help: ## Show this help message
	@echo "$(BLUE)NUOA SWE Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

## Setup Commands

setup: venv install-deps ## Complete setup: venv + install all dependencies
	@echo "$(GREEN)✓ Setup complete!$(NC)"

venv: ## Create Python virtual environment and install requirements
	@echo "$(BLUE)Creating Python virtual environment...$(NC)"
	@if [ ! -d .venv ]; then \
		python3 -m venv .venv; \
		echo "$(GREEN)✓ Virtual environment created$(NC)"; \
	else \
		echo "$(YELLOW)Virtual environment already exists$(NC)"; \
	fi
	@echo "$(BLUE)Installing Python dependencies...$(NC)"
	@. .venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
	@echo "$(GREEN)✓ Python dependencies installed$(NC)"
	@echo "$(YELLOW)Run 'source .venv/bin/activate' to activate the virtual environment$(NC)"

install-deps: ## Install dependencies for all projects
	@echo "$(BLUE)Installing dependencies for all projects...$(NC)"
	@cd $(ADMIN_UI_DIR) && echo "$(BLUE)Installing nuoa-io-admin-ui...$(NC)" && yarn install
	@cd $(CONSOLE_DIR) && echo "$(BLUE)Installing admin-console-nuoa-react...$(NC)" && yarn install
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

## Development Commands

dev-admin: ## Run nuoa-io-admin-ui dev server (port 5173)
	@echo "$(BLUE)Starting nuoa-io-admin-ui dev server...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn dev

dev-console: ## Run admin-console-nuoa-react dev server (port 4200)
	@echo "$(BLUE)Starting admin-console-nuoa-react dev server...$(NC)"
	@cd $(CONSOLE_DIR) && yarn dev

dev-console-beta: ## Run admin-console-nuoa-react dev server in beta mode
	@echo "$(BLUE)Starting admin-console-nuoa-react dev server (beta)...$(NC)"
	@cd $(CONSOLE_DIR) && yarn dev:beta

dev-both: ## Run both frontend dev servers in parallel
	@echo "$(BLUE)Starting both frontend dev servers...$(NC)"
	@echo "$(YELLOW)Admin UI: http://localhost:5173$(NC)"
	@echo "$(YELLOW)Console: http://localhost:4200$(NC)"
	@make -j2 dev-admin dev-console

## Testing Commands

test: test-python ## Run all Python tests (default)

test-python: ## Run Python tests with pytest
	@echo "$(BLUE)Running Python tests...$(NC)"
	@. .venv/bin/activate && cd $(SHARED_BACKEND_DIR) && pytest

test-python-cov: ## Run Python tests with coverage report
	@echo "$(BLUE)Running Python tests with coverage...$(NC)"
	@. .venv/bin/activate && cd $(SHARED_BACKEND_DIR) && pytest --cov=src --cov-report=html --cov-report=term
	@echo "$(GREEN)Coverage report: $(SHARED_BACKEND_DIR)/htmlcov/index.html$(NC)"

test-java: ## Run Java tests with Maven
	@echo "$(BLUE)Running Java tests...$(NC)"
	@cd $(TENANT_BACKEND_DIR) && mvn test

test-java-cov: ## Run Java tests with coverage
	@echo "$(BLUE)Running Java tests with coverage...$(NC)"
	@cd $(TENANT_BACKEND_DIR) && mvn clean test jacoco:report
	@echo "$(GREEN)Coverage report: $(TENANT_BACKEND_DIR)/target/site/jacoco/index.html$(NC)"

test-admin: ## Run nuoa-io-admin-ui tests
	@echo "$(BLUE)Running nuoa-io-admin-ui tests...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn test

test-admin-e2e: ## Run nuoa-io-admin-ui E2E tests
	@echo "$(BLUE)Running E2E tests...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn test:e2e

test-console: ## Run admin-console tests
	@echo "$(BLUE)Running admin-console tests...$(NC)"
	@cd $(CONSOLE_DIR) && yarn test

test-all: ## Run all tests (Python, Java, Frontend)
	@echo "$(BLUE)Running all tests...$(NC)"
	@make test-python
	@make test-java
	@make test-admin
	@echo "$(GREEN)✓ All tests completed$(NC)"

## Skill Scripts (requires .venv)

skill-call-api: ## Call tenant API (requires .venv, args: PATH=/path METHOD=GET PAYLOAD='{}')
	@echo "$(BLUE)Calling tenant API...$(NC)"
	@. .venv/bin/activate && python .github/skills/nuoa-call-tenant/call_api.py \
		--path $(or $(PATH),/reports) \
		--method $(or $(METHOD),GET) \
		$(if $(PAYLOAD),--payload '$(PAYLOAD)',)

skill-reindex: ## Reindex DynamoDB table (requires .venv, args: TABLE=table-name PROFILE=aws-beta)
	@echo "$(BLUE)Reindexing DynamoDB table...$(NC)"
	@. .venv/bin/activate && python .github/skills/nuoa-fix-opensearch/scripts/increase_version_of_table.py \
		--table-name $(or $(TABLE),Activity-beta-pooled) \
		--aws-profile $(or $(PROFILE),aws-beta) \
		$(if $(DRY_RUN),--dry-run,)

skill-update-lambda: ## Update Lambda function (args: PROFILE=aws-beta QUERY=ActivityManagement)
	@echo "$(BLUE)Updating Lambda function...$(NC)"
	@bash .github/skills/nuoa-update-lambda/update_lambda.sh \
		--profile $(or $(PROFILE),aws-beta) \
		--query $(or $(QUERY),ActivityManagement) \
		$(if $(REBUILD),--rebuild,) \
		$(if $(ALL),--all,)

skill-create-plan: ## Create feature development plan in current repo (auto-detects branch/domain)
	@echo "$(BLUE)Creating feature development plan...$(NC)"
	@bash .github/skills/nuoa-feature-development/scripts/create-plan.sh

## Code Quality Commands

lint: ## Run linters for all projects
	@echo "$(BLUE)Running linters...$(NC)"
	@cd $(ADMIN_UI_DIR) && echo "Linting admin-ui..." && yarn lint
	@cd $(CONSOLE_DIR) && echo "Linting console..." && yarn lint
	@echo "$(GREEN)✓ Linting complete$(NC)"

lint-fix: ## Fix linting issues automatically
	@echo "$(BLUE)Fixing linting issues...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn lint:fix
	@cd $(CONSOLE_DIR) && yarn lint:fix
	@echo "$(GREEN)✓ Linting fixes applied$(NC)"

format: ## Format code with Prettier
	@echo "$(BLUE)Formatting code...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn prettier
	@cd $(CONSOLE_DIR) && yarn fm:fix
	@echo "$(GREEN)✓ Code formatted$(NC)"

format-check: ## Check code formatting
	@echo "$(BLUE)Checking code formatting...$(NC)"
	@cd $(CONSOLE_DIR) && yarn fm:check

## Build Commands

build-admin: ## Build nuoa-io-admin-ui for production
	@echo "$(BLUE)Building nuoa-io-admin-ui...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn build
	@echo "$(GREEN)✓ Admin UI built$(NC)"

build-console: ## Build admin-console-nuoa-react for production
	@echo "$(BLUE)Building admin-console-nuoa-react...$(NC)"
	@cd $(CONSOLE_DIR) && yarn build
	@echo "$(GREEN)✓ Console built$(NC)"

build-console-beta: ## Build admin-console for beta environment
	@echo "$(BLUE)Building admin-console (beta)...$(NC)"
	@cd $(CONSOLE_DIR) && yarn build:beta
	@echo "$(GREEN)✓ Console built for beta$(NC)"

build-java: ## Build Java backend services
	@echo "$(BLUE)Building Java services...$(NC)"
	@cd $(TENANT_BACKEND_DIR) && mvn clean package
	@echo "$(GREEN)✓ Java services built$(NC)"

build-all: ## Build all projects
	@make build-admin
	@make build-console
	@make build-java
	@echo "$(GREEN)✓ All projects built$(NC)"

## Clean Commands

clean-node: ## Remove all node_modules directories
	@echo "$(BLUE)Cleaning node_modules...$(NC)"
	@cd $(ADMIN_UI_DIR) && yarn clean || rm -rf node_modules
	@cd $(CONSOLE_DIR) && yarn clean || rm -rf node_modules
	@echo "$(GREEN)✓ node_modules cleaned$(NC)"

clean-python: ## Remove Python cache and build files
	@echo "$(BLUE)Cleaning Python cache...$(NC)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Python cache cleaned$(NC)"

clean-venv: ## Remove Python virtual environment
	@echo "$(BLUE)Removing virtual environment...$(NC)"
	@rm -rf .venv
	@echo "$(GREEN)✓ Virtual environment removed$(NC)"

clean-java: ## Clean Java build artifacts
	@echo "$(BLUE)Cleaning Java build...$(NC)"
	@cd $(TENANT_BACKEND_DIR) && mvn clean
	@echo "$(GREEN)✓ Java build cleaned$(NC)"

clean-all: clean-node clean-python clean-java ## Clean all build artifacts and dependencies
	@echo "$(GREEN)✓ All artifacts cleaned$(NC)"

## Utility Commands

check-env: ## Check if required tools are installed
	@echo "$(BLUE)Checking environment...$(NC)"
	@command -v node >/dev/null 2>&1 && echo "$(GREEN)✓ Node.js: $$(node --version)$(NC)" || echo "$(YELLOW)✗ Node.js not found$(NC)"
	@command -v python3 >/dev/null 2>&1 && echo "$(GREEN)✓ Python: $$(python3 --version)$(NC)" || echo "$(YELLOW)✗ Python3 not found$(NC)"
	@command -v java >/dev/null 2>&1 && echo "$(GREEN)✓ Java: $$(java -version 2>&1 | head -n 1)$(NC)" || echo "$(YELLOW)✗ Java not found$(NC)"
	@command -v mvn >/dev/null 2>&1 && echo "$(GREEN)✓ Maven: $$(mvn --version | head -n 1)$(NC)" || echo "$(YELLOW)✗ Maven not found$(NC)"
	@command -v aws >/dev/null 2>&1 && echo "$(GREEN)✓ AWS CLI: $$(aws --version)$(NC)" || echo "$(YELLOW)✗ AWS CLI not found$(NC)"
	@command -v yarn >/dev/null 2>&1 && echo "$(GREEN)✓ Yarn: $$(yarn --version)$(NC)" || echo "$(YELLOW)✗ Yarn not found$(NC)"

logs-admin: ## Tail admin UI dev server logs (if running in background)
	@echo "$(BLUE)Tailing admin UI logs...$(NC)"
	@tail -f $(ADMIN_UI_DIR)/logs/dev.log 2>/dev/null || echo "$(YELLOW)No logs found. Is dev server running?$(NC)"

info: ## Show project information
	@echo "$(BLUE)NUOA SWE Monorepo Information$(NC)"
	@echo ""
	@echo "$(GREEN)Frontend Projects:$(NC)"
	@echo "  • nuoa-io-admin-ui      → http://localhost:5173"
	@echo "  • admin-console-nuoa    → http://localhost:4200"
	@echo ""
	@echo "$(GREEN)Backend Projects:$(NC)"
	@echo "  • nuoa-io-backend-shared-services"
	@echo "  • nuoa-io-backend-tenant-services"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  make setup              # Setup everything"
	@echo "  make dev-admin          # Run admin UI"
	@echo "  make dev-console        # Run console"
	@echo "  make test-all           # Run all tests"
	@echo ""
	@echo "For more commands: make help"

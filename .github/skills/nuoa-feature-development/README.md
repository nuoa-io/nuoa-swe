# NUOA Feature Development Skill

Structured workflow for implementing features across all NUOA repositories with automatic domain detection and plan generation.

## 🚀 Quick Start

```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Generate plan (from repo root)
cd repos/{your-repo}
bash ../../.github/skills/nuoa-feature-development/scripts/create-plan.sh

# Or from monorepo root
make skill-create-plan

# 3. Fill in the plan
# Edit agent/{domain}/plan/{branch_name}.md

# 4. Implement following repository workflow
# See repository-specific agent instructions

# 5. Test and verify
# Run tests, lint, format

# 6. Document and commit
# Update log/, commit with clear message
```

## 📁 Directory Structure

```
nuoa-feature-development/
├── SKILL.md                 # Main documentation
├── QUICKSTART.md           # Quick reference
├── EXAMPLE.md              # Complete example
├── SETUP_SUMMARY.md        # Setup summary
├── README.md               # This file
├── scripts/
│   └── create-plan.sh      # Plan generation script
└── templates/
    └── AGENT_README.md     # Template for agent dirs
```

## 🎯 Supported Repositories

| Repository | Type | Agent Instructions |
|------------|------|-------------------|
| admin-console-nuoa-react | Frontend | [Link](../../../repos/admin-console-nuoa-react/.github/instructions/agent.instruction.md) |
| nuoa-io-admin-ui | Frontend | [Link](../../../repos/nuoa-io-admin-ui/.github/instructions/agent.instruction.md) |
| nuoa-io-backend-shared-services | Backend | [Link](../../../repos/nuoa-io-backend-shared-services/.github/instructions/agent.instruction.md) |
| nuoa-io-backend-tenant-services | Backend | [Link](../../../repos/nuoa-io-backend-tenant-services/.github/instructions/agent.instruction.md) |

## 🔧 Tools & Scripts

### create-plan.sh

Auto-generates feature plans with:
- Domain detection from branch name
- Plan filename generation
- Directory structure creation
- Template plan file with structure

**Usage:**
```bash
bash scripts/create-plan.sh
```

## 📋 Workflows

### Frontend Workflow
```
Analyze → Plan → Components → Tests → 
Type Check → Lint → Dev → Manual Test → Build
```

### Backend Java Workflow
```
Analyze → Plan → Handler → Tests → Build → 
Update Lambda → Test API → Logs → Fix → Format
```

### Backend Python Workflow
```
Analyze → Plan → Lambda → Tests → 
Update → Test API → Logs → Fix → Format
```

### Infrastructure Workflow
```
Analyze → Plan → Construct → Tests → 
Synth → Fix → Commit → Pipeline → Verify
```

## 🏗️ Agent Directory Structure

Each repository can have:

```
agent/
├── {domain}/
│   ├── context/        # Specs, requirements, designs
│   ├── plan/          # Implementation plans
│   │   ├── feature1.md
│   │   └── feature2.md
│   └── log/           # Logs, API docs, summaries
│       ├── implementation1.md
│       └── api_documentation.md
```

## 🎨 Common Domains

- `activitymanagement` - Activity operations
- `reportmanagement` - Report operations
- `analyticsmanagement` - Analytics & metrics
- `entitymanagement` - Entity operations
- `accessmanagement` - Auth & permissions
- `jobmanagement` - Background jobs
- `notificationmanagement` - Notifications

## 💡 For AI Agents

When receiving a task:

1. **Read** repository-specific agent instructions
2. **Extract** domain from branch/task
3. **Generate** plan using create-plan.sh
4. **Fill** plan based on analysis
5. **Track** progress with manage_todo_list
6. **Follow** repository workflow
7. **Document** in log/ when complete

## 🔗 Related Skills

- [NUOA Update Lambda](../nuoa-update-lambda/SKILL.md)
- [NUOA Call Tenant](../nuoa-call-tenant/SKILL.md)
- [NUOA Testing Java](../nuoa-testing-java/SKILL.md)
- [NUOA Testing Python](../nuoa-testing-python/SKILL.md)
- [AWS CDK Development](../aws-cdk-development/SKILL.md)

## 🛠️ Makefile Commands

From monorepo root:

```bash
make skill-create-plan              # Generate feature plan
make dev-admin                      # Start admin UI
make dev-console                    # Start console
make test-all                       # Run all tests
make lint                          # Lint all code
make format                        # Format all code
```

## 📖 Documentation

- **[SKILL.md](SKILL.md)** - Complete workflows and patterns
- **[scripts/create-plan.sh](scripts/create-plan.sh)** - Auto-generate feature plans
- **Agent Instructions** - See each repo's `.github/instructions/agent.instruction.md`

---

**Version**: 1.0  
**Last Updated**: February 2, 2026

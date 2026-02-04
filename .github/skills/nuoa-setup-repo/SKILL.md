---
name: NUOA Setup Repository
description: Automated setup workflow for NUOA development environment. Clones 4 repositories, verifies prerequisites, installs dependencies for Java/Python backends and React frontends.
---

# NUOA Setup Repository Skill

## 🎯 What This Skill Does

Automates complete NUOA development environment setup:
1. **Clone** 4 NUOA repositories (2 backends, 2 frontends)
2. **Verify** development tools (Java 11, Maven, Python 3.13+, Node.js 18+, Yarn)
3. **Install** dependencies for all projects
4. **Configure** SSH with github-nuoa support

## � Agent Quick Start

**Step 1: Run main setup**
```bash
bash .github/skills/nuoa-setup-repo/scripts/setup.sh
```

**Step 2: Verify success**
```bash
ls repos/  # Should show 4 directories
source .venv/bin/activate  # Python environment
```

**Step 3: Test repositories**
```bash
# Backend Java
cd repos/nuoa-io-backend-tenant-services && mvn test

# Backend Python  
cd repos/nuoa-io-backend-shared-services && pytest

# Frontend
cd repos/nuoa-io-admin-ui && yarn dev
```

## 📦 Repositories (Cloned to `repos/`)

| Repository | Type | Tech Stack | Clone URL |
|------------|------|------------|-----------|
| **nuoa-io-backend-tenant-services** | Backend | Java 11, Maven | `git@github-nuoa:nuoa-io/nuoa-io-backend-tenant-services.git` |
| **nuoa-io-backend-shared-services** | Backend | Python 3.13+ | `git@github-nuoa:nuoa-io/nuoa-io-backend-shared-services.git` |
| **nuoa-io-admin-ui** | Frontend | React, Vite, Yarn | `git@github-nuoa:nuoa-io/nuoa-io-admin-ui.git` |
| **admin-console-nuoa-react** | Frontend | React, Vite, Yarn | `git@github-nuoa:nuoa-io/admin-console-nuoa-react.git` |

## 🔧 Prerequisites Verified

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 11+ | Backend (tenant services) |
| Maven | 3.6+ | Java dependency management |
| Python | 3.13+ | Backend (shared services) |
| Node.js | 18+ LTS | Frontend build & dev servers |
| npm | 9+ | Package manager |
| Yarn | 1.22+ | Frontend dependencies |
| AWS CLI | 2.x | Lambda deployment |

## 📁 Directory Structure

After setup, your workspace will look like:

```
nuoa-swe/
├── .github/
│   └── skills/
│       └── nuoa-setup-repo/
│           ├── SKILL.md              # This file
│           ├── README.md             # Quick reference
│           └── scripts/
│               ├── setup.sh          # Main setup script
│               ├── clone-repos.sh    # Repository cloning
│               ├── check-prereqs.sh  # Prerequisite checker
│               └── install-deps.sh   # Dependency installer
├── repos/                            # All repositories (gitignored)
│   ├── nuoa-io-backend-tenant-services/
│   ├── nuoa-io-backend-shared-services/
│   ├── nuoa-io-admin-ui/
│   └── admin-console-nuoa-react/
├── .venv/                            # Python virtual environment
├── Makefile                          # Build commands
└── requirements.txt                  # Python dependencies
```

## 🔍 Scripts Reference

### `setup.sh` - Main Orchestrator
Runs complete setup: SSH check → prerequisites → clone → install deps

```bash
bash .github/skills/nuoa-setup-repo/scripts/setup.sh [OPTIONS]

# Options
--skip-clone      # Skip repository cloning
--skip-prereqs    # Skip prerequisite checks  
--skip-deps       # Skip dependency installation
--help            # Show usage
```

### `clone-repos.sh` - Repository Cloning
Clones all 4 repos with github-nuoa priority detection

```bash
bash .github/skills/nuoa-setup-repo/scripts/clone-repos.sh

# Features
- Prioritizes github-nuoa SSH host
- Skips existing repos (set +e)
- Validates SSH before cloning
- Reports summary (cloned/skipped/failed)
```

### `check-prereqs.sh` - Prerequisite Checker
Verifies tools and shows installation commands if missing

```bash
bash .github/skills/nuoa-setup-repo/scripts/check-prereqs.sh

# Output: ✓ Java 11.0.20, ✓ Maven 3.9.5, etc.
```

### `install-deps.sh` - Dependency Installer
Installs dependencies for all or specific projects

```bash
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh [--project NAME]

# Examples
--project tenant   # Java backend only
--project shared   # Python backend only
--project admin    # Admin UI only
--project console  # Console UI only
```

## 🎓 Usage Examples

### Complete Fresh Setup

```bash
# Clone and setup everything
cd /path/to/nuoa-swe
bash .github/skills/nuoa-setup-repo/scripts/setup.sh
```

### Update Dependencies Only

```bash
# Skip cloning, just update deps
bash .github/skills/nuoa-setup-repo/scripts/setup.sh --skip-clone
```

### Check Prerequisites Only

```bash
# Verify tools without installing anything
bash .github/skills/nuoa-setup-repo/scripts/check-prereqs.sh
```

### Clone Repositories Only

```bash
# Just clone repos, no dependency installation
bash .github/skills/nuoa-setup-repo/scripts/clone-repos.sh
```

### Install Specific Project Dependencies

```bash
# Install only frontend dependencies
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh --project admin
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh --project console

# Install only backend dependencies
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh --project tenant
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh --project shared
```

## 🔐 SSH Configuration

### Automatic Detection Priority
1. **`github-nuoa`** (checked first)
2. Other custom GitHub hosts
3. Standard `github.com` (fallback)

### Example: Custom SSH Host

`~/.ssh/config`:
```ssh-config
Host github-nuoa
    HostName github.com
    Port 443
    User git
    IdentityFile ~/.ssh/id_rsa_nuoa
```

Script automatically uses: `git@github-nuoa:nuoa-io/[repo].git`

### Troubleshooting

```bash
# Test connection
ssh -T git@github-nuoa

# Check config
cat ~/.ssh/config | grep -A5 github-nuoa

# Add SSH key
ssh-add ~/.ssh/id_rsa_nuoa
```

## 🧪 Verification Steps

After setup completes, verify everything works:

```bash
# 1. Check repos cloned
ls repos/
# Expected: 4 directories

# 2. Verify SSH remotes
cd repos && for repo in */; do git -C "$repo" remote -v | head -1; done
# Expected: All use git@github-nuoa

# 3. Test Python environment
source .venv/bin/activate
python --version
# Expected: Python 3.13+

# 4. Test Java build
cd repos/nuoa-io-backend-tenant-services
mvn clean test
# Expected: BUILD SUCCESS

# 5. Test frontend
cd repos/nuoa-io-admin-ui
yarn dev
# Expected: Dev server on localhost:5173
```

## 🛠️ Makefile Integration

The setup skill integrates with monorepo Makefile:

```bash
# Complete setup
make setup

# Install dependencies only
make install-deps

# Create Python venv
make venv

# Check environment
make check-env

# Clean and re-setup
make clean-all
make setup
```

## 🐛 Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **SSH Permission denied** | `ssh -T git@github-nuoa`<br>`ssh-add ~/.ssh/id_rsa_nuoa` |
| **Wrong Java version** | `sudo update-alternatives --config java` (Linux)<br>`sdk use java 11.0.20-amzn` (macOS) |
| **Python 3.13 not found** | `sudo apt install python3.13 python3.13-venv` (Ubuntu)<br>`brew install python@3.13` (macOS) |
| **Yarn not found** | `npm install -g yarn` |
| **Maven build fails** | `rm -rf ~/.m2/repository`<br>`mvn clean install -X` |
| **Clone exits early** | Fixed: Script uses `set +e` to continue past existing repos |

## � Success Checklist

Setup complete when:

- ✅ All 4 repositories cloned to `repos/`
- ✅ All prerequisites verified (Java, Maven, Python, Node, Yarn)
- ✅ Frontend dependencies installed (`node_modules/` exists)
- ✅ Java backend builds successfully
- ✅ Python virtual environment created (`.venv/`)
- ✅ All remotes use `github-nuoa` SSH host

## 🎯 Next Steps

1. **Activate Python**: `source .venv/bin/activate`
2. **Create feature branch**: `git checkout -b feature/your-feature`
3. **Start dev server**: `make dev-admin` or `make dev-console`
4. **Read repo docs**: Check `.github/instructions/agent.instruction.md` in each repo

---

**Version**: 1.0  
**Last Updated**: February 4, 2026

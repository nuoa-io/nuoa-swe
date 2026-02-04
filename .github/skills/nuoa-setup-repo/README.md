# NUOA Setup Repository - Quick Reference

Automated setup for NUOA monorepo development environment.

## 🚀 Quick Start

```bash
# Complete setup (from monorepo root)
bash .github/skills/nuoa-setup-repo/scripts/setup.sh

# Or use Makefile
make setup
```

## 📦 What Gets Set Up

1. **Repositories** (cloned to `repos/`):
   - nuoa-io-backend-tenant-services (Java)
   - nuoa-io-backend-shared-services (Python)
   - nuoa-io-admin-ui (React)
   - admin-console-nuoa-react (React)

2. **Prerequisites**:
   - Java 11, Maven
   - Python 3.13, venv
   - Node.js, npm, Yarn
   - AWS CLI

3. **Dependencies**:
   - Maven packages for Java
   - Python packages in .venv
   - node_modules for frontends

## 📖 Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Main orchestrator - runs everything |
| `clone-repos.sh` | Clone all 4 repositories |
| `check-prereqs.sh` | Verify development tools |
| `install-deps.sh` | Install project dependencies |

## 🎯 Common Commands

```bash
# Full setup
make setup

# Check prerequisites only
bash .github/skills/nuoa-setup-repo/scripts/check-prereqs.sh

# Clone repos only
bash .github/skills/nuoa-setup-repo/scripts/clone-repos.sh

# Install deps only
bash .github/skills/nuoa-setup-repo/scripts/install-deps.sh

# Verify environment
make check-env
```

## 🔧 Verify Setup

```bash
# Activate Python environment
source .venv/bin/activate

# Check tools
java -version      # Should be 11.x
python --version   # Should be 3.13+
node --version     # Should be 18+
yarn --version     # Should be 1.22+

# Test dev servers
make dev-admin     # http://localhost:5173
make dev-console   # http://localhost:4200
```

## 📚 Documentation

See [SKILL.md](SKILL.md) for complete documentation.

---

**Need help?** Run: `bash .github/skills/nuoa-setup-repo/scripts/setup.sh --help`

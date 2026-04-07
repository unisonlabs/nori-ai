#!/bin/bash
set -e

# ════════════════════════════════════════════════
# Nori Engineer Setup — Mac mini remote dev environment
# Interactive, idempotent — safe to re-run at any time
# ════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ZSHRC="$HOME/.zshrc"
ENV_FILE="$HOME/.env"

section() {
  echo ""
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}════════════════════════════════════════${NC}"
  echo ""
}

ok() { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "  $prompt [Y/n] " response
  [[ -z "$response" || "$response" =~ ^[Yy] ]]
}

mask_value() {
  local val="$1"
  if [ ${#val} -gt 8 ]; then
    echo "${val:0:8}..."
  else
    echo "***"
  fi
}

# Check if a line pattern exists in .zshrc
zshrc_has() {
  grep -qF "$1" "$ZSHRC" 2>/dev/null
}

# Add a line to .zshrc if not already present
zshrc_add() {
  if ! zshrc_has "$1"; then
    echo "$1" >> "$ZSHRC"
    ok "Added to ~/.zshrc: $1"
  fi
}

# Prompt for an env var, check if already set in .env or .zshrc
prompt_env_var() {
  local var_name="$1"
  local description="$2"

  # Check .env first, then .zshrc
  local current_val=""
  if [ -f "$ENV_FILE" ]; then
    current_val=$(grep "^export ${var_name}=" "$ENV_FILE" 2>/dev/null | head -1 | sed "s/^export ${var_name}=//; s/^[\"']//; s/[\"']$//")
  fi
  if [ -z "$current_val" ]; then
    current_val=$(grep "^export ${var_name}=" "$ZSHRC" 2>/dev/null | head -1 | sed "s/^export ${var_name}=//; s/^[\"']//; s/[\"']$//")
  fi

  if [ -n "$current_val" ]; then
    echo "  $var_name is set: $(mask_value "$current_val")"
    if confirm "Is this correct?"; then
      return
    fi
  fi

  if [ -n "$description" ]; then
    echo "  $description"
  fi
  read -r -p "  Enter $var_name: " new_val
  if [ -n "$new_val" ]; then
    # Write to .env file
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    if grep -q "^export ${var_name}=" "$ENV_FILE" 2>/dev/null; then
      sed -i '' "s|^export ${var_name}=.*|export ${var_name}=\"${new_val}\"|" "$ENV_FILE"
    else
      echo "export ${var_name}=\"${new_val}\"" >> "$ENV_FILE"
    fi
    ok "$var_name saved to ~/.env"
  else
    warn "Skipped $var_name"
  fi
}

# Ensure .env is sourced from .zshrc
setup_env_sourcing() {
  if ! zshrc_has "source ~/.env"; then
    echo '' >> "$ZSHRC"
    echo '# Load environment secrets' >> "$ZSHRC"
    echo '[ -f ~/.env ] && source ~/.env' >> "$ZSHRC"
    ok "Added .env sourcing to ~/.zshrc"
  fi
}

INSTALLED=()
SKIPPED=()

echo ""
echo "Nori Engineer Setup"
echo "This script sets up your Mac mini remote dev environment."
echo "It's interactive and idempotent — safe to re-run."
echo ""

# ──────────────────────────────────────────────
# 1. Homebrew
# ──────────────────────────────────────────────

section "1/18 — Homebrew"

if command -v brew &>/dev/null; then
  ok "Homebrew is already installed"
  SKIPPED+=("Homebrew")
else
  echo "  Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  if [ -f /opt/homebrew/bin/brew ]; then
    zshrc_add 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
  INSTALLED+=("Homebrew")
fi

# ──────────────────────────────────────────────
# 2. pyenv + Python 3.11.11
# ──────────────────────────────────────────────

section "2/18 — pyenv + Python 3.11.11"

if command -v pyenv &>/dev/null; then
  ok "pyenv is already installed"
  SKIPPED+=("pyenv")
else
  echo "  Installing pyenv..."
  brew install pyenv
  ok "pyenv installed"
  INSTALLED+=("pyenv")
fi

# Add pyenv init to .zshrc
zshrc_add 'export PYENV_ROOT="$HOME/.pyenv"'
zshrc_add '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"'
zshrc_add 'eval "$(pyenv init -)"'

# Source pyenv for current session
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

if pyenv versions 2>/dev/null | grep -q "3.11.11"; then
  ok "Python 3.11.11 is already installed"
else
  echo "  Installing Python 3.11.11 via pyenv..."
  pyenv install 3.11.11
  ok "Python 3.11.11 installed"
fi

pyenv global 3.11.11
ok "Python 3.11.11 set as global"

# ──────────────────────────────────────────────
# 3. Poetry
# ──────────────────────────────────────────────

section "3/18 — Poetry"

if command -v poetry &>/dev/null; then
  ok "Poetry is already installed"
  SKIPPED+=("Poetry")
else
  echo "  Installing Poetry..."
  curl -sSL https://install.python-poetry.org | python3 -
  zshrc_add 'export PATH="$HOME/.local/bin:$PATH"'
  export PATH="$HOME/.local/bin:$PATH"
  ok "Poetry installed"
  INSTALLED+=("Poetry")
fi

# ──────────────────────────────────────────────
# 4. PostgreSQL 17
# ──────────────────────────────────────────────

section "4/18 — PostgreSQL 17"

if brew list postgresql@17 &>/dev/null; then
  ok "PostgreSQL 17 is already installed"
  SKIPPED+=("PostgreSQL 17")
else
  echo "  Installing PostgreSQL 17..."
  brew install postgresql@17
  ok "PostgreSQL 17 installed"
  INSTALLED+=("PostgreSQL 17")
fi

zshrc_add 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"'
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# Start as brew service
if brew services list 2>/dev/null | grep -q "postgresql@17.*started"; then
  ok "PostgreSQL 17 is already running"
else
  brew services start postgresql@17
  ok "PostgreSQL 17 started"
fi

# pgvector
if brew list pgvector &>/dev/null; then
  ok "pgvector is already installed"
else
  echo "  Installing pgvector..."
  brew install pgvector
  ok "pgvector installed"
fi

# ──────────────────────────────────────────────
# 5. Redis
# ──────────────────────────────────────────────

section "5/18 — Redis"

if command -v redis-server &>/dev/null; then
  ok "Redis is already installed"
  SKIPPED+=("Redis")
else
  echo "  Installing Redis..."
  brew install redis
  ok "Redis installed"
  INSTALLED+=("Redis")
fi

if brew services list 2>/dev/null | grep -q "redis.*started"; then
  ok "Redis is already running"
else
  brew services start redis
  ok "Redis started"
fi

# ──────────────────────────────────────────────
# 6. Node.js
# ──────────────────────────────────────────────

section "6/18 — Node.js"

if command -v node &>/dev/null; then
  ok "Node.js is already installed ($(node --version))"
  SKIPPED+=("Node.js")
else
  echo "  Installing Node.js..."
  brew install node
  ok "Node.js installed"
  INSTALLED+=("Node.js")
fi

# ──────────────────────────────────────────────
# 7. Claude Code
# ──────────────────────────────────────────────

section "7/18 — Claude Code"

if command -v claude &>/dev/null; then
  ok "Claude Code is already installed"
  SKIPPED+=("Claude Code")
else
  echo "  Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
  ok "Claude Code installed"
  INSTALLED+=("Claude Code")
fi

# ──────────────────────────────────────────────
# 8. Pi (coding agent)
# ──────────────────────────────────────────────

section "8/18 — Pi (coding agent)"

if command -v pi &>/dev/null || npm list -g @mariozechner/pi-coding-agent &>/dev/null 2>&1; then
  ok "Pi is already installed"
  SKIPPED+=("Pi")
else
  echo "  Installing Pi coding agent..."
  npm install -g @mariozechner/pi-coding-agent
  ok "Pi installed"
  INSTALLED+=("Pi")
fi

# ──────────────────────────────────────────────
# 9. GitHub CLI
# ──────────────────────────────────────────────

section "9/18 — GitHub CLI"

if command -v gh &>/dev/null; then
  ok "GitHub CLI is already installed"
  SKIPPED+=("GitHub CLI")
else
  echo "  Installing GitHub CLI..."
  brew install gh
  ok "GitHub CLI installed"
  INSTALLED+=("GitHub CLI")
fi

if gh auth status &>/dev/null; then
  ok "GitHub CLI is authenticated"
else
  warn "GitHub CLI is not authenticated"
  if confirm "Run 'gh auth login' now?"; then
    gh auth login
  fi
fi

# ──────────────────────────────────────────────
# 10. Sentry CLI
# ──────────────────────────────────────────────

section "10/18 — Sentry CLI"

if command -v sentry-cli &>/dev/null; then
  ok "Sentry CLI is already installed"
  SKIPPED+=("Sentry CLI")
else
  echo "  Installing Sentry CLI..."
  brew install getsentry/tools/sentry-cli
  ok "Sentry CLI installed"
  INSTALLED+=("Sentry CLI")
fi

prompt_env_var "SENTRY_AUTH_TOKEN" "Get your auth token from https://sentry.io/settings/auth-tokens/"

# ──────────────────────────────────────────────
# 11. Tailscale
# ──────────────────────────────────────────────

section "11/18 — Tailscale"

if [ -d "/Applications/Tailscale.app" ]; then
  ok "Tailscale is installed"
  SKIPPED+=("Tailscale")
else
  warn "Tailscale is not installed"
  echo "  Download from https://tailscale.com/download/mac"
  echo "  Install the app, then re-run this script."
  INSTALLED+=("Tailscale (manual)")
fi

zshrc_add 'export PATH="/Applications/Tailscale.app/Contents/MacOS:$PATH"'

# ──────────────────────────────────────────────
# 12. SSH key for GitHub
# ──────────────────────────────────────────────

section "12/18 — SSH Key"

if [ -f "$HOME/.ssh/id_ed25519" ]; then
  ok "SSH key exists"
  echo ""
  echo "  Public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  if ! confirm "Is this key already added to GitHub?"; then
    echo "  Add it at: https://github.com/settings/keys"
  fi
else
  echo "  Generating SSH key..."
  read -r -p "  Enter your email for the SSH key: " ssh_email
  ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
  echo ""
  echo "  Your public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
  echo ""
  echo "  Add it at: https://github.com/settings/keys"
  read -r -p "  Press Enter when done..."
  INSTALLED+=("SSH key")
fi

# ──────────────────────────────────────────────
# 13. Oh My Zsh (optional)
# ──────────────────────────────────────────────

section "13/18 — Oh My Zsh (optional)"

if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "Oh My Zsh is already installed"
  SKIPPED+=("Oh My Zsh")
else
  if confirm "Install Oh My Zsh + plugins?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # zsh-autosuggestions
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
      git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
      git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    ok "Oh My Zsh + plugins installed"
    echo "  Add 'zsh-autosuggestions' and 'zsh-syntax-highlighting' to plugins=() in ~/.zshrc"
    INSTALLED+=("Oh My Zsh")
  else
    SKIPPED+=("Oh My Zsh")
  fi
fi

# ──────────────────────────────────────────────
# 14. Clone repos
# ──────────────────────────────────────────────

section "14/18 — Clone Repos"

read -r -p "  GitHub org [unisonlabs]: " gh_org
gh_org="${gh_org:-unisonlabs}"

mkdir -p "$HOME/nori"

for repo in nori-backend nori-mobile nori-ai; do
  if [ -d "$HOME/nori/$repo" ]; then
    ok "$repo already cloned"
  else
    echo "  Cloning $repo..."
    git clone "git@github.com:${gh_org}/${repo}.git" "$HOME/nori/$repo"
    ok "$repo cloned"
    INSTALLED+=("$repo")
  fi
done

# ──────────────────────────────────────────────
# 15. Run make setup in each repo
# ──────────────────────────────────────────────

section "15/18 — Repo Setup"

if [ -f "$HOME/nori/nori-backend/Makefile" ]; then
  if confirm "Run 'make setup' in nori-backend?"; then
    (cd "$HOME/nori/nori-backend" && make setup)
    ok "nori-backend setup complete"
  fi
fi

if [ -f "$HOME/nori/nori-mobile/package.json" ]; then
  if confirm "Run 'npm install' in nori-mobile?"; then
    (cd "$HOME/nori/nori-mobile" && npm install)
    ok "nori-mobile setup complete"
  fi
fi

# ──────────────────────────────────────────────
# 16. API Keys
# ──────────────────────────────────────────────

section "16/18 — API Keys"

setup_env_sourcing

prompt_env_var "ANTHROPIC_API_KEY" "Get your key from https://console.anthropic.com/settings/keys"
prompt_env_var "DATABASE_URL" "Local dev database connection string (read-write)"
prompt_env_var "DATABASE_URL_PROD_READONLY" "Production database connection string (read-only)"

# ──────────────────────────────────────────────
# 17. Mac mini settings
# ──────────────────────────────────────────────

section "17/18 — Mac Mini Settings"

if confirm "Disable sleep? (recommended for remote dev)"; then
  sudo systemsetup -setcomputersleep Never 2>/dev/null || warn "Could not disable sleep (may need Full Disk Access)"
  ok "Sleep disabled"
fi

if confirm "Restart on power failure? (recommended)"; then
  sudo systemsetup -setrestartpowerfailure on 2>/dev/null || warn "Could not set restart on power failure"
  ok "Restart on power failure enabled"
fi

# ──────────────────────────────────────────────
# 18. MCP servers and hooks
# ──────────────────────────────────────────────

section "18/18 — MCP Servers & Hooks"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if confirm "Install MCP servers and notification hooks?"; then
  (cd "$REPO_ROOT" && make mcps hooks)
  ok "MCPs and hooks installed"
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""

if [ ${#INSTALLED[@]} -gt 0 ]; then
  echo "  Installed:"
  for item in "${INSTALLED[@]}"; do
    echo -e "    ${GREEN}✓${NC} $item"
  done
  echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
  echo "  Already present:"
  for item in "${SKIPPED[@]}"; do
    echo -e "    ${BLUE}–${NC} $item"
  done
  echo ""
fi

echo "  Next steps:"
echo "    1. Restart your terminal (or run: source ~/.zshrc)"
echo "    2. Open Claude Code and run /plugin to enable:"
echo "       pr-review-toolkit, code-simplifier, figma, github, swift-lsp, codex"
echo "    3. Run 'make check' to verify your setup"
echo ""

#!/bin/bash
# ════════════════════════════════════════════════
# Shared agent setup functions
# Source this from agent-specific setup.sh scripts
# ════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_ok() { echo -e "  ${GREEN}✓${NC} $1"; }
_warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
_fail() { echo -e "  ${RED}✗${NC} $1"; }
_section() {
  echo ""
  echo -e "${BLUE}── $1${NC}"
  echo ""
}

_confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "  $prompt [Y/n] " response
  [[ -z "$response" || "$response" =~ ^[Yy] ]]
}

_mask_value() {
  local val="$1"
  if [ ${#val} -gt 8 ]; then
    echo "${val:0:8}..."
  else
    echo "***"
  fi
}

# Run a command as the agent user
_as_agent() {
  local username="$1"
  shift
  sudo su - "$username" -c "$*"
}

# ──────────────────────────────────────────────
# setup_agent_user <username> <realname> <suggested_uid>
# Creates a macOS user for the agent if it doesn't exist.
# Finds next available UID if suggested one conflicts.
# ──────────────────────────────────────────────
setup_agent_user() {
  local username="$1"
  local realname="$2"
  local suggested_uid="$3"

  _section "Creating macOS user: $username"

  # Check if user already exists
  if dscl . -read "/Users/$username" &>/dev/null; then
    _ok "User $username already exists"
    return
  fi

  # Find available UID
  local uid="$suggested_uid"
  while dscl . -list /Users UniqueID 2>/dev/null | awk '{print $2}' | grep -q "^${uid}$"; do
    _warn "UID $uid is taken, trying next..."
    uid=$((uid + 1))
  done

  echo "  Creating user $username (UID: $uid)..."

  # Prompt for password
  read -r -s -p "  Enter password for $username: " agent_password
  echo ""

  sudo dscl . -create "/Users/$username"
  sudo dscl . -create "/Users/$username" UserShell /bin/zsh
  sudo dscl . -create "/Users/$username" RealName "$realname"
  sudo dscl . -create "/Users/$username" UniqueID "$uid"
  sudo dscl . -create "/Users/$username" PrimaryGroupID 20
  sudo dscl . -create "/Users/$username" NFSHomeDirectory "/Users/$username"
  sudo dscl . -passwd "/Users/$username" "$agent_password"
  sudo createhomedir -c -u "$username"

  _ok "User $username created (UID: $uid)"
}

# ──────────────────────────────────────────────
# setup_agent_homebrew <username>
# Installs Homebrew for the agent user.
# ──────────────────────────────────────────────
setup_agent_homebrew() {
  local username="$1"

  _section "Installing Homebrew for $username"

  if _as_agent "$username" "command -v brew &>/dev/null"; then
    _ok "Homebrew is already installed for $username"
    return
  fi

  echo "  Installing Homebrew as $username..."
  _as_agent "$username" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  # Add brew shellenv to agent's .zshrc
  _as_agent "$username" 'echo '\''eval "$(/opt/homebrew/bin/brew shellenv)"'\'' >> ~/.zshrc'
  _ok "Homebrew installed for $username"
}

# ──────────────────────────────────────────────
# setup_agent_node <username>
# Installs Node.js via brew for the agent user.
# ──────────────────────────────────────────────
setup_agent_node() {
  local username="$1"

  _section "Installing Node.js for $username"

  if _as_agent "$username" "command -v node &>/dev/null"; then
    _ok "Node.js is already installed for $username"
    return
  fi

  _as_agent "$username" "brew install node"
  _ok "Node.js installed for $username"
}

# ──────────────────────────────────────────────
# setup_agent_clis <username>
# Installs CLI tools (sentry-cli, gh) for the agent user.
# ──────────────────────────────────────────────
setup_agent_clis() {
  local username="$1"

  _section "Installing CLI tools for $username"

  if _as_agent "$username" "command -v gh &>/dev/null"; then
    _ok "GitHub CLI is already installed"
  else
    _as_agent "$username" "brew install gh"
    _ok "GitHub CLI installed"
  fi

  if _as_agent "$username" "command -v sentry-cli &>/dev/null"; then
    _ok "Sentry CLI is already installed"
  else
    _as_agent "$username" "brew install getsentry/tools/sentry-cli"
    _ok "Sentry CLI installed"
  fi
}

# ──────────────────────────────────────────────
# setup_agent_mom <username>
# Installs Mom (Slack-connected Pi wrapper) via npm.
# ──────────────────────────────────────────────
setup_agent_mom() {
  local username="$1"

  _section "Installing Mom for $username"

  if _as_agent "$username" "npm list -g @mariozechner/pi-mom &>/dev/null 2>&1"; then
    _ok "Mom is already installed for $username"
    return
  fi

  _as_agent "$username" "npm install -g @mariozechner/pi-mom"
  _ok "Mom installed for $username"
}

# ──────────────────────────────────────────────
# setup_agent_workspace <username> <data_dir>
# Creates workspace directories and copies AGENTS.md.
# ──────────────────────────────────────────────
setup_agent_workspace() {
  local username="$1"
  local data_dir="$2"

  _section "Setting up workspace for $username"

  _as_agent "$username" "mkdir -p '$data_dir' '$data_dir/logs' '$data_dir/tools'"
  _ok "Workspace directories created at $data_dir"

  # Copy AGENTS.md from the calling script's directory
  local agent_dir
  agent_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  if [ -f "$agent_dir/AGENTS.md" ]; then
    sudo cp "$agent_dir/AGENTS.md" "$data_dir/AGENTS.md"
    sudo chown "$username:staff" "$data_dir/AGENTS.md"
    _ok "AGENTS.md copied to $data_dir"
  else
    _warn "No AGENTS.md found in $agent_dir"
  fi
}

# ──────────────────────────────────────────────
# setup_agent_repos <username> <org> <repo1> [repo2] ...
# Clones repos for the agent user (readonly access).
# ──────────────────────────────────────────────
setup_agent_repos() {
  local username="$1"
  local org="$2"
  shift 2

  _section "Cloning repos for $username"

  _as_agent "$username" "mkdir -p ~/nori"

  for repo in "$@"; do
    if _as_agent "$username" "[ -d ~/nori/$repo ]"; then
      _ok "$repo already cloned"
    else
      echo "  Cloning $repo..."
      _as_agent "$username" "gh repo clone ${org}/${repo} ~/nori/$repo"
      _ok "$repo cloned"
    fi
  done
}

# ──────────────────────────────────────────────
# setup_agent_credentials <username> <space_separated_key_list>
# Prompts for credentials and writes to ~/.env with chmod 600.
# ──────────────────────────────────────────────
setup_agent_credentials() {
  local username="$1"
  local keys="$2"
  local agent_home="/Users/$username"
  local env_file="$agent_home/.env"

  _section "Configuring credentials for $username"

  echo "  Credentials are stored in $env_file (chmod 600)"
  echo ""

  # Ensure .env exists with correct permissions
  sudo touch "$env_file"
  sudo chown "$username:staff" "$env_file"
  sudo chmod 600 "$env_file"

  # Ensure .env is sourced from .zshrc
  if ! _as_agent "$username" "grep -qF 'source ~/.env' ~/.zshrc 2>/dev/null"; then
    _as_agent "$username" 'echo "" >> ~/.zshrc && echo "# Load environment secrets" >> ~/.zshrc && echo "[ -f ~/.env ] && source ~/.env" >> ~/.zshrc'
    _ok "Added .env sourcing to $username's .zshrc"
  fi

  for key in $keys; do
    # Check if already set
    local current_val
    current_val=$(sudo grep "^export ${key}=" "$env_file" 2>/dev/null | head -1 | sed "s/^export ${key}=//; s/^[\"']//; s/[\"']$//" || echo "")

    if [ -n "$current_val" ]; then
      echo "  $key is set: $(_mask_value "$current_val")"
      if _confirm "Is this correct?"; then
        continue
      fi
    fi

    read -r -p "  Enter $key: " new_val
    if [ -n "$new_val" ]; then
      if sudo grep -q "^export ${key}=" "$env_file" 2>/dev/null; then
        sudo sed -i '' "s|^export ${key}=.*|export ${key}=\"${new_val}\"|" "$env_file"
      else
        echo "export ${key}=\"${new_val}\"" | sudo tee -a "$env_file" >/dev/null
      fi
      _ok "$key saved"
    else
      _warn "Skipped $key"
    fi
  done
}

# ──────────────────────────────────────────────
# setup_agent_process <username> <command>
# Installs a launchd plist for the agent process.
# Uses a LaunchDaemon (/Library/LaunchDaemons/) so the agent starts on
# boot without requiring a GUI login — appropriate for headless Mac minis.
# Auto-restarts on crash via KeepAlive.
# ──────────────────────────────────────────────
setup_agent_process() {
  local username="$1"
  local command="$2"
  local agent_home="/Users/$username"
  local plist_label="com.nori.${username}"
  local plist_path="/Library/LaunchDaemons/${plist_label}.plist"
  local log_dir="$agent_home/nori/nori-agent/data/logs"

  _section "Setting up launchd process for $username"

  _as_agent "$username" "mkdir -p '$log_dir'"

  # Create a wrapper script that sources .env before running
  local wrapper_path="$agent_home/nori/nori-agent/run.sh"
  sudo tee "$wrapper_path" >/dev/null <<EOF
#!/bin/bash
source "\$HOME/.env" 2>/dev/null
exec $command
EOF
  sudo chmod +x "$wrapper_path"
  sudo chown "$username:staff" "$wrapper_path"

  # Write LaunchDaemon plist (runs as the agent user, starts on boot)
  sudo tee "$plist_path" >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${plist_label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${wrapper_path}</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${agent_home}/nori</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${agent_home}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>UserName</key>
  <string>${username}</string>
  <key>KeepAlive</key>
  <true/>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${log_dir}/mom.log</string>
  <key>StandardErrorPath</key>
  <string>${log_dir}/mom.log</string>
</dict>
</plist>
EOF

  sudo chown root:wheel "$plist_path"
  sudo chmod 644 "$plist_path"

  _ok "LaunchDaemon plist created at $plist_path"
  _ok "Wrapper script created at $wrapper_path (sources ~/.env)"

  # Load the plist
  if _confirm "Load and start the agent now?"; then
    sudo launchctl bootstrap system "$plist_path" 2>/dev/null || \
      sudo launchctl load "$plist_path" 2>/dev/null || \
      _warn "Could not load plist — try: sudo launchctl load $plist_path"
    _ok "Agent process started"
  fi

  echo ""
  echo "  Useful commands:"
  echo "    sudo launchctl list | grep $username"
  echo "    tail -f $log_dir/mom.log"
  echo "    sudo launchctl stop $plist_label"
  echo "    sudo launchctl start $plist_label"
}

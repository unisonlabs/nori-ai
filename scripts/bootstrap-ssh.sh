#!/bin/bash
# ════════════════════════════════════════════════
# Bootstrap SSH key for GitHub
# Run this BEFORE setup-engineer.sh on a new Mac mini user account.
# ════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "SSH Key Bootstrap for GitHub"
echo ""

if [ -f "$HOME/.ssh/id_ed25519" ]; then
  echo -e "  ${GREEN}✓${NC} SSH key already exists"
  echo ""
  echo "  Public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
else
  read -r -p "  Enter your email for the SSH key: " ssh_email
  ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
  echo ""
  echo -e "  ${GREEN}✓${NC} SSH key generated"
  echo ""
  echo "  Public key:"
  cat "$HOME/.ssh/id_ed25519.pub"
fi

echo ""
echo "  Next steps:"
echo "    1. Copy the public key above"
echo "    2. Add it at: https://github.com/settings/keys"
echo "    3. Then clone and run setup:"
echo ""
echo "       git clone git@github.com:unisonlabs/nori-ai.git ~/nori/nori-ai"
echo "       cd ~/nori/nori-ai"
echo "       ./scripts/setup-engineer.sh"
echo ""

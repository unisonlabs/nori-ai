#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/scripts/setup-agent.sh"

echo ""
echo "════════════════════════════════════════"
echo "  Setting up nori-bug-agent"
echo "════════════════════════════════════════"
echo ""

setup_agent_user "nori-bug-agent" "Nori Bug Agent" "503"
setup_agent_homebrew "nori-bug-agent"
setup_agent_node "nori-bug-agent"
setup_agent_clis "nori-bug-agent"
setup_agent_mom "nori-bug-agent"
setup_agent_workspace "nori-bug-agent" "/Users/nori-bug-agent/nori/nori-agent/data"
setup_agent_credentials "nori-bug-agent" \
  "ANTHROPIC_API_KEY \
   MOM_SLACK_APP_TOKEN \
   MOM_SLACK_BOT_TOKEN \
   GITHUB_TOKEN \
   SENTRY_AUTH_TOKEN \
   DATABASE_URL \
   BETTERSTACK_API_KEY \
   LANGSMITH_API_KEY \
   HELPSCOUT_APP_ID \
   HELPSCOUT_APP_SECRET"
setup_agent_repos "nori-bug-agent" "unisonlabs" "nori-backend" "nori-mobile"
setup_agent_process "nori-bug-agent" \
  "mom --data /Users/nori-bug-agent/nori/nori-agent/data"

echo ""
echo "✓ nori-bug-agent setup complete!"
echo ""
echo "Next steps:"
echo "  1. Invite @nori-bug-bot to #nori-errors in Slack"
echo "  2. Check agent is running: launchctl list | grep nori-bug-agent"
echo "  3. Check logs: tail -f /Users/nori-bug-agent/nori/nori-agent/data/logs/mom.log"
echo ""

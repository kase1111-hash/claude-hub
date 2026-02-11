#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — First-time setup for Claude Hub
# Usage: ./scripts/bootstrap.sh
#
# Run this once after cloning claude-hub to:
# 1. Verify dependencies
# 2. Authenticate with GitHub
# 3. Run initial discovery
# 4. Map all repo purposes
# 5. Generate first self-update report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"

echo "╔══════════════════════════════════════╗"
echo "║       Claude Hub — Bootstrap         ║"
echo "║   GitHub = Filesystem, Claude = CPU  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# 1. Check dependencies
echo "--- Checking dependencies ---"
MISSING=()

command -v gh >/dev/null 2>&1 || MISSING+=("gh (GitHub CLI)")
command -v jq >/dev/null 2>&1 || MISSING+=("jq")
command -v claude >/dev/null 2>&1 || MISSING+=("claude (Claude Code CLI)")
command -v git >/dev/null 2>&1 || MISSING+=("git")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "⚠ Missing dependencies:"
  for dep in "${MISSING[@]}"; do
    echo "  - $dep"
  done
  echo ""
  echo "Install missing dependencies and re-run bootstrap."
  
  # Provide install hints
  for dep in "${MISSING[@]}"; do
    case "$dep" in
      *gh*) echo "  gh:     https://cli.github.com/" ;;
      *jq*) echo "  jq:     sudo apt install jq / brew install jq" ;;
      *claude*) echo "  claude: npm install -g @anthropic-ai/claude-code" ;;
    esac
  done
  exit 1
fi
echo "✓ All dependencies found."

# 2. Check GitHub auth
echo ""
echo "--- Checking GitHub authentication ---"
if gh auth status >/dev/null 2>&1; then
  OWNER=$(gh api user --jq '.login')
  echo "✓ Authenticated as: $OWNER"
else
  echo "⚠ Not authenticated with GitHub CLI."
  echo "  Run: gh auth login"
  exit 1
fi

# 3. Make scripts executable
echo ""
echo "--- Setting permissions ---"
chmod +x "$SCRIPT_DIR"/*.sh
echo "✓ Scripts are executable."

# 4. Run discovery
echo ""
echo "--- Phase 1: Discovery ---"
"$SCRIPT_DIR/discover.sh" --owner "$OWNER"

# 5. Map purposes
echo ""
echo "--- Phase 2: Purpose Mapping ---"
echo "This will use Claude Code to analyze each repo."
echo "Depending on repo count, this may take several minutes."
read -p "Proceed? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  "$SCRIPT_DIR/map-purposes.sh"
else
  echo "Skipped. Run ./scripts/map-purposes.sh when ready."
fi

# 6. Self-update
echo ""
echo "--- Phase 3: Self-Update Check ---"
"$SCRIPT_DIR/self-update.sh"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Bootstrap Complete! ✓          ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Review manifests/repo-map.json"
echo "  2. Run: ./scripts/maintain.sh --all --dry-run"
echo "  3. Add .claude/purpose.md to key repos (template in templates/)"
echo "  4. Set up a cron or Claude Code alias for regular maintenance"
echo ""
echo "Quick aliases for your shell:"
echo "  alias chub-scan='cd $(pwd) && ./scripts/discover.sh && ./scripts/map-purposes.sh'"
echo "  alias chub-maintain='cd $(pwd) && ./scripts/maintain.sh --all'"
echo "  alias chub-status='cd $(pwd) && ./scripts/self-update.sh'"

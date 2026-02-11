#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh — First-time setup for Claude Hub
# Usage: ./scripts/bootstrap.sh [--yes] [--owner OWNER]
#
# Run this once after cloning claude-hub to:
# 1. Verify dependencies
# 2. Authenticate with GitHub
# 3. Initialize directory structure
# 4. Run initial discovery
# 5. Map all repo purposes
# 6. Generate first self-update report
#
# Options:
#   --yes       Skip interactive prompts (auto-confirm)
#   --owner     Specify GitHub owner (skips auto-detection)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"

AUTO_YES=false
OWNER=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --yes|-y) AUTO_YES=true; shift ;;
    --owner) OWNER="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

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
  echo "Missing dependencies:"
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
echo "All dependencies found."

# 2. Check GitHub auth
echo ""
echo "--- Checking GitHub authentication ---"
GH_AUTHENTICATED=false
if gh auth status >/dev/null 2>&1; then
  GH_AUTHENTICATED=true
  if [[ -z "$OWNER" ]]; then
    OWNER=$(gh api user --jq '.login')
  fi
  echo "Authenticated as: $OWNER"
else
  echo "Not authenticated with GitHub CLI."
  if [[ -n "$OWNER" ]]; then
    echo "Using provided owner: $OWNER"
    echo "Note: GitHub API calls will fail until you run: gh auth login"
  else
    echo "  Run: gh auth login"
    echo "  Or re-run with: ./scripts/bootstrap.sh --owner YOUR_GITHUB_USERNAME"
    exit 1
  fi
fi

# 3. Initialize directory structure
echo ""
echo "--- Initializing directory structure ---"
mkdir -p "$HUB_ROOT/manifests/reports"
mkdir -p "$HUB_ROOT/templates"

# Initialize manifest if it doesn't exist or is empty
if [[ ! -s "$HUB_ROOT/manifests/repo-map.json" ]]; then
  echo '{"owner": null, "last_full_scan": null, "repos": []}' | jq . > "$HUB_ROOT/manifests/repo-map.json"
  echo "Initialized empty manifest."
fi

# Set owner in manifest
jq --arg o "$OWNER" '.owner = $o' "$HUB_ROOT/manifests/repo-map.json" > "$HUB_ROOT/manifests/repo-map.json.tmp" \
  && mv "$HUB_ROOT/manifests/repo-map.json.tmp" "$HUB_ROOT/manifests/repo-map.json"
echo "Directory structure ready."

# 4. Make scripts executable
echo ""
echo "--- Setting permissions ---"
chmod +x "$SCRIPT_DIR"/*.sh
echo "Scripts are executable."

# 5. Run discovery (requires gh auth)
echo ""
echo "--- Phase 1: Discovery ---"
if [[ "$GH_AUTHENTICATED" == true ]]; then
  "$SCRIPT_DIR/discover.sh" --owner "$OWNER"
else
  echo "Skipped: GitHub authentication required."
  echo "  Run: gh auth login && ./scripts/discover.sh"
fi

# 6. Map purposes (requires gh auth + Claude)
echo ""
echo "--- Phase 2: Purpose Mapping ---"
if [[ "$GH_AUTHENTICATED" == true ]]; then
  echo "This will use Claude Code to analyze each repo."
  echo "Depending on repo count, this may take several minutes."
  if [[ "$AUTO_YES" == true ]]; then
    REPLY="y"
  else
    read -p "Proceed? (y/n) " -n 1 -r
    echo ""
  fi
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/map-purposes.sh"
  else
    echo "Skipped. Run ./scripts/map-purposes.sh when ready."
  fi
else
  echo "Skipped: GitHub authentication required."
  echo "  Run: gh auth login && ./scripts/map-purposes.sh"
fi

# 7. Self-update
echo ""
echo "--- Phase 3: Self-Update Check ---"
if [[ "$GH_AUTHENTICATED" == true ]]; then
  "$SCRIPT_DIR/self-update.sh"
else
  echo "Skipped: GitHub authentication required."
  echo "  Run: gh auth login && ./scripts/self-update.sh"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Bootstrap Complete!            ║"
echo "╚══════════════════════════════════════╝"
echo ""
if [[ "$GH_AUTHENTICATED" == true ]]; then
  echo "Next steps:"
  echo "  1. Review manifests/repo-map.json"
  echo "  2. Run: ./scripts/maintain.sh --all --dry-run"
  echo "  3. Add .claude/purpose.md to key repos (template in templates/)"
  echo "  4. Set up a cron or Claude Code alias for regular maintenance"
else
  echo "Local setup complete. To finish GitHub integration:"
  echo "  1. Run: gh auth login"
  echo "  2. Re-run: ./scripts/bootstrap.sh"
fi
echo ""
echo "Quick aliases for your shell:"
echo "  alias chub-scan='cd $HUB_ROOT && ./scripts/discover.sh && ./scripts/map-purposes.sh'"
echo "  alias chub-maintain='cd $HUB_ROOT && ./scripts/maintain.sh --all'"
echo "  alias chub-status='cd $HUB_ROOT && ./scripts/self-update.sh'"

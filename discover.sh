#!/usr/bin/env bash
set -euo pipefail

# discover.sh — Scan GitHub account and build/update the repo manifest
# Usage: ./scripts/discover.sh [--owner OWNER]
#
# Requires: gh CLI (authenticated), jq
# This script gathers raw data. Claude Code analyzes purpose afterward.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$HUB_ROOT/manifests/repo-map.json"
INVENTORY="$HUB_ROOT/manifests/.inventory-raw.json"

# Parse args
OWNER=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --owner) OWNER="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Auto-detect owner from gh CLI if not specified
if [[ -z "$OWNER" ]]; then
  OWNER=$(gh api user --jq '.login')
  echo "Auto-detected owner: $OWNER"
fi

echo "=== Claude Hub: Discovery Scan ==="
echo "Owner: $OWNER"
echo "Manifest: $MANIFEST"
echo ""

# Fetch all repos (handles pagination automatically)
echo "Fetching repository list..."
gh api --paginate "/users/$OWNER/repos?per_page=100&sort=updated" \
  --jq '[.[] | {
    name: .name,
    full_name: .full_name,
    description: .description,
    language: (.language // "unknown"),
    default_branch: .default_branch,
    updated_at: .updated_at,
    created_at: .created_at,
    archived: .archived,
    fork: .fork,
    private: .private,
    html_url: .html_url,
    topics: .topics,
    size: .size,
    has_issues: .has_issues,
    open_issues_count: .open_issues_count
  }]' > "$INVENTORY"

REPO_COUNT=$(jq length "$INVENTORY")
echo "Found $REPO_COUNT repositories."

# Check which repos have CLAUDE.md or .claude/ directory
echo ""
echo "Scanning for Claude configuration files..."
ENRICHED="$HUB_ROOT/manifests/.inventory-enriched.json"
cp "$INVENTORY" "$ENRICHED"

for repo in $(jq -r '.[].name' "$INVENTORY"); do
  branch=$(jq -r --arg r "$repo" '.[] | select(.name==$r) | .default_branch' "$INVENTORY")
  
  # Check for CLAUDE.md
  has_claude_md=false
  if gh api "repos/$OWNER/$repo/contents/CLAUDE.md" --jq '.name' 2>/dev/null | grep -q "CLAUDE.md"; then
    has_claude_md=true
  fi

  # Check for .claude/ directory
  has_claude_dir=false
  if gh api "repos/$OWNER/$repo/contents/.claude" --jq '.[0].name' 2>/dev/null | grep -q .; then
    has_claude_dir=true
  fi

  # Check for test configuration
  test_config="none"
  for f in "pyproject.toml" "package.json" "Cargo.toml" "Makefile" "test" ".bats"; do
    if gh api "repos/$OWNER/$repo/contents/$f" --jq '.name' 2>/dev/null | grep -q .; then
      test_config="$f"
      break
    fi
  done

  # Update enriched inventory
  jq --arg r "$repo" \
     --argjson cm "$has_claude_md" \
     --argjson cd "$has_claude_dir" \
     --arg tc "$test_config" \
     '(.[] | select(.name==$r)) += {
        claude_md_exists: $cm,
        claude_dir_exists: $cd,
        test_config_detected: $tc
      }' "$ENRICHED" > "${ENRICHED}.tmp" && mv "${ENRICHED}.tmp" "$ENRICHED"

  echo "  ✓ $repo (claude.md=$has_claude_md, tests=$test_config)"
done

echo ""
echo "=== Discovery Complete ==="
echo "Raw inventory: $INVENTORY"
echo "Enriched inventory: $ENRICHED"
echo ""
echo "Next step: Run Claude Code to analyze purposes and update manifest:"
echo "  claude 'Read $ENRICHED and analyze each repo. Update $MANIFEST with purpose and category for each.'"

#!/usr/bin/env bash
set -euo pipefail

# self-update.sh — Claude Hub maintains its own consistency
# Usage: ./scripts/self-update.sh
#
# This is the reflexive maintenance loop. Claude Hub checks:
# 1. Are there repos on GitHub not in the manifest?
# 2. Are there manifest entries for deleted repos?
# 3. Are templates still consistent with what repos actually use?
# 4. Is CLAUDE.md itself still accurate?
#
# Requires: gh CLI, jq

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$HUB_ROOT/manifests/repo-map.json"

OWNER=$(jq -r '.owner' "$MANIFEST")
if [[ -z "$OWNER" || "$OWNER" == "null" ]]; then
  OWNER=$(gh api user --jq '.login')
fi

echo "=== Claude Hub: Self-Update ==="
echo "Owner: $OWNER"
echo ""

# 1. Check for orphaned repos (on GitHub but not in manifest)
echo "--- Checking for unmapped repos ---"
GITHUB_REPOS=$(gh api --paginate "/users/$OWNER/repos?per_page=100" --jq '.[].name' | sort)
MANIFEST_REPOS=$(jq -r '.repos[].name' "$MANIFEST" | sort)

ORPHANS=$(comm -23 <(echo "$GITHUB_REPOS") <(echo "$MANIFEST_REPOS"))
if [[ -n "$ORPHANS" ]]; then
  echo "⚠ Found unmapped repos:"
  echo "$ORPHANS" | while read -r repo; do
    echo "  - $repo"
  done
  echo ""
  echo "Run ./scripts/discover.sh && ./scripts/map-purposes.sh to map them."
else
  echo "✓ All GitHub repos are in the manifest."
fi

# 2. Check for ghost entries (in manifest but not on GitHub)
echo ""
echo "--- Checking for ghost manifest entries ---"
GHOSTS=$(comm -13 <(echo "$GITHUB_REPOS") <(echo "$MANIFEST_REPOS"))
if [[ -n "$GHOSTS" ]]; then
  echo "⚠ Found ghost entries (repo deleted from GitHub):"
  echo "$GHOSTS" | while read -r repo; do
    echo "  - $repo (removing from manifest)"
    jq --arg r "$repo" '.repos = [.repos[] | select(.name != $r)]' "$MANIFEST" > "${MANIFEST}.tmp"
    mv "${MANIFEST}.tmp" "$MANIFEST"
  done
else
  echo "✓ No ghost entries found."
fi

# 3. Check maintenance staleness
echo ""
echo "--- Checking maintenance freshness ---"
STALE_DAYS=30
STALE_CUTOFF=$(date -u -d "$STALE_DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
  date -u -v-${STALE_DAYS}d +"%Y-%m-%dT%H:%M:%SZ")

jq -r --arg cutoff "$STALE_CUTOFF" '
  .repos[] | 
  select(.maintenance_priority != "archive") |
  select(.last_maintained == null or .last_maintained < $cutoff) |
  "\(.maintenance_priority)\t\(.name)\t\(.last_maintained // "never")"
' "$MANIFEST" | sort | while IFS=$'\t' read -r priority name last; do
  echo "  ⏰ $name (priority=$priority, last=$last)"
done

# 4. Template drift detection
echo ""
echo "--- Checking template usage ---"
TEMPLATES_DIR="$HUB_ROOT/templates"
if [[ -d "$TEMPLATES_DIR" ]]; then
  for template in "$TEMPLATES_DIR"/*.md; do
    [[ -f "$template" ]] || continue
    tname=$(basename "$template")
    echo "  Template: $tname"
    # Count how many repos reference this template
    # This would require scanning repos — flag for Claude Code to handle
  done
else
  echo "  No templates directory found."
fi

# 5. Manifest statistics
echo ""
echo "--- Manifest Summary ---"
echo "Total repos: $(jq '.repos | length' "$MANIFEST")"
echo "By category:"
jq -r '.repos | group_by(.category) | .[] | "  \(.[0].category): \(length)"' "$MANIFEST"
echo "By priority:"
jq -r '.repos | group_by(.maintenance_priority) | .[] | "  \(.[0].maintenance_priority): \(length)"' "$MANIFEST"

echo ""
echo "=== Self-Update Complete ==="

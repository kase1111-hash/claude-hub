#!/usr/bin/env bash
set -euo pipefail

# maintain.sh — Orchestrate Claude Code maintenance across repos
# Usage:
#   ./scripts/maintain.sh <repo-name>        # maintain one repo
#   ./scripts/maintain.sh --all              # maintain all repos
#   ./scripts/maintain.sh --all --dry-run    # report only
#   ./scripts/maintain.sh --category agent-os # maintain by category
#   ./scripts/maintain.sh --priority high    # maintain by priority
#
# Requires: gh CLI, jq, claude CLI (Claude Code)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$HUB_ROOT/manifests/repo-map.json"
REPORTS_DIR="$HUB_ROOT/manifests/reports"
TEMPLATES_DIR="$HUB_ROOT/templates"

DRY_RUN=false
TARGET=""
FILTER_KEY=""
FILTER_VAL=""

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --all) TARGET="__ALL__"; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --category) FILTER_KEY="category"; FILTER_VAL="$2"; TARGET="__FILTER__"; shift 2 ;;
    --priority) FILTER_KEY="maintenance_priority"; FILTER_VAL="$2"; TARGET="__FILTER__"; shift 2 ;;
    --ecosystem) FILTER_KEY="ecosystem"; FILTER_VAL="$2"; TARGET="__FILTER__"; shift 2 ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Usage: maintain.sh <repo-name> | --all | --category <cat> | --priority <pri>"
  exit 1
fi

mkdir -p "$REPORTS_DIR"

# Build repo list
if [[ "$TARGET" == "__ALL__" ]]; then
  REPOS=$(jq -r '.repos[].name' "$MANIFEST")
elif [[ "$TARGET" == "__FILTER__" ]]; then
  REPOS=$(jq -r --arg k "$FILTER_KEY" --arg v "$FILTER_VAL" \
    '.repos[] | select(.[$k]==$v) | .name' "$MANIFEST")
else
  REPOS="$TARGET"
fi

OWNER=$(jq -r '.owner' "$MANIFEST")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_FILE="$REPORTS_DIR/maintenance-$(date +%Y%m%d-%H%M%S).md"

echo "# Maintenance Report — $TIMESTAMP" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

for repo in $REPOS; do
  echo "=== Maintaining: $repo ==="
  
  # Get repo info from manifest
  REPO_INFO=$(jq --arg r "$repo" '.repos[] | select(.name==$r)' "$MANIFEST")
  PRIORITY=$(echo "$REPO_INFO" | jq -r '.maintenance_priority // "medium"')
  TEST_CMD=$(echo "$REPO_INFO" | jq -r '.test_command // "null"')
  LANGUAGE=$(echo "$REPO_INFO" | jq -r '.language // "unknown"')
  
  if [[ "$PRIORITY" == "archive" ]]; then
    echo "  Skipping archived repo: $repo"
    echo "## $repo — SKIPPED (archived)" >> "$REPORT_FILE"
    continue
  fi

  echo "## $repo" >> "$REPORT_FILE"
  echo "- Priority: $PRIORITY" >> "$REPORT_FILE"
  echo "- Language: $LANGUAGE" >> "$REPORT_FILE"
  echo "- Test command: $TEST_CMD" >> "$REPORT_FILE"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [DRY RUN] Would maintain $repo (priority=$PRIORITY, lang=$LANGUAGE)"
    echo "- Status: DRY RUN" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    continue
  fi

  # Clone/update repo into workspace
  WORKSPACE="/tmp/claude-hub-workspace/$repo"
  if [[ -d "$WORKSPACE" ]]; then
    cd "$WORKSPACE" && git pull --quiet
  else
    mkdir -p "$(dirname "$WORKSPACE")"
    gh repo clone "$OWNER/$repo" "$WORKSPACE" -- --quiet
  fi

  # Build the maintenance prompt for Claude Code
  PROMPT="You are maintaining the repo '$repo' as part of the claude-hub system.

Repo metadata from manifest:
$(echo "$REPO_INFO" | jq .)

Your maintenance checklist:
1. READ: Check CLAUDE.md, README.md, .claude/purpose.md for context
2. ASSESS: Do tests pass ($TEST_CMD)? Are deps outdated? Is README accurate?
3. FIX: Apply safe fixes — typos, dep bumps, broken tests, missing docs
4. TEST: Run tests with the environment-native runner (no Docker/VMs)
5. REPORT: Summarize what you found and what you changed

Rules:
- Never push to main — create a branch and PR if changes needed
- Use environment-native testing only
- Preserve existing CLAUDE.md content
- If no test runner exists and this isn't pure prose, add one

Hub templates available at: $TEMPLATES_DIR/
Report your findings as structured output."

  # Run Claude Code on the repo
  cd "$WORKSPACE"
  CLAUDE_OUTPUT=$(claude --print "$PROMPT" 2>&1) || true
  
  echo "$CLAUDE_OUTPUT" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Update last_maintained in manifest
  jq --arg r "$repo" --arg t "$TIMESTAMP" \
    '(.repos[] | select(.name==$r)).last_maintained = $t' \
    "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"

  echo "  ✓ Maintenance complete for $repo"
  echo ""
done

echo ""
echo "=== Maintenance Complete ==="
echo "Report: $REPORT_FILE"

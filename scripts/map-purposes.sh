#!/usr/bin/env bash
set -euo pipefail

# map-purposes.sh — Use Claude Code to analyze each repo and populate the manifest
# Usage: ./scripts/map-purposes.sh [--force]
#
# Reads .inventory-enriched.json from discover.sh
# For each repo without a manifest entry (or --force for all),
# clones it, has Claude analyze it, and updates repo-map.json
#
# Requires: gh CLI, jq, claude CLI

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFEST="$HUB_ROOT/manifests/repo-map.json"
ENRICHED="$HUB_ROOT/manifests/.inventory-enriched.json"

FORCE=false
[[ "${1:-}" == "--force" ]] && FORCE=true

if [[ ! -f "$ENRICHED" ]]; then
  echo "No enriched inventory found. Run ./scripts/discover.sh first."
  exit 1
fi

OWNER=$(gh api user --jq '.login')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update owner in manifest
jq --arg o "$OWNER" '.owner = $o' "$MANIFEST" > "${MANIFEST}.tmp" && mv "${MANIFEST}.tmp" "$MANIFEST"

TOTAL=$(jq length "$ENRICHED")
echo "=== Claude Hub: Purpose Mapping ==="
echo "Repos to analyze: $TOTAL"
echo ""

for i in $(seq 0 $((TOTAL - 1))); do
  REPO_NAME=$(jq -r ".[$i].name" "$ENRICHED")
  
  # Skip if already in manifest (unless --force)
  if [[ "$FORCE" != true ]]; then
    EXISTS=$(jq --arg r "$REPO_NAME" '.repos[] | select(.name==$r) | .name' "$MANIFEST" 2>/dev/null || echo "")
    if [[ -n "$EXISTS" ]]; then
      echo "  ⏭ $REPO_NAME (already mapped)"
      continue
    fi
  fi

  echo "  🔍 Analyzing: $REPO_NAME..."

  RAW_INFO=$(jq ".[$i]" "$ENRICHED")
  LANGUAGE=$(echo "$RAW_INFO" | jq -r '.language // "unknown"')
  DESCRIPTION=$(echo "$RAW_INFO" | jq -r '.description // "none"')
  TOPICS=$(echo "$RAW_INFO" | jq -r '.topics // [] | join(", ")')
  ARCHIVED=$(echo "$RAW_INFO" | jq -r '.archived')

  # Clone shallow copy for analysis
  WORKSPACE="/tmp/claude-hub-analysis/$REPO_NAME"
  rm -rf "$WORKSPACE"
  gh repo clone "$OWNER/$REPO_NAME" "$WORKSPACE" -- --depth 1 --quiet 2>/dev/null || {
    echo "    ⚠ Failed to clone $REPO_NAME, skipping"
    continue
  }

  # Gather file tree (top 2 levels)
  FILE_TREE=$(find "$WORKSPACE" -maxdepth 2 -not -path '*/.git/*' -not -name '.git' | \
    sed "s|$WORKSPACE/||" | sort)

  # Read key files if they exist
  README=""
  [[ -f "$WORKSPACE/README.md" ]] && README=$(head -100 "$WORKSPACE/README.md")
  CLAUDE_MD=""
  [[ -f "$WORKSPACE/CLAUDE.md" ]] && CLAUDE_MD=$(head -50 "$WORKSPACE/CLAUDE.md")
  PURPOSE_MD=""
  [[ -f "$WORKSPACE/.claude/purpose.md" ]] && PURPOSE_MD=$(cat "$WORKSPACE/.claude/purpose.md")

  # Build analysis prompt
  ANALYSIS_PROMPT="Analyze this GitHub repository and return ONLY valid JSON (no markdown fencing, no explanation).

Repository: $REPO_NAME
Description: $DESCRIPTION
Language: $LANGUAGE
Topics: $TOPICS
Archived: $ARCHIVED

File tree (top 2 levels):
$FILE_TREE

README (first 100 lines):
$README

CLAUDE.md (if exists):
$CLAUDE_MD

.claude/purpose.md (if exists):
$PURPOSE_MD

Return this exact JSON structure:
{
  \"purpose\": \"One clear sentence describing what this repo does\",
  \"category\": \"one of: ecosystem, tool, library, config, experiment, archive\",
  \"ecosystem\": \"one of: agent-os, natlangchain, construction, personal, standalone\",
  \"test_command\": \"the native test command or null if none detected\",
  \"maintenance_priority\": \"one of: high, medium, low, archive\",
  \"dependencies\": [\"list of other repos in this account it depends on\"],
  \"notes\": \"Any important context for future maintenance\"
}

Rules for classification:
- ecosystem repos: part of Agent-OS or NatLangChain ecosystems
- tool: standalone utility or CLI
- library: reusable module imported by others
- config: configuration, dotfiles, templates (like claude-hub itself)
- experiment: prototype, POC, or exploration
- archive: unmaintained, completed, or abandoned
- high priority: actively developed, core infrastructure, or has dependents
- low priority: stable, rarely changes, or experimental
- archive priority: no longer maintained"

  # Run Claude Code for analysis
  RESULT=$(cd "$WORKSPACE" && claude --print "$ANALYSIS_PROMPT" 2>/dev/null) || {
    echo "    ⚠ Claude analysis failed for $REPO_NAME, adding stub entry"
    RESULT='{
      "purpose": "Analysis pending — Claude could not analyze this repo",
      "category": "experiment",
      "ecosystem": "standalone",
      "test_command": null,
      "maintenance_priority": "low",
      "dependencies": [],
      "notes": "Needs manual review"
    }'
  }

  # Clean up any markdown fencing Claude might add
  CLEAN_RESULT=$(echo "$RESULT" | sed 's/^```json//;s/^```//' | tr -d '\n' | \
    grep -o '{.*}' | head -1)

  # Validate JSON
  if ! echo "$CLEAN_RESULT" | jq . >/dev/null 2>&1; then
    echo "    ⚠ Invalid JSON from Claude for $REPO_NAME, adding stub"
    CLEAN_RESULT='{"purpose":"Analysis produced invalid JSON","category":"experiment","ecosystem":"standalone","test_command":null,"maintenance_priority":"low","dependencies":[],"notes":"Needs re-analysis"}'
  fi

  # Build full manifest entry
  ENTRY=$(echo "$CLEAN_RESULT" | jq \
    --arg name "$REPO_NAME" \
    --arg lang "$LANGUAGE" \
    --argjson cm "$(echo "$RAW_INFO" | jq '.claude_md_exists // false')" \
    --arg ts "$TIMESTAMP" \
    '. + {
      name: $name,
      language: $lang,
      claude_md_exists: $cm,
      last_maintained: null,
      last_scanned: $ts
    }')

  # Upsert into manifest
  if [[ "$FORCE" == true ]]; then
    # Remove existing entry first
    jq --arg r "$REPO_NAME" '.repos = [.repos[] | select(.name != $r)]' "$MANIFEST" > "${MANIFEST}.tmp"
    mv "${MANIFEST}.tmp" "$MANIFEST"
  fi

  jq --argjson entry "$ENTRY" '.repos += [$entry]' "$MANIFEST" > "${MANIFEST}.tmp"
  mv "${MANIFEST}.tmp" "$MANIFEST"

  PURPOSE=$(echo "$CLEAN_RESULT" | jq -r '.purpose')
  CATEGORY=$(echo "$CLEAN_RESULT" | jq -r '.category')
  echo "    ✓ $CATEGORY: $PURPOSE"

  # Cleanup
  rm -rf "$WORKSPACE"
done

# Update scan timestamp
jq --arg t "$TIMESTAMP" '.last_full_scan = $t' "$MANIFEST" > "${MANIFEST}.tmp"
mv "${MANIFEST}.tmp" "$MANIFEST"

MAPPED=$(jq '.repos | length' "$MANIFEST")
echo ""
echo "=== Purpose Mapping Complete ==="
echo "Total repos mapped: $MAPPED"
echo "Manifest: $MANIFEST"

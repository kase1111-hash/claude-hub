#!/usr/bin/env bats

# Tests for claude-hub scripts
# Run with: bats test/ or make test

setup() {
  HUB_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPTS="$HUB_ROOT/scripts"
  MANIFEST="$HUB_ROOT/manifests/repo-map.json"
}

# --- Script existence and permissions ---

@test "all scripts exist and are executable" {
  for script in bootstrap.sh discover.sh maintain.sh map-purposes.sh self-update.sh; do
    [ -f "$SCRIPTS/$script" ]
    [ -x "$SCRIPTS/$script" ]
  done
}

# --- Argument parsing ---

@test "bootstrap.sh rejects unknown arguments" {
  run "$SCRIPTS/bootstrap.sh" --invalid-flag
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown arg"* ]]
}

@test "discover.sh rejects unknown arguments" {
  run "$SCRIPTS/discover.sh" --invalid-flag
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown arg"* ]]
}

@test "maintain.sh shows usage with no arguments" {
  run "$SCRIPTS/maintain.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

# --- Manifest validation ---

@test "manifest file exists" {
  [ -f "$MANIFEST" ]
}

@test "manifest is valid JSON" {
  run jq . "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "manifest has required top-level keys" {
  run jq -e '.owner and (.repos | type == "array")' "$MANIFEST"
  [ "$status" -eq 0 ]
}

# --- Directory structure ---

@test "required directories exist" {
  [ -d "$HUB_ROOT/manifests" ]
  [ -d "$HUB_ROOT/manifests/reports" ]
  [ -d "$HUB_ROOT/scripts" ]
  [ -d "$HUB_ROOT/templates" ]
}

@test "templates exist" {
  [ -f "$HUB_ROOT/templates/purpose.md" ]
  [ -f "$HUB_ROOT/templates/python-base.md" ]
  [ -f "$HUB_ROOT/templates/node-base.md" ]
}

@test "Makefile exists" {
  [ -f "$HUB_ROOT/Makefile" ]
}

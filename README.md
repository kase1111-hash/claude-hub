# Claude Hub

Claude Hub maintains all your GitHub repos from one place. It scans your account, analyzes each repo, and runs Claude Code to assess, fix, test, and PR changes — including on itself.

## Quick Start

```bash
git clone https://github.com/YOUR_USER/claude-hub.git
cd claude-hub
make bootstrap
```

This will: check dependencies, scan your GitHub repos, analyze each with Claude, and report status.

## Requirements

- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated via `gh auth login`
- [jq](https://stedolan.github.io/jq/) — JSON processing
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — for repo analysis and maintenance
- Git

## Usage

```bash
make discover       # Scan GitHub for all repos
make map            # Analyze repos with Claude, populate manifest
make maintain REPO=my-repo   # Maintain a specific repo
make maintain-all   # Maintain everything
make maintain-dry   # Dry-run (report only, no changes)
make status         # Check for drift and staleness
make test           # Run tests (requires bats)
make lint           # Run shellcheck on scripts
```

Or use the scripts directly:

```bash
./scripts/discover.sh              # Scan GitHub
./scripts/map-purposes.sh          # Analyze with Claude
./scripts/maintain.sh my-repo      # Maintain one repo
./scripts/maintain.sh --all        # Maintain all
./scripts/maintain.sh --all --dry-run
./scripts/self-update.sh           # Check consistency
```

## How It Works

```
claude-hub/
├── manifests/repo-map.json   ← Registry of all repos + metadata
├── scripts/                  ← Discovery, mapping, maintenance, self-check
├── templates/                ← Reusable .claude/purpose.md fragments
└── test/                     ← bats tests
```

1. **Discover** scans your GitHub account and builds an inventory
2. **Map** uses Claude to analyze each repo's purpose, category, and test setup
3. **Maintain** clones repos, runs Claude to assess/fix/test, opens PRs for changes
4. **Status** detects orphaned repos, ghost manifest entries, and stale maintenance

## Adding Claude Awareness to Your Repos

Copy the purpose template into any repo:

```bash
mkdir -p .claude
cp templates/purpose.md .claude/purpose.md
# Edit to describe the repo's purpose and maintenance rules
```

## Design Principles

1. **Test natively** — pytest for Python, npm test for Node, cargo test for Rust. No Docker.
2. **Never push to main** — all changes go through PRs.
3. **Self-maintaining** — the hub checks its own consistency.
4. **Human-in-the-loop** — flags sensitive changes for review, never auto-archives.

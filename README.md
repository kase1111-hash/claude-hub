# Claude Hub

**GitHub is the filesystem. Claude is the CPU.**

Claude Hub is a self-maintaining orchestration layer that treats your entire GitHub account as a unified filesystem. One repo (this one) holds the instruction set. Every other repo is a file on the disk. Claude Code reads, maintains, tests, and documents them all — including itself.

## Quick Start

```bash
git clone https://github.com/YOUR_USER/claude-hub.git
cd claude-hub
./scripts/bootstrap.sh
```

Bootstrap will: verify dependencies → scan your GitHub → analyze every repo's purpose → build the manifest.

## Architecture

```
claude-hub (this repo)          ← Instruction memory
├── CLAUDE.md                   ← CPU instruction set
├── manifests/
│   └── repo-map.json           ← Filesystem allocation table  
├── templates/                  ← Shared libraries (.claude/purpose.md fragments)
├── scripts/
│   ├── bootstrap.sh            ← First-time setup
│   ├── discover.sh             ← Scan GitHub, build inventory
│   ├── map-purposes.sh         ← Claude analyzes each repo
│   ├── maintain.sh             ← Run maintenance on repos
│   └── self-update.sh          ← Hub maintains itself
└── hooks/                      ← Pre/post maintenance hooks
```

## Usage

```bash
# Discover new repos
./scripts/discover.sh

# Map purposes (uses Claude Code)
./scripts/map-purposes.sh

# Maintain a specific repo
./scripts/maintain.sh my-repo-name

# Maintain all high-priority repos
./scripts/maintain.sh --priority high

# Maintain everything (dry run first)
./scripts/maintain.sh --all --dry-run
./scripts/maintain.sh --all

# Self-update (check for drift)
./scripts/self-update.sh
```

## Adding Claude Awareness to Your Repos

Copy `templates/purpose-template.md` to `.claude/purpose.md` in any repo:

```bash
mkdir -p .claude
cp /path/to/claude-hub/templates/purpose-template.md .claude/purpose.md
# Edit to describe this repo's purpose and maintenance rules
```

## Design Principles

1. **Environment-native testing** — pytest for Python, npm test for Node, cargo test for Rust. No Docker, no VMs, no cross-platform matrices.
2. **Never push to main** — all changes go through PRs.
3. **Self-maintaining** — the hub updates its own manifest and templates.
4. **Constitutional constraints** — never delete repos, always preserve existing CLAUDE.md content, flag don't auto-archive.

## Dependencies

- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated
- [jq](https://stedolan.github.io/jq/) — JSON processing
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — the CPU
- Git

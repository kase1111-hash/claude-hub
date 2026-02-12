# Claude Hub

**GitHub is the filesystem. Claude is the CPU.**

Claude Hub is a self-maintaining orchestration layer that treats your entire GitHub account as a unified filesystem. One repo (this one) holds the instruction set. Every other repo is a file on the disk. Claude Code reads, maintains, tests, and documents them all — including itself.

## Quick Start

```bash
git clone https://github.com/YOUR_USER/claude-hub.git
cd claude-hub
./scripts/bootstrap.sh
```

Bootstrap will:
1. Verify dependencies (`gh`, `jq`, `claude`, `git`)
2. Authenticate with GitHub
3. Initialize directory structure (`manifests/`, `templates/`)
4. Run discovery — scan your GitHub repos
5. Run purpose mapping — Claude analyzes each repo
6. Run self-update — check consistency

Use `--yes` to skip interactive prompts or `--owner USERNAME` to specify the GitHub owner.

## Architecture

```
claude-hub (this repo)          ← Instruction memory
├── CLAUDE.md                   ← CPU instruction set
├── manifests/
│   ├── repo-map.json           ← Filesystem allocation table
│   ├── reports/                ← Maintenance reports (generated)
│   ├── .inventory-raw.json     ← Raw GitHub scan (generated)
│   └── .inventory-enriched.json← Enriched scan data (generated)
├── templates/                  ← Shared libraries (.claude/purpose.md fragments)
│   ├── purpose.md              ← Purpose file template for repos
│   ├── python-base.md          ← Python project conventions
│   ├── node-base.md            ← Node/TS project conventions
│   ├── agent-os-module.md      ← Agent-OS ecosystem conventions
│   └── natlangchain-module.md  ← NatLangChain ecosystem conventions
└── scripts/
    ├── bootstrap.sh            ← First-time setup
    ├── discover.sh             ← Scan GitHub, build inventory
    ├── map-purposes.sh         ← Claude analyzes each repo
    ├── maintain.sh             ← Run maintenance on repos
    └── self-update.sh          ← Hub maintains itself
```

## Usage

### Discovery — scan GitHub for repos

```bash
./scripts/discover.sh                  # auto-detects owner from gh CLI
./scripts/discover.sh --owner USER     # specify owner explicitly
```

Produces `.inventory-raw.json` and `.inventory-enriched.json` in `manifests/`. Each repo is checked for `CLAUDE.md`, `.claude/` directory, and test configuration files.

### Purpose Mapping — Claude analyzes each repo

```bash
./scripts/map-purposes.sh             # analyze unmapped repos only
./scripts/map-purposes.sh --force     # re-analyze all repos
```

Clones each repo, sends context to Claude Code for analysis, and populates `repo-map.json` with purpose, category, ecosystem, test command, priority, and dependencies.

### Maintenance — run Claude Code on repos

```bash
./scripts/maintain.sh my-repo-name          # maintain one repo
./scripts/maintain.sh --all                 # maintain all repos
./scripts/maintain.sh --all --dry-run       # report only, no changes
./scripts/maintain.sh --priority high       # filter by priority
./scripts/maintain.sh --category ecosystem  # filter by category
./scripts/maintain.sh --ecosystem agent-os  # filter by ecosystem
```

Generates a timestamped report in `manifests/reports/`.

### Self-Update — hub maintains itself

```bash
./scripts/self-update.sh
```

Checks for: unmapped repos on GitHub, ghost manifest entries (deleted repos), stale maintenance dates, template usage, and manifest statistics.

## Adding Claude Awareness to Your Repos

Copy `templates/purpose.md` to `.claude/purpose.md` in any repo:

```bash
mkdir -p .claude
cp /path/to/claude-hub/templates/purpose.md .claude/purpose.md
# Edit to describe this repo's purpose and maintenance rules
```

The purpose file supports template composition:
```markdown
<!-- @template: python-base, agent-os-module -->
```

Available templates: `python-base`, `node-base`, `agent-os-module`, `natlangchain-module`.

## Design Principles

1. **Environment-native testing** — pytest for Python, npm test for Node, cargo test for Rust. No Docker, no VMs, no cross-platform matrices.
2. **Never push to main** — all changes go through PRs.
3. **Self-maintaining** — the hub updates its own manifest and templates.
4. **Constitutional constraints** — never delete repos, always preserve existing CLAUDE.md content, flag don't auto-archive.

## Dependencies

- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated via `gh auth login`
- [jq](https://jqlang.github.io/jq/) — JSON processing
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — the CPU (`npm install -g @anthropic-ai/claude-code`)
- Git

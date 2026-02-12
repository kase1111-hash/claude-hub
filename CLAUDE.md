# CLAUDE.md — Claude Hub

## What This Is

Claude Hub is the central repo for maintaining all GitHub repos in this account.
This file tells Claude how to operate. The scripts do the work. The manifest tracks state.

## Directory Layout

```
claude-hub/
├── CLAUDE.md                    ← You're reading this
├── Makefile                     ← make bootstrap, make test, make lint
├── manifests/
│   ├── repo-map.json            ← Registry of all repos and metadata
│   └── reports/                 ← Maintenance reports
├── scripts/
│   ├── bootstrap.sh             ← First-time setup
│   ├── discover.sh              ← Scan GitHub, build inventory
│   ├── map-purposes.sh          ← Analyze repos with Claude, populate manifest
│   ├── maintain.sh              ← Run maintenance on repos
│   └── self-update.sh           ← Check for drift and staleness
├── templates/
│   ├── purpose.md               ← Template for .claude/purpose.md in other repos
│   ├── python-base.md           ← Python project conventions
│   └── node-base.md             ← Node/TS project conventions
└── test/
    └── scripts.bats             ← bats tests for scripts
```

## How It Works

1. **Discover** — `make discover` scans GitHub for all repos, checks for CLAUDE.md and test configs
2. **Map** — `make map` uses Claude to analyze each repo and populate the manifest
3. **Maintain** — `make maintain REPO=name` clones a repo, runs Claude to assess/fix/test/PR
4. **Self-check** — `make status` detects orphaned repos, ghost entries, and stale maintenance

Or run everything at once: `make bootstrap`

## Manifest Schema

Each entry in `manifests/repo-map.json`:
```json
{
  "name": "repo-name",
  "purpose": "One-line description",
  "category": "tool|library|config|experiment|archive",
  "language": "python|typescript|rust|shell|mixed|prose",
  "test_command": "pytest|npm test|cargo test|bats test/|null",
  "claude_md_exists": true,
  "last_maintained": "2026-02-11T00:00:00Z",
  "last_scanned": "2026-02-11T00:00:00Z",
  "maintenance_priority": "high|medium|low|archive",
  "dependencies": ["other-repo-name"],
  "notes": "Any context for future maintenance"
}
```

## Testing Rules

| Language  | Runner        | Command                        |
|-----------|--------------|--------------------------------|
| Python    | pytest       | `python -m pytest --tb=short`  |
| Node/TS   | vitest/jest  | `npm test`                     |
| Rust      | cargo test   | `cargo test`                   |
| Shell     | bats         | `bats test/`                   |
| Prose     | markdownlint | `markdownlint '**/*.md'`       |

If a repo has no test command and isn't pure prose, add one during maintenance.
No Docker. No VMs. Test in the language's own toolchain.

## Maintenance Checklist (per repo)

1. **Read** — CLAUDE.md, .claude/purpose.md, README
2. **Assess** — Tests pass? Deps outdated? README accurate? Stale branches?
3. **Fix** — Typos, dep bumps, broken tests, missing docs
4. **Test** — Run environment-native tests
5. **Report** — Update manifest with timestamp and notes
6. **PR** — If changes made, open a PR (never push to main)

## Rules

- Never delete repos without human approval
- Never push to main/master — always PR
- Preserve existing CLAUDE.md content — append, don't overwrite
- Flag abandoned repos for human review, don't auto-archive
- Keep testing native — no Docker, no CI dependencies

# CLAUDE.md — Claude Hub: The Central Nervous System

## Identity

You are the CPU. GitHub is your filesystem. This repo (`claude-hub`) is your instruction memory.
Every other repo in this GitHub account is a file on your disk. You read them, understand them,
maintain them, and keep them healthy — including yourself.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  claude-hub (this repo)          │
│  ┌───────────┐ ┌──────────┐ ┌────────────────┐  │
│  │ CLAUDE.md │ │ manifest │ │   templates/   │  │
│  │ (CPU ISA) │ │ (FAT/fs) │ │ (shared libs)  │  │
│  └───────────┘ └──────────┘ └────────────────┘  │
│  ┌───────────────┐ ┌──────────────────────────┐  │
│  │   scripts/    │ │        hooks/            │  │
│  │ (syscalls)    │ │  (interrupt handlers)    │  │
│  └───────────────┘ └──────────────────────────┘  │
└─────────────┬───────────────────────────────────┘
              │ GitHub API
    ┌─────────┼─────────┬──────────┬──────────┐
    ▼         ▼         ▼          ▼          ▼
 [repo-a]  [repo-b]  [repo-c]  [repo-d]  [repo-n]
  each has optional .claude/purpose.md
```

## Core Principles

1. **GitHub IS the filesystem** — never store state locally. Everything persists in repos.
2. **Manifest is truth** — `manifests/repo-map.json` is the filesystem allocation table.
3. **Environment-native testing** — test in the language's own toolchain. No Docker, no VMs,
   no cross-platform test matrices. Python tests with pytest. Node tests with vitest/jest.
   Rust tests with cargo test. Shell tests with bats. If it can't test natively, flag it.
4. **Self-maintaining** — you update your own manifest, your own templates, your own docs.
5. **Modular composition** — templates/ are shared libraries. Repos import what they need.

## Operational Workflow

### Discovery (scan the filesystem)
```bash
# Run from claude-hub root
./scripts/discover.sh
```
This calls the GitHub API, finds all repos, and produces a raw inventory.
Claude then analyzes each repo to determine its purpose and updates the manifest.

### Maintenance (scheduled or on-demand)
```bash
# Maintain a specific repo
./scripts/maintain.sh <repo-name>

# Maintain all repos
./scripts/maintain.sh --all

# Dry run (report only)
./scripts/maintain.sh --all --dry-run
```

### Self-Update (reflexive maintenance)
```bash
./scripts/maintain.sh claude-hub
```
When maintaining itself, Claude should:
- Check if any new repos lack manifest entries
- Update templates/ if patterns have evolved
- Reconcile the manifest with actual GitHub state

## Manifest Schema

Each repo entry in `manifests/repo-map.json`:
```json
{
  "name": "repo-name",
  "purpose": "One-line purpose statement",
  "category": "ecosystem|tool|library|config|experiment|archive",
  "ecosystem": "agent-os|natlangchain|construction|personal|standalone",
  "language": "python|typescript|rust|shell|mixed|prose",
  "test_command": "pytest|npm test|cargo test|bats test/|null",
  "claude_md_exists": true,
  "last_maintained": "2026-02-11T00:00:00Z",
  "maintenance_priority": "high|medium|low|archive",
  "dependencies": ["other-repo-name"],
  "notes": "Any context Claude needs for future maintenance"
}
```

## Template System

Templates in `templates/` are reusable CLAUDE.md fragments:
- `templates/python-base.md` — Standard Python project instructions
- `templates/node-base.md` — Standard Node/TS project instructions
- `templates/agent-os-module.md` — Agent-OS ecosystem conventions
- `templates/natlangchain-module.md` — NatLangChain ecosystem conventions

Repos reference templates via their `.claude/purpose.md`:
```markdown
<!-- @template: python-base, agent-os-module -->
# Purpose: Constitutional boundary enforcement daemon
...
```

## Environment-Native Testing Rules

| Language   | Test Runner    | Config File         | Claude Validates With       |
|-----------|---------------|--------------------|-----------------------------|
| Python    | pytest        | pyproject.toml     | `python -m pytest --tb=short` |
| Node/TS   | vitest/jest   | package.json       | `npm test`                    |
| Rust      | cargo test    | Cargo.toml         | `cargo test`                  |
| Shell     | bats          | test/*.bats        | `bats test/`                  |
| Prose/Doc | markdownlint  | .markdownlint.json | `markdownlint '**/*.md'`     |
| Mixed     | Makefile      | Makefile           | `make test`                   |

**Rule**: If a repo has no test command and isn't pure prose, Claude should ADD one
during maintenance using the appropriate native runner. Never introduce Docker or
cross-platform testing harnesses — test where the code lives.

## Maintenance Actions (what Claude does per repo)

1. **Read** — Pull latest, read CLAUDE.md / .claude/purpose.md / README
2. **Assess** — Check: tests pass? Deps outdated? README accurate? Stale branches?
3. **Fix** — Apply fixes within scope (typos, dep bumps, broken tests, missing docs)
4. **Test** — Run environment-native tests, verify green
5. **Report** — Update manifest entry with timestamp and notes
6. **PR** — If changes made, open a PR with clear description (never push to main)

## Constitutional Constraints

- Never delete repos without explicit human approval
- Never push directly to main/master — always PR
- Never introduce external CI dependencies (keep it Claude-native)
- Always preserve existing CLAUDE.md content — append, don't overwrite
- Flag repos that seem abandoned for human review rather than archiving autonomously

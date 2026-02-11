# .claude/purpose.md Template

<!-- 
  This file tells Claude Hub what this repo is and how to maintain it.
  Copy this to .claude/purpose.md in any repo and fill it in.
  Claude will read this during maintenance cycles.
-->

<!-- @template: python-base -->
<!-- Uncomment and adjust the template reference above. Options:
  python-base, node-base, agent-os-module, natlangchain-module
  Multiple: @template: python-base, agent-os-module
-->

## Purpose
<!-- One sentence: what does this repo do? -->

## Maintenance Rules
<!-- What should Claude do (and NOT do) when maintaining this repo? -->
- [ ] Run tests before any changes
- [ ] Never modify [specific files] without human review
- [ ] Check compatibility with [dependent repos]

## Test Command
<!-- How to run tests natively -->
```bash
# e.g., pytest, npm test, cargo test
```

## Sensitive Areas
<!-- Files or directories that need human review before changes -->
- config/ — contains deployment secrets references
- src/core/ — constitutional layer, needs human review

## Dependencies (sibling repos)
<!-- Other repos in this account that this one depends on -->
- repo-name-a (imports module X)
- repo-name-b (uses API Y)

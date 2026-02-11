# Template: agent-os-module

## Ecosystem: Agent-OS

This repo is part of the Agent-OS constitutional framework for AI governance.

## Integration Points
- Must respect constitutional layer boundaries
- Should export a clear API surface for other Agent-OS modules
- Must include boundary enforcement hooks if handling external input
- Should integrate with IntentLog for reasoning audit trails

## Constitutional Compliance
- All actions must be traceable to a constitutional permission
- Boundary violations must raise, never silently pass
- Human override capability must be preserved at every layer

## Cross-Module Dependencies
When maintaining this module, check if changes affect:
- boundary-daemon (security enforcement)
- IntentLog (reasoning version control)
- Other modules listed in this repo's manifest entry

## Testing Requirements
- Unit tests for core logic (environment-native)
- Integration tests for cross-module boundaries (if applicable)
- Constitutional compliance assertions in test suite

## Maintenance Notes
- Changes to API surfaces require checking all dependent modules
- Constitutional layer changes require human review — flag, don't auto-fix

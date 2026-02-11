# Template: natlangchain-module

## Ecosystem: NatLangChain

This repo is part of the NatLangChain prose-first blockchain protocol.

## Core Principle
NatLangChain uses natural language as the primary protocol layer.
Code is secondary — the prose specification IS the contract.

## Module Conventions
- Every module must have a prose specification in SPEC.md or README
- Code implements the prose spec, not the other way around
- Changes to prose spec = breaking changes (require version bump)
- Natural language interfaces preferred over API-only designs

## Testing
- Prose specs should have example scenarios that serve as acceptance tests
- Implementation tests verify behavior matches prose spec
- Environment-native runners only

## Cross-Module Dependencies
- Check NatLangChain protocol compatibility when updating
- Ensure prose interfaces remain human-readable
- Verify natural language parsing hasn't regressed

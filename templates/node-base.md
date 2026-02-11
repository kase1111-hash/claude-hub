# Template: node-base

## Language: Node.js / TypeScript

Standard conventions for Node/TypeScript projects maintained by Claude Hub.

## Project Structure
- Source code in `src/` or `lib/`
- Tests alongside source or in `test/` / `tests/` / `__tests__/`
- Configuration in `package.json`, `tsconfig.json`

## Testing
- Test runner: `npm test` (delegates to vitest, jest, or mocha via package.json)
- If no test script exists, add vitest as default
- Config file: `package.json` (scripts.test)

## Dependency Management
- Check `package.json` for outdated dependencies
- Use `npm outdated` to identify stale packages
- Flag major version bumps for human review
- Respect lockfile (`package-lock.json` or `yarn.lock`)

## Code Style
- Follow existing project conventions (eslint, prettier configs)
- TypeScript preferred for new code if project uses it
- Respect existing `tsconfig.json` strictness settings

## Maintenance Notes
- Run `npm test` to validate changes
- Run `npm audit` to check for security issues
- Ensure `package-lock.json` is committed if it exists

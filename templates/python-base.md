# Template: python-base

## Language: Python

Standard conventions for Python projects maintained by Claude Hub.

## Project Structure
- Source code in `src/` or top-level package directory
- Tests in `tests/` or `test/`
- Configuration in `pyproject.toml` (preferred) or `setup.py`

## Testing
- Test runner: `python -m pytest --tb=short`
- Config file: `pyproject.toml` (pytest section)
- If no test runner exists, add pytest with a minimal `pyproject.toml`

## Dependency Management
- Check `pyproject.toml` or `requirements.txt` for pinned versions
- Flag outdated dependencies but don't auto-bump major versions
- Prefer `pyproject.toml` over `requirements.txt` for new setups

## Code Style
- Follow existing project conventions
- If no formatter configured, prefer ruff or black
- Type hints encouraged but don't add retroactively unless requested

## Maintenance Notes
- Run `python -m pytest --tb=short` to validate changes
- Check for security advisories on dependencies
- Ensure `__init__.py` files exist where needed

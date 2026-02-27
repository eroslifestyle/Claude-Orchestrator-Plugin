# Python Patterns and Rules

> Python-specific standards. Supplements `rules/common/` rules.

---

## Style and Formatting

- Follow **PEP 8** as baseline
- Line length: **88 chars** (Black default) or 79 (strict PEP 8) - pick one per project, enforce with formatter
- Use **Black** for formatting, **isort** for import sorting, **ruff** for linting
- Imports order: stdlib > third-party > local, separated by blank lines
- Use absolute imports over relative imports (except within a package)

## Type Hints

- **Type hints mandatory** for all function signatures (params + return)
- Use `from __future__ import annotations` for modern syntax in Python 3.9+
- Complex types: use `TypeAlias`, `TypeVar`, `Protocol` from `typing`
- Return `None` explicitly in type hints: `def init_db() -> None:`
- Use `Optional[X]` or `X | None` (3.10+) - never leave it ambiguous
- Run **mypy** (strict mode) or **pyright** in CI

## Data Modeling

- Use **dataclasses** for simple data containers
- Use **Pydantic** for data with validation (API input/output, configs)
- Avoid raw dicts for structured data - define a model
- Use `__slots__` on performance-critical classes
- Prefer `NamedTuple` over regular tuples for multi-field returns

## File and Path Handling

- Use **pathlib.Path** over `os.path` for all path operations
- Context managers (`with`) for ALL file operations - never `f = open()` without `with`
- Specify encoding explicitly: `open(path, encoding="utf-8")`
- Use `tempfile` module for temporary files (auto-cleanup)

## Async Patterns

- Use **async/await** for I/O-bound operations (HTTP, DB, file I/O)
- Use `asyncio.gather()` for concurrent I/O operations
- Never mix sync and async without proper bridging (`asyncio.to_thread()`)
- Use `httpx` (async) over `requests` (sync) for new async projects
- Set timeouts on all async operations: `asyncio.wait_for(coro, timeout=30)`

## Error Handling

- Catch **specific exceptions**, never bare `except:` or `except Exception:`
- Use custom exception classes for domain errors (inherit from a base app exception)
- Use `raise ... from err` to preserve exception chains
- Log exceptions with `logger.exception()` (includes traceback automatically)
- Let unexpected exceptions propagate - don't catch what you can't handle

## Logging

- Use the **logging** module - never `print()` in production code
- Configure once at app entry point, use `getLogger(__name__)` in modules
- Log levels: DEBUG (dev detail), INFO (operations), WARNING (recoverable), ERROR (failures), CRITICAL (system down)
- Use structured logging (JSON) for production: `structlog` or `python-json-logger`
- Never log sensitive data (passwords, tokens, PII)

## Performance Patterns

- **Generators** over lists for large/unbounded sequences
- Use `functools.lru_cache` for expensive pure functions (with `maxsize`)
- List comprehensions over `map()`/`filter()` when readable
- `collections.defaultdict`, `Counter`, `deque` for common patterns
- Profile before optimizing: `cProfile`, `line_profiler`, `memory_profiler`
- Use `__slots__` for classes with many instances

## Strings

- **f-strings** over `.format()` or `%` formatting
- Use `textwrap.dedent()` for multi-line strings in code
- Raw strings `r"..."` for regex patterns
- `str.removeprefix()` / `str.removesuffix()` (3.9+) over slicing

## Environment and Dependencies

- **Virtual environments mandatory**: `venv`, `poetry`, `uv`, or `conda`
- Pin dependencies in production: use lockfiles (`poetry.lock`, `requirements.txt` with hashes)
- Separate dev dependencies from production dependencies
- Use `python-dotenv` or `pydantic-settings` for configuration
- Minimum Python version: 3.10+ for new projects (use `|` union types, match/case)

## Testing (Python-Specific)

- Use **pytest** (not unittest) as test framework
- Fixtures over setUp/tearDown for test setup
- Use `pytest.mark.parametrize` for data-driven tests
- Use `pytest-asyncio` for async test functions
- Use `freezegun` or `time-machine` for time-dependent tests
- Use `factory_boy` or `faker` for test data generation
- Coverage with `pytest-cov`: `pytest --cov=src --cov-report=term-missing`

## Project Structure

```
project/
  src/
    package_name/
      __init__.py
      main.py
      models/
      services/
      utils/
  tests/
    conftest.py
    test_models/
    test_services/
  pyproject.toml
  README.md
```

- Use `pyproject.toml` as the single config file (PEP 621)
- `src/` layout to prevent import confusion
- Mirror source structure in tests

# Testing Rules

> Every feature ships with tests. No exceptions.

---

## Test-First Mindset (Rules 1-4)

### Rule 1
Write tests **BEFORE or WITH** implementation (TDD preferred)

### Rule 2
If retrofitting tests: write them before refactoring, not after

### Rule 3
A feature without tests is not done

### Rule 4
Minimum **80% code coverage** for new code, 60% for legacy code being modified

## Test Structure (Rules 5-8)

### Rule 5
Each test tests **ONE thing** - one assertion per logical concept

### Rule 6
Follow **Arrange / Act / Assert** (AAA) pattern:
```
# Arrange - set up test data and dependencies
# Act     - call the function under test
# Assert  - verify the result
```

### Rule 7
Keep tests short: 10-20 lines max (excluding setup)

### Rule 8
No logic in tests (no if/else, no loops) - tests should be dead simple

## Naming (Rules 9-12)

### Rule 9
Test names must describe the **scenario and expected outcome**

### Rule 10
Format: `test_<what>_<condition>_<expected>` or `should <expected> when <condition>`

### Rule 11
Examples:
- `test_login_with_invalid_password_returns_401`
- `test_calculate_total_with_empty_cart_returns_zero`
- `should reject expired tokens`

### Rule 12
Bad names: `test1`, `test_login`, `test_it_works`

## Edge Cases (Rules 13-19)

### Rule 13
**Null/None/undefined** inputs - always test

### Rule 14
**Empty** collections, strings, objects - always test

### Rule 15
**Boundary values**: 0, -1, MAX_INT, empty string, single char - always test

### Rule 16
**Unicode**: emojis, RTL text, null bytes, very long strings - always test

### Rule 17
**Concurrent** access (if applicable) - always test

### Rule 18
**Large inputs**: performance doesn't degrade catastrophically - always test

### Rule 19
**Error paths**: network failure, timeout, invalid format, permission denied - always test

## Mocking and Dependencies (Rules 20-24)

### Rule 20
**Mock external dependencies**: APIs, databases, file system, time, randomness

### Rule 21
Never call real APIs in unit tests (use fixtures/stubs)

### Rule 22
Integration tests may use real services (in test environments only)

### Rule 23
Keep mocks minimal - mock the interface, not the implementation

### Rule 24
Verify mock interactions only when the interaction IS the behavior

## Test Independence (Rules 25-28)

### Rule 25
**Each test runs independently** - no shared mutable state between tests

### Rule 26
Tests can run in any order and still pass

### Rule 27
Use setup/teardown (beforeEach/afterEach) for common setup, not shared variables

### Rule 28
Clean up after yourself: delete temp files, reset singletons, restore mocks

## Test Types and When to Use (Rules 29-33)

### Rule 29
**Unit tests** - Single function/class, <10ms - Always

### Rule 30
**Integration tests** - Multiple components, <1s - API endpoints, DB queries

### Rule 31
**E2E tests** - Full user flow, <30s - Critical paths only

### Rule 32
**Snapshot tests** - UI output, <100ms - Components with stable output

### Rule 33
**Property-based tests** - Random inputs, <5s - Pure functions with invariants

## CI/CD Integration (Rules 34-38)

### Rule 34
Tests MUST pass before merge - no exceptions, no "skip this once"

### Rule 35
Flaky tests are bugs - fix or delete them, never retry-and-ignore

### Rule 36
Test suite should complete in under 5 minutes (parallelize if needed)

### Rule 37
Run linter + type checker + tests in CI pipeline

### Rule 38
Coverage report generated on every PR

## What NOT to Test (Rules 39-43)

### Rule 39
Framework/library internals (trust your dependencies)

### Rule 40
Private methods directly (test through public interface)

### Rule 41
Trivial getters/setters with no logic

### Rule 42
Configuration values (test behavior, not config)

### Rule 43
Third-party API response format (use contract tests instead)

## Anti-Patterns to Avoid (Rules 44-49)

### Rule 44
**Test interdependency**: test B passes only if test A runs first

### Rule 45
**Excessive mocking**: mocking everything = testing nothing

### Rule 46
**Testing implementation**: changing internal code breaks tests even though behavior is the same

### Rule 47
**Slow tests nobody runs**: if the suite takes 30min, developers skip it

### Rule 48
**Commented-out tests**: delete them, don't comment them out

### Rule 49
**Assert-free tests**: a test that never asserts is not a test

# Coding Style Rules (Universal)

> Applies to ALL languages. Language-specific overrides in `rules/<lang>/patterns.md`.

---

## File Structure (Rules 1-4)

### Rule 1
**One responsibility per file** - split when a file does more than one thing

### Rule 2
Optimal file size: 200-400 lines. Hard max: 800 lines

### Rule 3
Group related functions together; separate with a blank line

### Rule 4
Imports/includes at the top, sorted and grouped (stdlib > external > internal)

## Naming (Rules 5-11)

### Rule 5
**Meaningful names** - the name should reveal intent without a comment

### Rule 6
No single-letter variables except: `i`, `j`, `k` for loop counters; `x`, `y` for coordinates

### Rule 7
Booleans: prefix with `is`, `has`, `can`, `should` (e.g., `isValid`, `hasPermission`)

### Rule 8
Functions: verb + noun (e.g., `calculateTotal`, `fetchUser`, `validateInput`)

### Rule 9
Constants: SCREAMING_SNAKE_CASE (e.g., `MAX_RETRIES`, `DEFAULT_TIMEOUT_MS`)

### Rule 10
Avoid abbreviations unless universally understood (`ctx`, `req`, `res`, `db` are OK)

### Rule 11
Collections: use plural nouns (`users`, `orderItems`, not `userList`, `orderItemArray`)

## Immutability (Rules 12-15)

### Rule 12
**Prefer immutable by default**: `const` (JS/TS), `final` (Java/Dart), `readonly` (C#), `let` only when mutation is required

### Rule 13
Avoid reassigning function parameters

### Rule 14
Return new objects/arrays instead of mutating inputs

### Rule 15
Use `Object.freeze()` or equivalent for configuration objects

## Control Flow (Rules 16-20)

### Rule 16
**Early returns** over nested if/else - flatten the happy path

### Rule 17
Guard clauses at function start for preconditions

### Rule 18
Max 4 levels of nesting - extract to helper function if deeper

### Rule 19
Avoid `else` after `return`/`throw`/`continue`/`break`

### Rule 20
Ternary only for simple expressions (one line, no nesting)

## Constants and Magic Numbers (Rules 21-24)

### Rule 21
**No magic numbers** - every literal number or string must have a named constant

### Rule 22
Exception: 0, 1, -1, empty string, true/false in obvious contexts

### Rule 23
Group related constants in an enum or constant object

### Rule 24
Timeouts, limits, thresholds: always named constants with units in the name (e.g., `TIMEOUT_MS`, `MAX_SIZE_BYTES`)

## DRY (Rules 25-28)

### Rule 25
**Rule of three**: 1-2 duplicates are OK; 3+ means extract

### Rule 26
Don't over-abstract prematurely - duplication is cheaper than wrong abstraction

### Rule 27
Shared logic goes in a utility/helper, not copy-pasted

### Rule 28
If extracting makes the code harder to read, keep the duplication

## Functions (Rules 29-33)

### Rule 29
Max 30 lines per function (excluding blank lines and comments)

### Rule 30
Max 5 parameters - use an options/config object beyond that

### Rule 31
Single return type (don't return string | number | null randomly)

### Rule 32
Pure functions preferred: same input = same output, no side effects

### Rule 33
Side effects should be explicit and isolated (not buried in getters)

## Comments (Rules 34-37)

### Rule 34
Code should be self-documenting - comments explain WHY, not WHAT

### Rule 35
Delete commented-out code (that's what version control is for)

### Rule 36
TODO/FIXME must include a ticket number or owner

### Rule 37
API/public functions: always have a doc comment (JSDoc, docstring, godoc)

## Error Handling (Rules 38-42)

### Rule 38
Handle errors at the appropriate level (don't swallow, don't over-catch)

### Rule 39
Use specific error types, not generic `Error("something went wrong")`

### Rule 40
Never use exceptions for control flow

### Rule 41
Log errors with context (what operation, what input caused it)

### Rule 42
Fail fast: validate early, crash on unrecoverable errors

## Formatting (Rules 43-47)

### Rule 43
Consistent style enforced by formatter (Prettier, Black, gofmt, etc.)

### Rule 44
One blank line between logical sections

### Rule 45
No trailing whitespace

### Rule 46
Files end with a newline

### Rule 47
Max line length: follow language convention (80-120 chars)

# Contextual Rules Engine

> Part of Orchestrator V11.0 - Rules are injected into subagent prompts based on context.

---

## How It Works

```
User Request
    |
    v
Orchestrator analyzes task
    |
    v
Detects: language, domain, operation type
    |
    v
Loads ONLY relevant rules from rules/
    |
    v
Injects rules into subagent system prompt
    |
    v
Subagent executes with context-aware rules
```

The rules engine eliminates the need to pack every rule into every agent's prompt.
Instead, rules are loaded on-demand based on what the task actually requires.

## Directory Structure

```
rules/
  README.md              <- You are here
  common/                <- Universal rules (always loaded for code tasks)
    coding-style.md      <- Naming, structure, immutability, control flow
    security.md          <- 100 security rules (loaded for code that handles I/O, auth, data)
    testing.md           <- Test standards (loaded when writing/reviewing tests)
    git-workflow.md      <- Commit, branch, PR rules (loaded for git operations)
    database.md          <- 50 database rules (loaded for SQL, ORM, schema work)
    api-design.md        <- 50 API design rules (loaded for REST, GraphQL, endpoints)
  python/                <- Python-specific (loaded when .py files detected)
    patterns.md          <- PEP 8, type hints, async, project structure
  typescript/            <- TypeScript-specific (loaded when .ts/.tsx detected)
    patterns.md          <- strict mode, zod, discriminated unions, exports
  go/                    <- Go-specific (loaded when .go files detected)
    patterns.md          <- error handling, interfaces, concurrency, testing
```

## Rule Loading Logic

### Priority Order
1. **common/** rules load first (baseline)
2. **language/** rules load second (override/supplement common rules)
3. Language-specific rules take precedence where they conflict with common rules

### Context Detection

| Signal | Rules Loaded |
|--------|-------------|
| `.py` files in scope | `common/coding-style.md` + `python/patterns.md` |
| `.ts`/`.tsx` files in scope | `common/coding-style.md` + `typescript/patterns.md` |
| `.go` files in scope | `common/coding-style.md` + `go/patterns.md` |
| Task involves auth/API/data | `common/security.md` |
| Task involves writing tests | `common/testing.md` |
| Task involves git/PR/commit | `common/git-workflow.md` |
| Task involves database/SQL/ORM | `common/database.md` |
| Task involves API/REST/GraphQL | `common/api-design.md` |
| Multi-language project | All relevant language rules loaded |

### Selective Loading

Not all rules load for every task. Examples:

- **"Fix the CSS on the login page"** -> loads `coding-style.md` only (no security, no testing)
- **"Add JWT authentication to the API"** -> loads `coding-style.md` + `security.md` + `typescript/patterns.md`
- **"Write tests for the payment service"** -> loads `testing.md` + `python/patterns.md`
- **"Create a PR for the user feature"** -> loads `git-workflow.md` only
- **"Optimize the database queries"** -> loads `database.md` + `coding-style.md`
- **"Build a REST API for users"** -> loads `api-design.md` + `security.md` + `typescript/patterns.md`

This keeps subagent prompts focused and token-efficient.

## How to Add New Rules

### Adding a Rule to an Existing File
1. Open the relevant file (e.g., `rules/common/security.md`)
2. Add the rule in the same format as existing rules
3. Keep rules **actionable** - each rule should be something a developer can immediately apply
4. No academic theory - only practical, enforceable rules

### Adding a New Language
1. Create `rules/<language>/patterns.md`
2. Follow the same structure as existing language files
3. Include: style, idioms, testing patterns, project structure, tooling
4. Focus on what makes this language DIFFERENT (don't repeat common rules)

### Adding a New Domain (e.g., database, DevOps)
1. Create `rules/common/<domain>.md` or `rules/<specific>/<domain>.md`
2. Define clear trigger keywords for the orchestrator to detect when to load it
3. Keep the file under 200 lines (if larger, split by sub-domain)

## Rule Quality Checklist

Every rule must pass these criteria:

- [ ] **Actionable**: Developer knows exactly what to do
- [ ] **Specific**: No vague advice ("write good code")
- [ ] **Enforceable**: Can be checked in code review or by a linter
- [ ] **Justified**: There's a real-world reason (security, maintainability, performance)
- [ ] **Concise**: One rule = one sentence or short paragraph + example

## Token Budget

Rules are injected into prompts, so size matters:

| File | Actual Size | Budget | Purpose |
|------|-------------|--------|---------|
| coding-style.md | 167 lines | 200 max | Always loaded, keep lean |
| security.md | 146 lines | 250 max | Loaded selectively, comprehensive is OK |
| testing.md | 181 lines | 200 max | Loaded selectively |
| git-workflow.md | 171 lines | 180 max | Loaded selectively |
| python/patterns.md | 119 lines | 150 max | Loaded per-language |
| typescript/patterns.md | 142 lines | 150 max | Loaded per-language |
| go/patterns.md | 124 lines | 150 max | Loaded per-language |
| database.md | 77 lines | 150 max | Database work |
| api-design.md | 77 lines | 140 max | API work |

Total injection per task: aim for 200-400 lines of rules (actual files are well within budget).

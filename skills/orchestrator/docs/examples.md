# Orchestrator Workflow Examples (V12.0)

> Practical examples showing end-to-end orchestrator execution.

---

## Example 1: Simple Bug Fix

**User request:** "Fix the login button not working on mobile"

### Step 4: Decomposition
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Analyze mobile login component and identify bug | Analyzer | haiku | SUBAGENT | - |
| T2 | Fix the identified bug | Coder | inherit | SUBAGENT | T1 |
| T3 | Verify fix works | Reviewer | haiku | SUBAGENT | T2 |

### Step 6: Launch
```
Message 1: [Task(T1, Analyzer, haiku)]  -- only T1 is independent
```

### Step 7: Dependent tasks
```
T1 completes -> Message 2: [Task(T2, Coder)]
T2 completes -> Message 3: [Task(T3, Reviewer, haiku)]
```

### Step 8: Verification
```
VERIFICATION:
  Changes reviewed: 1 file (LoginButton.tsx)
  Satisfies request: YES
  Issues found: none
  Iteration: 1/2
```

---

## Example 2: Multi-File Feature (Parallel)

**User request:** "Add dark mode toggle to settings, update the theme provider, and add CSS variables"

### Step 4: Decomposition
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Create dark mode CSS variables | GUI Super Expert | inherit | SUBAGENT | - |
| T2 | Add toggle component to settings page | GUI Super Expert | inherit | SUBAGENT | - |
| T3 | Update theme provider with dark mode context | Languages Expert | inherit | SUBAGENT | - |
| T4 | Integration test: verify toggle switches theme | Tester Expert | inherit | SUBAGENT | T1, T2, T3 |

### Step 6: Launch (3 independent tasks in ONE message)
```
Message 1: [Task(T1) + Task(T2) + Task(T3)]  -- all 3 independent, ONE message
```

### Step 7: Dependent tasks
```
T1, T2, T3 all complete -> Message 2: [Task(T4)]
```

---

## Example 3: Analyze Then Implement (Sequential)

**User request:** "Optimize the slowest database queries in the user dashboard"

### Step 4: Decomposition
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Analyze dashboard queries, identify top 3 slowest | Analyzer | haiku | SUBAGENT | - |
| T2 | Optimize query 1 (add index, rewrite) | DB Query Optimizer L2 | inherit | SUBAGENT | T1 |
| T3 | Optimize query 2 (add index, rewrite) | DB Query Optimizer L2 | inherit | SUBAGENT | T1 |
| T4 | Optimize query 3 (add index, rewrite) | DB Query Optimizer L2 | inherit | SUBAGENT | T1 |
| T5 | Verify all queries improved | Reviewer | haiku | SUBAGENT | T2, T3, T4 |

### Step 6: Launch
```
Message 1: [Task(T1)]  -- only T1 is independent
```

### Step 7: Dependent tasks (parallelized)
```
T1 completes -> Message 2: [Task(T2) + Task(T3) + Task(T4)]  -- 3 optimizations in ONE message
T2,T3,T4 complete -> Message 3: [Task(T5)]
```

**Key:** T2, T3, T4 touch DIFFERENT queries/files, so they run in parallel.

---

## Example 4: Agent Team (Complex Feature)

**User request:** "Build a complete payment integration with Stripe: API endpoints, webhook handler, and admin dashboard"

### Step 4: Decomposition -- AGENT TEAM mode (3+ tasks needing communication)
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Build Stripe API endpoints (create checkout, manage subscriptions) | Payment Integration Expert | inherit | TEAMMATE | - |
| T2 | Build webhook handler (payment success, failure, refund events) | Integration Expert | inherit | TEAMMATE | - |
| T3 | Build admin dashboard (payment list, refund button, revenue chart) | GUI Super Expert | inherit | TEAMMATE | - |
| T4 | Integration testing across all components | Tester Expert | inherit | SUBAGENT | T1, T2, T3 |

### Step 6: Create Agent Team
```
Teammate 1 (Payment Integration Expert):
  Role: Stripe API endpoints
  Files: src/api/payments/, src/services/stripe.ts
  Context: Use Stripe SDK, create checkout sessions, manage subscriptions

Teammate 2 (Integration Expert):
  Role: Webhook handler
  Files: src/api/webhooks/, src/services/webhook-handler.ts
  Context: Handle payment_intent.succeeded, payment_intent.failed, charge.refunded

Teammate 3 (GUI Super Expert):
  Role: Admin dashboard
  Files: src/pages/admin/payments/, src/components/admin/
  Context: Payment list table, refund action button, revenue chart with Chart.js
```

**File ownership:** No overlaps between teammates. Lead relays shared types/interfaces.

### Step 7: After team completes
```
All teammates done -> [Task(T4, Tester Expert)] for integration testing
```

---

## Example 5: Security Audit (Research + Action)

**User request:** "Run a full security audit on the authentication module"

### Step 4: Decomposition
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Scan auth module for OWASP vulnerabilities | Security Unified Expert | inherit | SUBAGENT | - |
| T2 | Review auth code for logic flaws and best practices | Reviewer | inherit | SUBAGENT | - |
| T3 | Test auth endpoints for injection/bypass | Tester Expert | inherit | SUBAGENT | - |
| T4 | Fix all identified vulnerabilities | Coder | inherit | SUBAGENT | T1, T2, T3 |
| T5 | Verify fixes don't break functionality | Tester Expert | inherit | SUBAGENT | T4 |

### Step 6: Launch (3 independent in ONE message)
```
Message 1: [Task(T1) + Task(T2) + Task(T3)]
```

### Step 7: Dependent tasks
```
T1,T2,T3 complete -> Message 2: [Task(T4)]  -- Coder gets all findings as input
T4 completes -> Message 3: [Task(T5)]
```

---

## Example 6: Error Recovery Flow

**User request:** "Refactor the payment module to use the new API"

### Normal flow
| # | Task | Agent | Model | Mode | Depends On | Status |
|---|------|-------|-------|------|------------|--------|
| T1 | Analyze current payment module | Analyzer | haiku | SUBAGENT | - | DONE |
| T2 | Refactor to new API | Coder | inherit | SUBAGENT | T1 | DONE |
| T3 | Verify refactoring | Reviewer | haiku | SUBAGENT | T2 | FAILED |

### Step 8: Verification fails -- correction loop
```
VERIFICATION:
  Changes reviewed: 4 files
  Satisfies request: NO
  Issues found: ["Missing error handling for new API timeout", "Old callback not removed"]
  Iteration: 1/2

-> Create correction task:
  T4: Fix missing error handling + remove old callback (Coder, depends on T3 findings)
  T5: Re-verify (Reviewer, depends on T4)
```

### After correction
```
VERIFICATION:
  Changes reviewed: 4 files
  Satisfies request: YES
  Issues found: none
  Iteration: 2/2
```

---

## Example 7: Slash Command -- /tdd

**User types:** `/tdd add email validation to user registration`

### Orchestrator routes to: Tester + Coder (TDD workflow)
| # | Task | Agent | Model | Mode | Depends On |
|---|------|-------|-------|------|------------|
| T1 | Write failing tests for email validation rules | Tester Expert | inherit | SUBAGENT | - |
| T2 | Implement email validation to make tests pass | Coder | inherit | SUBAGENT | T1 |
| T3 | Refactor: clean up implementation while tests stay green | Languages Refactor Specialist L2 | inherit | SUBAGENT | T2 |
| T4 | Run full test suite, confirm no regressions | Tester Expert | haiku | SUBAGENT | T3 |

### Flow: Red -- Green -- Refactor -- Verify
```
Message 1: [Task(T1)]  -- write failing tests first (RED)
T1 done -> Message 2: [Task(T2)]  -- implement to pass (GREEN)
T2 done -> Message 3: [Task(T3)]  -- refactor (REFACTOR)
T3 done -> Message 4: [Task(T4)]  -- verify all green
```

---

## Anti-Patterns (What NOT to Do)

### WRONG: One task per message
```
Message 1: Task(T1)
Message 2: Task(T2)   <-- VIOLATION of Rule 2 if T1 and T2 are independent
Message 3: Task(T3)
```

### CORRECT: All independent tasks in ONE message
```
Message 1: [Task(T1) + Task(T2) + Task(T3)]
```

### WRONG: Orchestrator does work directly
```
Orchestrator reads src/utils.ts to check code  <-- VIOLATION of Rule 1
```

### CORRECT: Delegate to Analyzer
```
Task(Analyzer): "Read and analyze src/utils.ts for..."
```

### WRONG: Launch team for same-file edits
```
Teammate 1: Edit src/app.ts lines 1-50
Teammate 2: Edit src/app.ts lines 51-100  <-- FILE CONFLICT
```

### CORRECT: Sequential subagents for same file
```
Task(T1, Coder): Edit src/app.ts part 1 -> wait -> Task(T2, Coder): Edit src/app.ts part 2
```

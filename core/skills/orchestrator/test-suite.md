# Orchestrator V10.0 Test Suite

> **Version:** 10.0.0 | **Last Updated:** 2026-02-21
> **Purpose:** Comprehensive validation of Orchestrator V10.0 systems
> **Total Tests:** 47 tests across 7 categories

---

## Overview

This test suite validates all critical components of the Orchestrator V10.0 system. Each test has a unique ID, detailed execution steps, expected results, and specific commands or tools to use.

### Test Categories Summary

| Category | Tests | Priority | Estimated Time |
|----------|-------|----------|----------------|
| Health Check Tests | 8 | CRITICAL | 2 min |
| Memory Integration Tests | 6 | HIGH | 3 min |
| Observability Tests | 7 | HIGH | 3 min |
| Routing Tests | 8 | CRITICAL | 2 min |
| Agent Teams Tests | 6 | CRITICAL | 5 min |
| MCP Integration Tests | 6 | MEDIUM | 3 min |
| Integration Tests | 6 | HIGH | 10 min |

**Total Estimated Time:** ~28 minutes

---

## Test Environment Setup

### Prerequisites

Before running tests, verify:

```bash
# 1. Check Claude Code is running
claude --version

# 2. Verify settings.json location
cat ~/.claude/settings.json

# 3. Check Agent Teams is enabled
echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS  # Should be "1"
```

### Test Execution Order

```
1. Health Check Tests (must pass first)
2. Memory Integration Tests
3. Observability Tests
4. Routing Tests
5. Agent Teams Tests
6. MCP Integration Tests
7. Integration Tests (end-to-end)
```

---

## 1. Health Check Tests

### TEST-HC-001: Environment Variables Check

**Description:** Verify all required environment variables are set correctly.

**Execution Steps:**
1. Open Claude Code session
2. Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable
3. Verify authentication is configured (OAuth or API key)

**Command/Tool:**
```bash
# PowerShell
$env:CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
$env:ANTHROPIC_API_KEY
$env:ANTHROPIC_BASE_URL
```

**Expected Result:**
```
CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
ANTHROPIC_API_KEY = (set OR credentials file exists)
ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic" (if using GLM5 proxy)
```

**Pass Criteria:** All critical variables present, Agent Teams enabled

---

### TEST-HC-002: Agent Teams Feature Flag

**Description:** Verify Agent Teams feature is enabled via settings.json.

**Execution Steps:**
1. Read `~/.claude/settings.json`
2. Check for `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` in env block
3. Verify Teammate mode is configurable

**Command/Tool:**
```bash
# Read settings.json
cat ~/.claude/settings.json | grep -A5 "env"
```

**Expected Result:**
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    ...
  }
}
```

**Pass Criteria:** Feature flag set to "1"

---

### TEST-HC-003: Storage Directories Check

**Description:** Verify teams and tasks storage directories exist and are writable.

**Execution Steps:**
1. Check `~/.claude/teams/` directory exists
2. Check `~/.claude/tasks/` directory exists
3. Test write permissions in both directories

**Command/Tool:**
```bash
# Check directories
ls -la ~/.claude/teams/
ls -la ~/.claude/tasks/

# Test write permission
touch ~/.claude/teams/.write_test && rm ~/.claude/teams/.write_test && echo "teams: OK"
touch ~/.claude/tasks/.write_test && rm ~/.claude/tasks/.write_test && echo "tasks: OK"
```

**Expected Result:**
```
teams: OK
tasks: OK
```

**Pass Criteria:** Both directories exist and writable

---

### TEST-HC-004: Skills Directory Check

**Description:** Verify skills directory structure is valid.

**Execution Steps:**
1. List all skills in `~/.claude/skills/`
2. Verify each skill has valid SKILL.md with YAML frontmatter
3. Count total skills loaded

**Command/Tool:**
```bash
# List skills
ls -la ~/.claude/skills/

# Check SKILL.md files
for dir in ~/.claude/skills/*/; do
  if [ -f "$dir/SKILL.md" ]; then
    echo "$dir: OK"
  else
    echo "$dir: MISSING SKILL.md"
  fi
done
```

**Expected Result:**
```
~/.claude/skills/orchestrator/: OK
~/.claude/skills/commit/: OK
~/.claude/skills/review-pr/: OK
...
```

**Pass Criteria:** All skills have valid SKILL.md files

---

### TEST-HC-005: MCP Servers Availability

**Description:** Verify MCP servers are connected and available.

**Execution Steps:**
1. Use `ListMcpResourcesTool` to list available MCP resources
2. Verify at least 4 MCP servers are connected
3. Check deferred tools availability

**Command/Tool:**
```
Use tool: ListMcpResourcesTool
```

**Expected Result:**
```
At least 4 MCP servers available:
- web-reader
- web-search-prime
- claude.ai Canva
- zai-mcp-server
```

**Pass Criteria:** MCP servers list not empty

---

### TEST-HC-006: Network Connectivity Check

**Description:** Verify network connectivity to required endpoints.

**Execution Steps:**
1. Test connection to API endpoint
2. Test DNS resolution
3. Measure latency

**Command/Tool:**
```bash
# Test API endpoint
curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com --connect-timeout 5

# Test Z.AI proxy (if configured)
curl -s -o /dev/null -w "%{http_code}" https://api.z.ai --connect-timeout 5
```

**Expected Result:**
```
HTTP 200 or 401 (auth required) - connectivity OK
```

**Pass Criteria:** Endpoints reachable within 5 seconds

---

### TEST-HC-007: Memory File Validation

**Description:** Verify MEMORY.md file exists and is valid.

**Execution Steps:**
1. Check project memory path exists
2. Verify file parses as valid markdown
3. Check file size is within limits (<50KB)

**Command/Tool:**
```bash
# Check memory file
ls -la ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md

# Check file size
wc -c ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md
```

**Expected Result:**
```
File exists
Size < 50000 bytes
```

**Pass Criteria:** Memory file valid and within size limits

---

### TEST-HC-008: Full Health Check Report

**Description:** Generate complete health check report.

**Execution Steps:**
1. Invoke orchestrator skill
2. Review health check output in startup banner
3. Verify all checks pass

**Command/Tool:**
```
Invoke skill: /orchestrator with any simple task
```

**Expected Result:**
```
HEALTH CHECK:
  [OK] Agent Teams: ENABLED
  [OK] Memory Integration: ACTIVE
  [OK] MCP Connections: READY
  [OK] Routing Table: LOADED
  [OK] Error Recovery: ARMED
  [OK] Observability: ENABLED
```

**Pass Criteria:** All health checks show [OK]

---

## 2. Memory Integration Tests

### TEST-MEM-001: Memory Auto-Load

**Description:** Verify memory is automatically loaded at orchestrator startup.

**Execution Steps:**
1. Start orchestrator with a simple task
2. Check if memory context is loaded
3. Verify memory appears in orchestrator context

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "What project patterns are stored in memory?"
```

**Expected Result:**
```
Orchestrator should reference memory content if MEMORY.md exists
```

**Pass Criteria:** Memory content accessible to orchestrator

---

### TEST-MEM-002: Memory Path Resolution

**Description:** Verify memory path resolution follows priority order.

**Execution Steps:**
1. Check all memory path locations
2. Verify priority: Project Memory > User Memory > Global Memory

**Command/Tool:**
```bash
# Check all memory paths
ls -la ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md 2>/dev/null || echo "Not found"
ls -la ~/.claude/MEMORY.md 2>/dev/null || echo "Not found"
```

**Expected Result:**
```
Project memory takes precedence if multiple exist
```

**Pass Criteria:** Correct path selected based on priority

---

### TEST-MEM-003: Memory Context Injection

**Description:** Verify memory context is injected into subagent prompts.

**Execution Steps:**
1. Delegate a task to a subagent
2. Verify the subagent receives memory context
3. Check memory section appears in subagent prompt

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "Analyze the codebase structure"
```

**Expected Result:**
```
Subagent prompt should include:
## Memory Context (Auto-Loaded)
- Key patterns: ...
- Known issues: ...
```

**Pass Criteria:** Memory context block present in subagent delegation

---

### TEST-MEM-004: Memory Update After Session

**Description:** Verify memory is updated after significant sessions.

**Execution Steps:**
1. Complete 3+ tasks in a session
2. Check if session summary is generated
3. Verify memory file is updated

**Command/Tool:**
```bash
# After completing 3+ tasks, check memory modification time
stat ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md
```

**Expected Result:**
```
Memory file modified timestamp updated
Session summary prepended to memory
```

**Pass Criteria:** Memory reflects recent session activity

---

### TEST-MEM-005: Memory Backup Creation

**Description:** Verify single backup file is created on update.

**Execution Steps:**
1. Trigger memory update
2. Check for .bak file
3. Verify only one backup exists (no proliferation)

**Command/Tool:**
```bash
# Check for backup file
ls -la ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md.bak
```

**Expected Result:**
```
Single .bak file exists (MEMORY.md.bak)
No timestamped backups like MEMORY_20260221.md.bak
```

**Pass Criteria:** Exactly one backup file

---

### TEST-MEM-006: Memory Compression

**Description:** Verify memory compression when size exceeds threshold.

**Execution Steps:**
1. Check memory size against threshold (30KB)
2. Verify compression activates if exceeded
3. Confirm structure is preserved after compression

**Command/Tool:**
```bash
# Check memory size
SIZE=$(wc -c < ~/.claude/projects/c--Users-LeoDg/memory/MEMORY.md)
if [ $SIZE -gt 30000 ]; then
  echo "Memory exceeds threshold - compression should activate"
else
  echo "Memory within limits - no compression needed"
fi
```

**Expected Result:**
```
If >30KB: Compressed memory with preserved structure
If <30KB: No compression applied
```

**Pass Criteria:** Memory stays under 50KB limit

---

## 3. Observability Tests

### TEST-OBS-001: Metrics Collection

**Description:** Verify metrics are collected during orchestrator operations.

**Execution Steps:**
1. Execute a task through orchestrator
2. Check metrics are recorded
3. Verify metric types (counter, gauge, histogram)

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "List files in the current directory"
Then check session metrics output
```

**Expected Result:**
```
SESSION METRICS:
  Tasks: X completed / Y total
  Parallelism: Z avg per batch
  Duration: HH:MM:SS
  Errors: E (all recovered)
```

**Pass Criteria:** Metrics displayed in session output

---

### TEST-OBS-002: Logging Protocol

**Description:** Verify structured logging is functional.

**Execution Steps:**
1. Check log directory exists
2. Verify log file format is JSON
3. Check log rotation configuration

**Command/Tool:**
```bash
# Check log directory
ls -la ~/.claude/logs/

# Check log format (if exists)
head -1 ~/.claude/logs/orchestrator.log 2>/dev/null | python -m json.tool
```

**Expected Result:**
```
Log directory exists
JSON formatted log entries
```

**Pass Criteria:** Structured logs present and parseable

---

### TEST-OBS-003: Correlation ID Tracking

**Description:** Verify correlation IDs are propagated across operations.

**Execution Steps:**
1. Start orchestrator session
2. Delegate task to subagent
3. Check if same correlation ID is used

**Command/Tool:**
```
Invoke orchestrator and observe session ID in:
- Startup banner
- Task dispatch logs
- Subagent context
```

**Expected Result:**
```
Same session ID / correlation ID across all operations
```

**Pass Criteria:** Correlation ID consistent in logs

---

### TEST-OBS-004: Performance Tracking

**Description:** Verify task duration and latency tracking.

**Execution Steps:**
1. Execute a known task
2. Measure actual duration
3. Compare with tracked duration

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "Analyze the README.md file"
Note start/end time manually
```

**Expected Result:**
```
Tracked duration close to actual wall-clock time (+/- 1 second)
```

**Pass Criteria:** Duration tracking accurate within 10%

---

### TEST-OBS-005: Agent Usage Statistics

**Description:** Verify agent usage is tracked correctly.

**Execution Steps:**
1. Execute tasks using different agents
2. Check agent usage count in metrics
3. Verify counts match actual invocations

**Command/Tool:**
```
After multiple tasks, check:
AGENT USAGE (Top 5):
  1. Coder: X tasks
  2. Analyzer: Y tasks
  ...
```

**Expected Result:**
```
Agent counts match number of times each agent was invoked
```

**Pass Criteria:** Usage counts accurate

---

### TEST-OBS-006: Error Rate Calculation

**Description:** Verify error rate is calculated correctly.

**Execution Steps:**
1. Execute mix of successful and failing tasks
2. Check error rate in metrics
3. Verify rate matches actual failures

**Command/Tool:**
```
Session should track:
ERRORS:
  Total: X
  Auto-Recovered: Y
  Manual Fix: Z
```

**Expected Result:**
```
Error rate = (failed tasks / total tasks) * 100
```

**Pass Criteria:** Error rate calculation correct

---

### TEST-OBS-007: Session Cleanup Verification

**Description:** Verify session cleanup runs after Documenter.

**Execution Steps:**
1. Create temp files during session
2. Trigger session end
3. Verify temp files are deleted

**Command/Tool:**
```bash
# Create temp file
touch /tmp/test_temp_file.tmp

# After orchestrator session ends:
ls /tmp/test_temp_file.tmp 2>/dev/null && echo "FAIL: file not deleted" || echo "OK: file deleted"
```

**Expected Result:**
```
Temp files deleted
CLEANUP: OK | files_deleted=N
```

**Pass Criteria:** No orphaned temp files

---

## 4. Routing Tests

### TEST-RT-001: Routing Table Loaded

**Description:** Verify routing table is loaded with 39 agents.

**Execution Steps:**
1. Start orchestrator
2. Check agent roster display
3. Count total agents

**Command/Tool:**
```
Invoke skill: /orchestrator
Check startup banner for:
ORCHESTRATOR V10.0 ULTRA | 39 agents ready
```

**Expected Result:**
```
Routing Table: LOADED (39 agents)
```

**Pass Criteria:** Exactly 39 agents in roster

---

### TEST-RT-002: Core Agent Routing

**Description:** Verify core agents (L0) are routed correctly.

**Execution Steps:**
1. Submit tasks matching core agent keywords
2. Verify correct core agent is selected
3. Check model assignment

**Command/Tool:**
```
Test keywords:
- "implement" -> Coder
- "analyze" -> Analyzer
- "review" -> Reviewer
- "document" -> Documenter
```

**Expected Result:**
```
Keyword matches correct agent
Model: haiku for Analyzer/Documenter, sonnet for Coder/Reviewer
```

**Pass Criteria:** Correct agent selected for each keyword

---

### TEST-RT-003: Expert Agent Routing

**Description:** Verify L1 expert agents are routed correctly.

**Execution Steps:**
1. Submit tasks with expert-specific keywords
2. Verify correct expert is selected
3. Check fallback chain works

**Command/Tool:**
```
Test keywords:
- "GUI, PyQt5" -> GUI Super Expert
- "database, SQL" -> Database Expert
- "security, encryption" -> Security Unified Expert
- "MQL, EA" -> MQL Expert
- "trading, strategy" -> Trading Strategy Expert
```

**Expected Result:**
```
Correct L1 expert selected for domain-specific tasks
```

**Pass Criteria:** Expert routing matches keyword domain

---

### TEST-RT-004: L2 Sub-Agent Routing

**Description:** Verify L2 sub-agents are routed when specialized keywords present.

**Execution Steps:**
1. Submit tasks with L2-specific keywords
2. Verify L2 specialist is selected over L1
3. Check delegation from L1 to L2

**Command/Tool:**
```
Test L2 keywords:
- "layout, splitter" -> GUI Layout Specialist L2
- "query optimization, N+1" -> DB Query Optimizer L2
- "JWT, refresh token" -> Security Auth Specialist L2
- "unit test, mock" -> Test Unit Specialist L2
```

**Expected Result:**
```
L2 specialist selected when L2 keywords present
```

**Pass Criteria:** L2 routing takes precedence

---

### TEST-RT-005: Keyword Collision Resolution

**Description:** Verify keyword collisions are resolved correctly.

**Execution Steps:**
1. Submit task with multiple domain keywords
2. Check which agent is selected
3. Verify most specific match wins

**Command/Tool:**
```
Test collision:
- "implement GUI security feature" -> GUI Super Expert or Security Unified Expert?
Expected: More specific/specialized agent selected
```

**Expected Result:**
```
Most specific agent selected based on keyword strength
```

**Pass Criteria:** Collision resolved deterministically

---

### TEST-RT-006: Fallback Chain Test

**Description:** Verify fallback chain works when primary agent fails.

**Execution Steps:**
1. Force primary agent failure
2. Verify fallback agent is tried
3. Check fallback chain completes

**Command/Tool:**
```
Fallback chains:
- GUI Super Expert -> Languages Expert -> Coder
- Database Expert -> Integration Expert -> Coder
- Security Unified Expert -> Coder -> Reviewer
```

**Expected Result:**
```
If primary fails, fallback agent attempted
```

**Pass Criteria:** Fallback mechanism functional

---

### TEST-RT-007: Model Assignment Verification

**Description:** Verify correct model is assigned per agent type.

**Execution Steps:**
1. Check model assignment for each agent
2. Verify haiku for mechanical tasks
3. Verify sonnet for problem-solving tasks

**Command/Tool:**
```
Model rules:
- Analyzer -> haiku (exploration)
- Coder -> sonnet (inherit) (implementation)
- Documenter -> haiku (documentation)
- Architect Expert -> opus (design decisions)
```

**Expected Result:**
```
Model assignment matches agent complexity
```

**Pass Criteria:** Model assignment correct per routing table

---

### TEST-RT-008: Decision Tree Traversal

**Description:** Verify decision tree selects correct agent.

**Execution Steps:**
1. Submit various task types
2. Trace decision tree path
3. Verify final agent selection

**Command/Tool:**
```
Test decision tree:
1. GUI task -> gui-super-expert
2. Not GUI, API task -> integration_expert
3. Not API, DB task -> database_expert
4. Not DB, Security task -> security_unified_expert
5. Not Security, Trading task -> trading_strategy_expert
6. Not Trading, MQL task -> mql_expert
7. Default -> coder + analyzer
```

**Expected Result:**
```
Decision tree correctly traversed for each task type
```

**Pass Criteria:** Decision tree logic correct

---

## 5. Agent Teams Tests

### TEST-TEAM-001: Team Creation

**Description:** Verify agent team can be created successfully.

**Execution Steps:**
1. Create agent team with multiple teammates
2. Verify team config file created
3. Check teammate spawn success

**Command/Tool:**
```
Invoke skill: /orchestrator
Request team creation for parallel review task
```

**Expected Result:**
```
Team config at ~/.claude/teams/{team-name}/config.json
Teammates spawned and active
```

**Pass Criteria:** Team created with correct structure

---

### TEST-TEAM-002: Teammate Spawn

**Description:** Verify teammates can be spawned successfully.

**Execution Steps:**
1. Spawn 3 teammates with different roles
2. Verify each teammate is active
3. Check teammate context inheritance

**Command/Tool:**
```
Use TeamCreate tool or orchestrator team creation
Check ~/.claude/teams/{team-name}/config.json for member list
```

**Expected Result:**
```
3 teammates spawned
Each with unique name and role
```

**Pass Criteria:** Teammates spawned and accessible

---

### TEST-TEAM-003: Task List Coordination

**Description:** Verify task list is shared across teammates.

**Execution Steps:**
1. Create team with shared task list
2. Verify tasks visible to all teammates
3. Check task assignment works

**Command/Tool:**
```
Check task list at ~/.claude/tasks/{team-name}/
Verify all teammates can read/write tasks
```

**Expected Result:**
```
Shared task list accessible
Tasks correctly assigned and updated
```

**Pass Criteria:** Task coordination functional

---

### TEST-TEAM-004: Teammate Communication

**Description:** Verify teammates can communicate via SendMessage.

**Execution Steps:**
1. Have teammate send message to another
2. Verify message delivery
3. Check message content preserved

**Command/Tool:**
```
Use SendMessage tool with:
  type: "message"
  recipient: "teammate-name"
  content: "test message"
```

**Expected Result:**
```
Message delivered to recipient
Message appears in recipient's context
```

**Pass Criteria:** Inter-teammate communication works

---

### TEST-TEAM-005: Team Shutdown

**Description:** Verify team can be gracefully shut down.

**Execution Steps:**
1. Request team shutdown
2. Verify all teammates stop
3. Check cleanup completes

**Command/Tool:**
```
Send shutdown_request to all teammates
Then call TeamDelete
```

**Expected Result:**
```
All teammates acknowledge shutdown
Team directories removed
```

**Pass Criteria:** Clean shutdown with no orphan processes

---

### TEST-TEAM-006: Plan Approval Workflow

**Description:** Verify plan approval workflow for teammates.

**Execution Steps:**
1. Require plan approval for a teammate
2. Have teammate submit plan
3. Approve or reject plan

**Command/Tool:**
```
Use SendMessage with:
  type: "plan_approval_response"
  approve: true/false
```

**Expected Result:**
```
Teammate waits for approval
Approved plans proceed, rejected plans revise
```

**Pass Criteria:** Plan approval workflow functional

---

## 6. MCP Integration Tests

### TEST-MCP-001: Tool Discovery

**Description:** Verify MCP tools can be discovered via ToolSearch.

**Execution Steps:**
1. Search for available MCP tools
2. Verify tool list returned
3. Check tool descriptions

**Command/Tool:**
```
Use ToolSearch tool:
  query: "web-reader"
  max_results: 5
```

**Expected Result:**
```
mcp__web-reader__webReader found
Tool loaded and available for use
```

**Pass Criteria:** MCP tools discoverable

---

### TEST-MCP-002: Deferred Tool Loading

**Description:** Verify deferred tools load correctly before use.

**Execution Steps:**
1. Attempt to use deferred tool without loading
2. Load tool via ToolSearch
3. Retry tool usage

**Command/Tool:**
```
Step 1: Try direct call (should fail)
Step 2: ToolSearch(query="select:mcp__web-reader__webReader")
Step 3: Use loaded tool
```

**Expected Result:**
```
Direct call fails
ToolSearch succeeds
Tool then usable
```

**Pass Criteria:** Deferred loading mechanism works

---

### TEST-MCP-003: Web Reader MCP

**Description:** Verify web-reader MCP server is functional.

**Execution Steps:**
1. Load web-reader tool
2. Fetch a test URL
3. Verify content returned

**Command/Tool:**
```
ToolSearch(query="web-reader")
Then use mcp__web-reader__webReader with:
  url: "https://example.com"
```

**Expected Result:**
```
URL content fetched and returned
Markdown or text format output
```

**Pass Criteria:** Web content successfully retrieved

---

### TEST-MCP-004: Web Search MCP

**Description:** Verify web-search-prime MCP server is functional.

**Execution Steps:**
1. Load web-search tool
2. Execute search query
3. Verify results returned

**Command/Tool:**
```
ToolSearch(query="web-search")
Then use mcp__web-search-prime__webSearchPrime with:
  query: "Claude AI latest news"
```

**Expected Result:**
```
Search results returned
Results include titles, URLs, snippets
```

**Pass Criteria:** Search results successfully retrieved

---

### TEST-MCP-005: Image Analysis MCP

**Description:** Verify image analysis MCP server is functional.

**Execution Steps:**
1. Load image analysis tool
2. Submit image URL
3. Verify analysis returned

**Command/Tool:**
```
ToolSearch(query="analyze_image")
Then use mcp__4_5v_mcp__analyze_image with:
  imageSource: "https://example.com/image.jpg"
  prompt: "Describe this image"
```

**Expected Result:**
```
Image analysis returned
Description matches image content
```

**Pass Criteria:** Image analysis functional

---

### TEST-MCP-006: MCP Error Handling

**Description:** Verify MCP errors are handled gracefully.

**Execution Steps:**
1. Invoke MCP tool with invalid parameters
2. Verify error is caught
3. Check error recovery

**Command/Tool:**
```
Call MCP tool with invalid URL or parameters
Verify error handling
```

**Expected Result:**
```
Error caught and logged
Recovery action suggested
Session continues
```

**Pass Criteria:** Errors handled without crashing

---

## 7. Integration Tests

### TEST-INT-001: End-to-End Simple Task

**Description:** Verify complete orchestrator flow for simple task.

**Execution Steps:**
1. Invoke orchestrator with simple task
2. Verify all phases execute
3. Check final report

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "Create a hello world Python script"
```

**Expected Result:**
```
Phase 1: Banner displayed
Phase 2: Health check passed
Phase 3: Agent roster shown
Step 1-10: Full algorithm executed
Final report: SUCCESS
```

**Pass Criteria:** Complete flow without errors

---

### TEST-INT-002: End-to-End Multi-Agent Task

**Description:** Verify orchestrator handles multi-agent coordination.

**Execution Steps:**
1. Submit task requiring multiple agents
2. Verify parallel execution
3. Check dependency handling

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "Analyze the codebase, implement a logging utility, and write tests"
```

**Expected Result:**
```
3+ agents invoked
Parallel batch for independent tasks
Sequential for dependent tasks
```

**Pass Criteria:** Multi-agent coordination correct

---

### TEST-INT-003: Error Recovery Flow

**Description:** Verify error recovery system works end-to-end.

**Execution Steps:**
1. Submit task that will fail
2. Verify error detection
3. Check recovery action

**Command/Tool:**
```
Task: "Read non-existent file: /path/to/nowhere/file.txt"
```

**Expected Result:**
```
Error detected
Diagnostic run
Recovery attempted (retry or fallback)
```

**Pass Criteria:** Error recovery triggered and handled

---

### TEST-INT-004: Memory + Routing Integration

**Description:** Verify memory influences routing decisions.

**Execution Steps:**
1. Store agent preference in memory
2. Submit task matching preference
3. Verify preferred agent selected

**Command/Tool:**
```
Add to MEMORY.md:
## Agent Performance Notes
- Coder: Good performance on Python tasks

Then submit Python implementation task
```

**Expected Result:**
```
Memory-aware routing selects preferred agent
```

**Pass Criteria:** Memory affects routing decisions

---

### TEST-INT-005: Observability + Error Integration

**Description:** Verify observability tracks errors correctly.

**Execution Steps:**
1. Execute tasks with mixed results
2. Check observability metrics
3. Verify error tracking

**Command/Tool:**
```
Execute session with:
- 3 successful tasks
- 1 failing task

Check final metrics for error count
```

**Expected Result:**
```
Errors: 1 (auto-recovered: 1)
Error rate: 25%
```

**Pass Criteria:** Observability accurately reflects session

---

### TEST-INT-006: Full System Stress Test

**Description:** Verify system handles high load.

**Execution Steps:**
1. Submit 10 parallel tasks
2. Monitor resource usage
3. Verify all tasks complete

**Command/Tool:**
```
Invoke skill: /orchestrator
Task: "Analyze all Python files in the project and create a summary for each"
```

**Expected Result:**
```
10+ tasks dispatched
Parallel efficiency > 70%
All tasks complete within timeout
No memory leaks
```

**Pass Criteria:** System stable under load

---

## Test Execution

### Quick Test Run (Essential Tests)

```bash
# Run critical tests only (~10 minutes)
Tests: HC-001, HC-002, RT-001, TEAM-001, INT-001
```

### Full Test Suite Run

```bash
# Run all tests (~28 minutes)
# Execute in order by category
1. Health Check Tests (8 tests)
2. Memory Integration Tests (6 tests)
3. Observability Tests (7 tests)
4. Routing Tests (8 tests)
5. Agent Teams Tests (6 tests)
6. MCP Integration Tests (6 tests)
7. Integration Tests (6 tests)
```

### Automated Test Runner

```python
# test_runner.py - Automated test execution
import subprocess
import json
from datetime import datetime

class OrchestratorTestRunner:
    def __init__(self):
        self.results = []
        self.passed = 0
        self.failed = 0

    def run_test(self, test_id, test_func):
        start = datetime.now()
        try:
            result = test_func()
            status = "PASS" if result else "FAIL"
            if result:
                self.passed += 1
            else:
                self.failed += 1
        except Exception as e:
            status = "ERROR"
            self.failed += 1

        duration = (datetime.now() - start).total_seconds()
        self.results.append({
            "test_id": test_id,
            "status": status,
            "duration_sec": duration
        })
        return status == "PASS"

    def run_category(self, category, tests):
        print(f"\n=== {category} ===")
        for test_id, test_func in tests:
            status = self.run_test(test_id, test_func)
            symbol = "[OK]" if status else "[FAIL]"
            print(f"  {symbol} {test_id}")

    def report(self):
        total = self.passed + self.failed
        print(f"\n{'='*50}")
        print(f"TEST RESULTS: {self.passed}/{total} PASSED")
        print(f"{'='*50}")
        return self.failed == 0
```

---

## Expected Results

### Summary Table

| Category | Tests | Pass Threshold | Critical |
|----------|-------|----------------|----------|
| Health Check | 8 | 8/8 (100%) | YES |
| Memory Integration | 6 | 5/6 (83%) | NO |
| Observability | 7 | 6/7 (86%) | NO |
| Routing | 8 | 8/8 (100%) | YES |
| Agent Teams | 6 | 5/6 (83%) | YES |
| MCP Integration | 6 | 4/6 (67%) | NO |
| Integration | 6 | 5/6 (83%) | YES |

### Critical Tests (Must Pass)

- TEST-HC-001: Environment Variables
- TEST-HC-002: Agent Teams Feature Flag
- TEST-RT-001: Routing Table Loaded
- TEST-TEAM-001: Team Creation
- TEST-INT-001: End-to-End Simple Task

### Overall Pass Criteria

```
PASS: >= 42/47 tests pass (89%)
      All critical tests pass
      No blocking errors
```

---

## Troubleshooting

### Common Test Failures

| Test | Failure Symptom | Resolution |
|------|-----------------|------------|
| HC-001 | Agent Teams disabled | Set env var in settings.json |
| HC-002 | Feature flag missing | Add `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` |
| HC-003 | Directory not writable | Fix permissions on ~/.claude/ |
| RT-001 | Agents not loaded | Check routing-table.md syntax |
| TEAM-001 | Team creation fails | Verify storage directories exist |
| MCP-001 | Tools not found | Run ToolSearch before using |

### Diagnostic Commands

```bash
# Full system check
cat ~/.claude/settings.json | grep -A10 "env"
ls -la ~/.claude/teams/ ~/.claude/tasks/
cat ~/.claude/skills/orchestrator/SKILL.md | head -20

# Memory check
wc -c ~/.claude/projects/*/memory/MEMORY.md

# MCP check
# Use ListMcpResourcesTool in Claude Code
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 10.0.0 | 2026-02-21 | Initial test suite for Orchestrator V10.0 |

---

**End of Orchestrator V10.0 Test Suite**

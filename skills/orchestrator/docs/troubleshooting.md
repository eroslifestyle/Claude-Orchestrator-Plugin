# Orchestrator Troubleshooting Guide V12.0

> Solutions for common issues and failure modes.

---

## Quick Diagnostics

Run these commands to diagnose issues:
- `/status` - System health overview
- `/metrics` - Performance metrics
- `/cleanup` - Clear temporary files

---

## Task Failures

### Task Timeout (>5 minutes)
**Symptoms:** Subagent doesn't respond, task stuck as IN_PROGRESS
**Causes:** Complex task, model overload, network issue
**Fix:**
1. Check task complexity - break into smaller subtasks
2. Retry with fresh context (max 3 retries)
3. Try different model (haiku for simple, opus for complex)
4. If persistent: escalate to user

### Agent Not Found
**Symptoms:** "subagent_type not recognized" error
**Causes:** Agent name mismatch between routing and Task tool
**Fix:**
1. Verify agent name matches Task tool's available subagent_types exactly
2. Check SKILL.md routing table for correct agent name
3. Fallback: use `general-purpose` subagent_type

### Agent Returns Empty Results
**Symptoms:** Subagent completes but provides no useful output
**Causes:** Insufficient context in prompt, wrong agent selected
**Fix:**
1. Add more context to the task prompt
2. Include specific file paths and line numbers
3. Verify correct agent was selected for the task type

---

## MCP Issues

### ToolSearch Returns No Results
**Symptoms:** "No matching tools found"
**Causes:** Wrong keyword, tool not loaded, server offline
**Fix:**
1. Try broader keywords: "slack" instead of "slack_post_message"
2. Check if MCP server is enabled in settings.local.json
3. For native tools (Canva, web-reader): they're always available

### MCP Server Offline
**Symptoms:** Connection refused, timeout on MCP calls
**Causes:** Server not started, config error, port conflict
**Fix:**
1. Check settings.local.json for correct server config
2. Restart Claude Code session
3. Fallback: use alternative tools or manual approach

---

## Memory Issues

### MEMORY.md Not Loading
**Symptoms:** Orchestrator skips memory context, patterns not recognized
**Causes:** File missing, wrong path, corrupted content
**Fix:**
1. Verify file exists at expected path
2. Check file is valid markdown (not binary/corrupted)
3. Recreate from session context if needed

### instincts.json Corrupted
**Symptoms:** Learning capture fails, JSON parse errors
**Causes:** Interrupted write, concurrent access
**Fix:**
1. System auto-recovers: backs up to .bak, reinitializes
2. If auto-recovery fails: delete and recreate with empty schema
3. Check learnings/ directory for .bak files with recent data

---

## Team Issues

### Teammate Deadlock
**Symptoms:** Multiple agents waiting for each other, no progress
**Causes:** Circular file dependencies, communication deadlock
**Fix:**
1. Check file ownership - no two agents should edit same file
2. Kill stuck teammates, restructure as sequential tasks
3. Use SUBAGENT mode instead of TEAMMATE for conflicting tasks

### File Conflicts
**Symptoms:** "Edit failed: old_string not found" after teammate edit
**Causes:** Two agents editing the same file
**Fix:**
1. NEVER assign same file to multiple agents
2. If unavoidable: make sequential (add dependency)
3. Use file locking (sequential retry with lock, max 3)

---

## Windows-Specific Issues

### NUL Files
**Symptoms:** Undeletable "NUL" files in project directories
**Causes:** Windows reserved device name accidentally created
**Fix:** Run `/cleanup` or manually:
```python
python -c "import ctypes; ctypes.windll.kernel32.DeleteFileW(r'\\\\?\\FULL_PATH\\NUL')"
```

### Path Issues
**Symptoms:** File not found errors with backslashes
**Causes:** Windows path separators in Unix-expecting code
**Fix:** Use forward slashes in all paths passed to tools

---

## Performance Issues

### Slow Response Times
**Symptoms:** Tasks take much longer than expected
**Causes:** Context window near capacity, too many sequential calls
**Fix:**
1. Run `/compact` to compress context
2. Maximize parallelism (independent tasks in ONE message)
3. Use haiku model for mechanical tasks (faster)

### Context Window Exhaustion
**Symptoms:** Lost context, repeated questions, truncated output
**Causes:** Long session, many large file reads
**Fix:**
1. Run `/checkpoint` to save state
2. Run `/compact` to compress
3. Start new session if needed, load checkpoint

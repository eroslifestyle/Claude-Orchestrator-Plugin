# MCP Plugin Integration Module V12.0

> Module for MCP server management, tool discovery, and integration patterns.
> Only servers enabled in settings.json are active.

> **Orchestrator Extension** - Model Context Protocol plugin management and routing

---

## Overview

The orchestrator integrates with three categories of external tools:

1. **MCP Servers** - Actual Model Context Protocol servers (require ToolSearch)
2. **Native Tools** - Built into Claude Code (always available, no ToolSearch needed)
3. **Marketplace Plugins** - Available from plugin marketplace (require activation)

**Critical distinction:** Native tools use `mcp__` prefix for internal organization but are NOT MCP servers.

---

## Tool Classification

### MCP Servers (Actual MCP Protocol)

These are real MCP protocol servers that require `ToolSearch` before use:

| Server | Type | Status | Config Location |
|--------|------|--------|-----------------|
| orchestrator | stdio (Python) | **Active** | settings.json |
| slack | HTTP (OAuth) | Inactive | settings.json (not configured) |
| firebase | stdio (NPX) | Inactive | settings.json (not configured) |

Only `orchestrator` is currently active. Slack and Firebase are configured but not enabled.

### Native Tools (NOT MCP -- Built into Claude Code)

These tools are ALWAYS available without `ToolSearch`:

| Tool | Prefix | Function |
|------|--------|----------|
| canva | `mcp__claude_ai_Canva__*` | Design generation, editing, export |
| web-reader | `mcp__web-reader__*` | URL content extraction, markdown conversion |
| web-search-prime | `mcp__web-search-prime__*` | Web search with filters |
| zai-mcp-server | `mcp__zai-mcp-server__*` | Image/video analysis, UI processing |

**Note:** The `mcp__` prefix is for Claude Code internal organization only. These are NOT MCP servers.

### Native Tool Capabilities

| Tool | Capabilities | Common Use Cases |
|------|-------------|------------------|
| **canva** | Design generation, editing, export, thumbnails | Creating presentations, social media graphics, export to PNG/PDF |
| **web-reader** | URL content extraction, markdown conversion, image retention | Reading documentation, extracting article content, web scraping |
| **web-search-prime** | Web search with filters, domain restrictions | Finding current information, researching APIs, documentation lookup |
| **zai-mcp-server** | Image analysis, video analysis, UI diff checking, technical diagrams | Screenshot analysis, UI testing, diagram understanding |

#### Tool-Specific Notes

- **canva**: Requires design ID for editing operations; supports templates
- **web-reader**: Set `retain_images=true` for visual content; `timeout=30` for slow sites
- **web-search-prime**: Use `allowed_domains` to restrict sources; supports date filters
- **zai-mcp-server**: Best for visual content analysis; supports batch processing

### Marketplace MCP Plugins (Available, Require Activation)

These plugins are available from the Claude Code marketplace:

| Plugin | Purpose | Agent Binding |
|--------|---------|---------------|
| context7 | Context management | Analyzer |
| github | GitHub API integration | DevOps Expert |
| gitlab | GitLab API integration | DevOps Expert |
| serena | Serena integration | Integration Expert |
| playwright | Browser automation | Browser Automation Expert |
| stripe | Payment processing | Payment Integration Expert |
| supabase | Backend-as-a-Service | Database Expert |
| greptile | Code search | Analyzer |
| linear | Issue tracking | DevOps Expert |
| laravel-boost | Laravel development | Languages Expert |

---

## Profile Configuration

| Profile | Config File | Active MCP | Native Tools |
|---------|-------------|------------|--------------|
| cca (Anthropic) | settings-anthropic.json | orchestrator | All 4 available |
| ccg (GLM5) | settings-glm.json | orchestrator | All 4 available |

Both profiles have access to the same native tools. MCP server availability depends on configuration.

---

## Invocation Rules

### 1. MCP Servers (Require ToolSearch)

```
# CORRECT: Load then call
ToolSearch(query="slack")
mcp__slack__post_message(...)

# WRONG: Call without loading
mcp__slack__post_message(...)  # FAILS
```

### 2. Native Tools (Direct Call)

```
# Native tools are always available - NO ToolSearch needed
mcp__web-reader__webReader(url="https://example.com")
mcp__claude_ai_Canva__get-design(designId="...")
```

### 3. Tool Discovery (MCP Only)

```
# Method 1: Keyword search (returns up to 5 tools)
ToolSearch(query="slack")

# Method 2: Domain search (require prefix)
ToolSearch(query="+slack send")

# Method 3: Direct selection
ToolSearch(query="select:mcp__slack__post_message")
```

---

## Subagent MCP Access Pattern

Subagents spawned via Task tool do NOT have ToolSearch. When a task needs MCP:

1. Orchestrator loads the MCP tool via ToolSearch
2. Orchestrator invokes the tool and captures results
3. Results are passed to the subagent as task context

Subagents should NEVER attempt to call MCP tools directly.

For native tools, subagents CAN call them directly (no ToolSearch needed).

---

## Error Handling

| Error | Recovery | Retries |
|-------|----------|---------|
| Tool not found | Try keyword search with broader terms | 2 |
| Server timeout | Retry with exponential backoff | 3 |
| Auth failure | Check server config in settings.json | 1 |
| Server offline | Skip MCP operation, use fallback | 1 |

### MCP Fallback Mapping

| Primary Tool | Fallback | Fallback 2 |
|--------------|----------|------------|
| slack | Console logging | Direct output |
| firebase | Local file storage | In-memory |
| orchestrator | Manual delegation | Direct tool calls |

---

## Active vs Inactive Servers

Only servers listed in `settings.json` -> `enabledMcpjsonServers` are active.

**Currently active:** `orchestrator` only.

**Inactive (configured but not enabled):** `slack`, `firebase`

To activate: Add server to `enabledMcpjsonServers` array in settings.json.

---

## Quick Reference

| Tool Type | ToolSearch Required? | Always Available? |
|-----------|---------------------|-------------------|
| MCP Servers (orchestrator, slack, firebase) | YES | NO (depends on config) |
| Native Tools (canva, web-reader, etc.) | NO | YES |
| Marketplace Plugins | YES | NO (must install first) |

---

*MCP Plugin Integration Module V12.0 - Orchestrator Extension*

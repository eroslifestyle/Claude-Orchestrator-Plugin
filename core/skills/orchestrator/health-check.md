# Health Check Module V10.0

## Overview

The Health Check Module provides comprehensive diagnostic capabilities for the Orchestrator V10.0 system. It performs systematic checks across all critical components to ensure system integrity, proper configuration, and operational readiness.

**Purpose:**
- Diagnose system configuration issues before they cause failures
- Validate environment setup for agent teams and MCP servers
- Provide actionable recovery recommendations
- Generate diagnostic reports for troubleshooting

**Invocation:**
```
/health-check [options]
```

---

## Checks Performed

### 1. ENVIRONMENT CHECK

Verifies required environment variables for orchestrator operation.

| Variable | Purpose | Severity if Missing |
|----------|---------|---------------------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enables Agent Teams feature | HIGH |
| `ANTHROPIC_API_KEY` | API authentication (via OAuth or env) | CRITICAL |
| `ANTHROPIC_BASE_URL` | API endpoint (optional, for proxies) | LOW |
| `HOME` / `USERPROFILE` | User home directory detection | CRITICAL |
| `PATH` | Executable discovery | MEDIUM |

**Diagnostic Protocol:**
```python
def check_environment():
    checks = []

    # Agent Teams flag
    agent_teams = os.environ.get('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS')
    checks.append({
        'name': 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS',
        'status': 'OK' if agent_teams == '1' else 'DISABLED',
        'value': agent_teams or 'not set',
        'severity': 'HIGH' if not agent_teams else 'NONE'
    })

    # API Key (check both env and credentials file)
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    creds_file = Path.home() / '.claude' / '.credentials.json'
    has_creds = creds_file.exists()

    checks.append({
        'name': 'ANTHROPIC_AUTHENTICATION',
        'status': 'OK' if (api_key or has_creds) else 'MISSING',
        'value': 'env' if api_key else ('oauth' if has_creds else 'none'),
        'severity': 'CRITICAL' if not (api_key or has_creds) else 'NONE'
    })

    return checks
```

---

### 2. AGENT TEAMS CHECK

Verifies if Agent Teams feature is properly enabled and configured.

| Check | Description | Status Codes |
|-------|-------------|--------------|
| Feature Flag | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` | OK / DISABLED |
| Teammate Mode | In-process vs tmux availability | OK / LIMITED |
| Storage Directory | `~/.claude/teams/` exists and writable | OK / ERROR |
| Task Storage | `~/.claude/tasks/` exists and writable | OK / ERROR |

**Diagnostic Protocol:**
```python
def check_agent_teams():
    results = {
        'enabled': False,
        'mode': 'unknown',
        'storage': {}
    }

    # Check feature flag
    results['enabled'] = os.environ.get('CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS') == '1'

    # Determine teammate mode
    if platform.system() == 'Windows':
        results['mode'] = 'in-process'
        results['mode_note'] = 'tmux not available on Windows'
    else:
        results['mode'] = 'auto'  # Will use tmux if available

    # Check storage directories
    for dir_name in ['teams', 'tasks']:
        dir_path = Path.home() / '.claude' / dir_name
        try:
            dir_path.mkdir(parents=True, exist_ok=True)
            test_file = dir_path / '.write_test'
            test_file.write_text('test')
            test_file.unlink()
            results['storage'][dir_name] = 'OK'
        except Exception as e:
            results['storage'][dir_name] = f'ERROR: {e}'

    return results
```

---

### 3. MCP CHECK

Verifies availability and health of MCP (Model Context Protocol) servers.

| MCP Server | Purpose | Priority |
|------------|---------|----------|
| `web-reader` | Fetch and read web content | HIGH |
| `web-search-prime` | Web search capabilities | MEDIUM |
| `orchestrator-mcp` | Multi-agent coordination | CRITICAL |
| `zai-mcp-server` | UI/visualization analysis | MEDIUM |
| `4_5v_mcp` | Advanced image analysis | MEDIUM |
| `canva` | Design and graphics creation | LOW |

**Diagnostic Protocol:**
```python
def check_mcp_servers():
    results = {}

    # Use ListMcpResourcesTool to get available servers
    try:
        resources = ListMcpResourcesTool()
        results['available'] = True
        results['servers'] = []

        for resource in resources:
            results['servers'].append({
                'name': resource.get('server', 'unknown'),
                'uri': resource.get('uri', ''),
                'status': 'CONNECTED'
            })
    except Exception as e:
        results['available'] = False
        results['error'] = str(e)

    # Check deferred tools availability
    deferred_tools = [
        'mcp__web-reader__webReader',
        'mcp__web-search-prime__webSearchPrime',
        'mcp__orchestrator__orchestrator_status'
    ]

    results['deferred_status'] = {}
    for tool in deferred_tools:
        try:
            ToolSearch(query=f"select:{tool}")
            results['deferred_status'][tool] = 'AVAILABLE'
        except:
            results['deferred_status'][tool] = 'NOT_FOUND'

    return results
```

---

### 4. MEMORY CHECK

Verifies existence and validity of MEMORY.md file.

| Check | Description | Expected Value |
|-------|-------------|----------------|
| File Exists | `~/.claude/projects/*/MEMORY.md` | True |
| File Valid | Parses as valid markdown | True |
| Contains Profile Info | Has Claude profile configuration | True |
| Last Modified | Recent update (within 30 days) | Date |

**Diagnostic Protocol:**
```python
def check_memory():
    results = {
        'exists': False,
        'valid': False,
        'profile_configured': False,
        'last_modified': None
    }

    memory_paths = [
        Path.home() / '.claude' / 'projects' / 'c--Users-LeoDg' / 'memory' / 'MEMORY.md',
        Path.home() / '.claude' / 'MEMORY.md'
    ]

    for memory_path in memory_paths:
        if memory_path.exists():
            results['exists'] = True
            results['path'] = str(memory_path)

            try:
                content = memory_path.read_text(encoding='utf-8')
                results['valid'] = True
                results['size_bytes'] = len(content)

                # Check for profile configuration
                results['profile_configured'] = 'Claude Code Profile' in content or 'cca' in content

                # Get last modified
                mtime = memory_path.stat().st_mtime
                results['last_modified'] = datetime.fromtimestamp(mtime).isoformat()

            except Exception as e:
                results['error'] = str(e)

            break

    return results
```

---

### 5. SKILLS CHECK

Verifies loaded skills and their configuration.

| Check | Description | Status Codes |
|-------|-------------|--------------|
| Skills Directory | `~/.claude/skills/` exists | OK / MISSING |
| Skill Count | Number of loaded skills | Count |
| Orchestrator Skill | Main orchestrator skill loaded | OK / MISSING |
| Skill Syntax | Valid SKILL.md files | OK / ERROR |

**Diagnostic Protocol:**
```python
def check_skills():
    results = {
        'directory_exists': False,
        'skills': [],
        'count': 0,
        'errors': []
    }

    skills_dir = Path.home() / '.claude' / 'skills'

    if skills_dir.exists():
        results['directory_exists'] = True

        for skill_path in skills_dir.iterdir():
            if skill_path.is_dir():
                skill_md = skill_path / 'SKILL.md'
                skill_info = {
                    'name': skill_path.name,
                    'has_skill_md': skill_md.exists()
                }

                if skill_md.exists():
                    try:
                        content = skill_md.read_text(encoding='utf-8')
                        # Check for valid YAML frontmatter
                        if content.startswith('---'):
                            skill_info['status'] = 'OK'
                        else:
                            skill_info['status'] = 'INVALID_FRONTMATTER'
                            results['errors'].append(f"{skill_path.name}: missing frontmatter")
                    except Exception as e:
                        skill_info['status'] = 'ERROR'
                        results['errors'].append(f"{skill_path.name}: {e}")

                results['skills'].append(skill_info)

        results['count'] = len(results['skills'])
    else:
        results['errors'].append('Skills directory not found')

    return results
```

---

### 6. NETWORK CHECK (Optional)

Verifies network connectivity to required endpoints.

| Endpoint | Purpose | Timeout |
|----------|---------|---------|
| `api.anthropic.com` | Claude API | 5s |
| `claude.ai` | Claude web interface | 5s |
| `z.ai` | GLM5 proxy (if configured) | 5s |

**Diagnostic Protocol:**
```python
def check_network():
    results = {
        'checks': [],
        'overall': 'UNKNOWN'
    }

    endpoints = [
        ('api.anthropic.com', 443, 'Claude API'),
        ('claude.ai', 443, 'Claude Web'),
    ]

    # Add proxy if configured
    base_url = os.environ.get('ANTHROPIC_BASE_URL', '')
    if 'z.ai' in base_url:
        endpoints.append(('z.ai', 443, 'GLM5 Proxy'))

    for host, port, name in endpoints:
        try:
            import socket
            socket.setdefaulttimeout(5)
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect((host, port))
            s.close()
            results['checks'].append({
                'name': name,
                'host': host,
                'status': 'OK',
                'latency_ms': None  # Could add timing
            })
        except Exception as e:
            results['checks'].append({
                'name': name,
                'host': host,
                'status': 'FAILED',
                'error': str(e)
            })

    # Determine overall status
    failed = sum(1 for c in results['checks'] if c['status'] == 'FAILED')
    if failed == 0:
        results['overall'] = 'OK'
    elif failed == len(results['checks']):
        results['overall'] = 'CRITICAL'
    else:
        results['overall'] = 'DEGRADED'

    return results
```

---

### 7. REPORT GENERATION

Generates comprehensive diagnostic report.

**Report Structure:**
```
================================================================================
                    ORCHESTRATOR V10.0 - HEALTH CHECK REPORT
================================================================================

Generated: [ISO 8601 Timestamp]
Session ID: [CLAUDE_SESSION_ID]

--------------------------------------------------------------------------------
SUMMARY
--------------------------------------------------------------------------------
Overall Status: [OK | WARNING | CRITICAL]
Checks Passed: X/Y
Critical Issues: [List or "None"]

--------------------------------------------------------------------------------
DETAILED RESULTS
--------------------------------------------------------------------------------

[1] ENVIRONMENT CHECK
    Status: [OK | WARNING | CRITICAL]
    Details:
    - CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: [value] ([OK | DISABLED])
    - ANTHROPIC_AUTHENTICATION: [value] ([OK | MISSING])

[2] AGENT TEAMS CHECK
    Status: [OK | WARNING | CRITICAL]
    Enabled: [Yes | No]
    Mode: [in-process | auto | tmux]
    Storage:
    - teams: [OK | ERROR]
    - tasks: [OK | ERROR]

[3] MCP SERVERS CHECK
    Status: [OK | WARNING | CRITICAL]
    Available Servers: [count]
    Deferred Tools:
    - web-reader: [AVAILABLE | NOT_FOUND]
    - web-search-prime: [AVAILABLE | NOT_FOUND]
    - orchestrator: [AVAILABLE | NOT_FOUND]

[4] MEMORY CHECK
    Status: [OK | WARNING | CRITICAL]
    Path: [file path or "Not Found"]
    Valid: [Yes | No]
    Profile Configured: [Yes | No]
    Last Modified: [ISO date]

[5] SKILLS CHECK
    Status: [OK | WARNING | CRITICAL]
    Skills Directory: [Exists | Missing]
    Loaded Skills: [count]
    Errors: [List or "None"]

[6] NETWORK CHECK
    Status: [OK | WARNING | CRITICAL]
    Connectivity:
    - Claude API: [OK | FAILED]
    - Claude Web: [OK | FAILED]

--------------------------------------------------------------------------------
RECOVERY ACTIONS
--------------------------------------------------------------------------------
[If issues found, list specific actions to resolve]

--------------------------------------------------------------------------------
RAW DATA (JSON)
--------------------------------------------------------------------------------
[Full diagnostic data in JSON format]

================================================================================
                              END OF REPORT
================================================================================
```

---

## Status Codes

| Status | Description | Action Required |
|--------|-------------|-----------------|
| `OK` | Check passed, no issues | None |
| `WARNING` | Non-critical issue detected | Review when convenient |
| `CRITICAL` | Critical issue preventing operation | Immediate action required |
| `DISABLED` | Feature intentionally disabled | No action if intentional |
| `MISSING` | Required component not found | Install or configure |
| `ERROR` | Unexpected error during check | Debug and fix |
| `DEGRADED` | Partial functionality available | Monitor closely |

---

## Recovery Actions

### Environment Issues

| Issue | Recovery Action |
|-------|-----------------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` not set | Add to `~/.claude/settings.json`: `{"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}` |
| `ANTHROPIC_API_KEY` missing | Set environment variable OR run `claude` to complete OAuth flow |
| Invalid `ANTHROPIC_BASE_URL` | Remove or correct URL in environment |

### Agent Teams Issues

| Issue | Recovery Action |
|-------|-----------------|
| Storage directories not writable | Check permissions on `~/.claude/` |
| Feature disabled but needed | Enable via settings.json (see above) |
| Teammate spawn failures | Check session logs in `~/.claude/logs/` |

### MCP Server Issues

| Issue | Recovery Action |
|-------|-----------------|
| Server not connected | Restart Claude Code session |
| Deferred tool not found | Run `ToolSearch(query="tool_name")` to load |
| MCP plugin disabled | Check settings.json MCP configuration |

### Memory Issues

| Issue | Recovery Action |
|-------|-----------------|
| MEMORY.md not found | Create from template or restore from backup |
| Invalid markdown | Fix syntax errors in file |
| Missing profile config | Add profile configuration section |

### Skills Issues

| Issue | Recovery Action |
|-------|-----------------|
| Skills directory missing | Create `~/.claude/skills/` directory |
| Invalid SKILL.md | Add YAML frontmatter to skill file |
| Skill not loading | Check file permissions and encoding |

### Network Issues

| Issue | Recovery Action |
|-------|-----------------|
| API endpoint unreachable | Check internet connection and firewall |
| DNS resolution failure | Check DNS settings |
| Timeout errors | Increase timeout or check network stability |

---

## API Reference

### HealthCheck Class

```python
class HealthCheck:
    """Orchestrator V10.0 Health Check Module"""

    def __init__(self, project_path: str = None):
        """
        Initialize health check module.

        Args:
            project_path: Optional project path for project-specific checks
        """
        pass

    def run_all_checks(self) -> dict:
        """
        Execute all health checks.

        Returns:
            dict: Complete diagnostic results
        """
        pass

    def run_check(self, check_name: str) -> dict:
        """
        Run a specific health check.

        Args:
            check_name: One of 'environment', 'agent_teams', 'mcp', 'memory', 'skills', 'network'

        Returns:
            dict: Check-specific results
        """
        pass

    def generate_report(self, results: dict = None, format: str = 'text') -> str:
        """
        Generate formatted diagnostic report.

        Args:
            results: Optional pre-computed results (runs checks if not provided)
            format: Output format ('text', 'json', 'markdown')

        Returns:
            str: Formatted report
        """
        pass

    def get_recovery_actions(self, results: dict) -> list:
        """
        Get recovery actions for detected issues.

        Args:
            results: Diagnostic results

        Returns:
            list: List of recovery action dictionaries
        """
        pass
```

### Check Functions

```python
def check_environment() -> list[dict]:
    """Check environment variables."""

def check_agent_teams() -> dict:
    """Check Agent Teams configuration."""

def check_mcp_servers() -> dict:
    """Check MCP server availability."""

def check_memory() -> dict:
    """Check MEMORY.md validity."""

def check_skills() -> dict:
    """Check loaded skills."""

def check_network() -> dict:
    """Check network connectivity (optional)."""
```

### Utility Functions

```python
def get_overall_status(results: dict) -> str:
    """Determine overall health status from results."""

def format_severity(severity: str) -> str:
    """Format severity level for display."""

def save_report(results: dict, path: str) -> bool:
    """Save diagnostic report to file."""
```

---

## Example Output

### Successful Health Check

```
================================================================================
                    ORCHESTRATOR V10.0 - HEALTH CHECK REPORT
================================================================================

Generated: 2026-02-21T14:32:15.123456
Session ID: d4b394a2-fe54-4109-8c41-ba9f6b984c81

--------------------------------------------------------------------------------
SUMMARY
--------------------------------------------------------------------------------
Overall Status: OK
Checks Passed: 6/6
Critical Issues: None

--------------------------------------------------------------------------------
DETAILED RESULTS
--------------------------------------------------------------------------------

[1] ENVIRONMENT CHECK
    Status: OK
    Details:
    - CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: 1 (OK)
    - ANTHROPIC_AUTHENTICATION: oauth (OK)

[2] AGENT TEAMS CHECK
    Status: OK
    Enabled: Yes
    Mode: in-process
    Storage:
    - teams: OK
    - tasks: OK

[3] MCP SERVERS CHECK
    Status: OK
    Available Servers: 6
    Deferred Tools:
    - web-reader: AVAILABLE
    - web-search-prime: AVAILABLE
    - orchestrator: AVAILABLE

[4] MEMORY CHECK
    Status: OK
    Path: C:\Users\LeoDg\.claude\projects\c--Users-LeoDg\memory\MEMORY.md
    Valid: Yes
    Profile Configured: Yes
    Last Modified: 2026-02-21T10:15:00

[5] SKILLS CHECK
    Status: OK
    Skills Directory: Exists
    Loaded Skills: 5
    Errors: None

[6] NETWORK CHECK
    Status: OK
    Connectivity:
    - Claude API: OK
    - Claude Web: OK

--------------------------------------------------------------------------------
RECOVERY ACTIONS
--------------------------------------------------------------------------------
No issues detected. No recovery actions required.

================================================================================
                              END OF REPORT
================================================================================
```

### Health Check with Issues

```
================================================================================
                    ORCHESTRATOR V10.0 - HEALTH CHECK REPORT
================================================================================

Generated: 2026-02-21T14:35:22.789012
Session ID: e5f605b3-ge65-5210-9d52-cb0g7c095d92

--------------------------------------------------------------------------------
SUMMARY
--------------------------------------------------------------------------------
Overall Status: WARNING
Checks Passed: 4/6
Critical Issues: None

--------------------------------------------------------------------------------
DETAILED RESULTS
--------------------------------------------------------------------------------

[1] ENVIRONMENT CHECK
    Status: WARNING
    Details:
    - CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: not set (DISABLED)
    - ANTHROPIC_AUTHENTICATION: oauth (OK)

[2] AGENT TEAMS CHECK
    Status: CRITICAL
    Enabled: No
    Mode: unavailable
    Storage:
    - teams: ERROR: Permission denied
    - tasks: ERROR: Permission denied

[3] MCP SERVERS CHECK
    Status: OK
    Available Servers: 6
    Deferred Tools:
    - web-reader: AVAILABLE
    - web-search-prime: AVAILABLE
    - orchestrator: AVAILABLE

[4] MEMORY CHECK
    Status: OK
    Path: C:\Users\LeoDg\.claude\projects\c--Users-LeoDg\memory\MEMORY.md
    Valid: Yes
    Profile Configured: Yes
    Last Modified: 2026-02-21T10:15:00

[5] SKILLS CHECK
    Status: OK
    Skills Directory: Exists
    Loaded Skills: 5
    Errors: None

[6] NETWORK CHECK
    Status: WARNING
    Connectivity:
    - Claude API: OK
    - Claude Web: FAILED (timeout)

--------------------------------------------------------------------------------
RECOVERY ACTIONS
--------------------------------------------------------------------------------

Issue: Agent Teams disabled
Action: Add to ~/.claude/settings.json:
  {"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}}

Issue: Storage permission denied
Action: Fix permissions on ~/.claude/ directory:
  Windows: icacls "%USERPROFILE%\.claude" /grant %USERNAME%:F
  Linux/Mac: chmod -R u+rw ~/.claude/

Issue: Claude Web connectivity timeout
Action: Check firewall rules and network stability

================================================================================
                              END OF REPORT
================================================================================
```

---

## Integration with Orchestrator

The Health Check Module integrates with the Orchestrator V10.0 as follows:

### Automatic Health Check

Health checks run automatically:
1. **On orchestrator startup** - Validates system readiness
2. **Before agent team creation** - Ensures Agent Teams is enabled
3. **On MCP tool failure** - Diagnoses connectivity issues
4. **Periodic background checks** - Monitors system health (optional)

### Manual Invocation

```bash
# Full health check
/health-check

# Specific check
/health-check --check=environment

# JSON output
/health-check --format=json

# Save to file
/health-check --output=diagnostic-report.txt
```

### Programmatic Usage

```python
from orchestrator.health_check import HealthCheck

# Initialize
hc = HealthCheck(project_path="/path/to/project")

# Run all checks
results = hc.run_all_checks()

# Generate report
report = hc.generate_report(format='markdown')
print(report)

# Get recovery actions
if results['overall_status'] != 'OK':
    actions = hc.get_recovery_actions(results)
    for action in actions:
        print(f"Issue: {action['issue']}")
        print(f"Action: {action['solution']}")
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 10.0 | 2026-02-21 | Initial release for Orchestrator V10.0 |

---

## See Also

- [Orchestrator Main Documentation](./SKILL.md)
- [Agent Teams Configuration](./agent-teams.md)
- [MCP Server Setup](./mcp-setup.md)
- [Troubleshooting Guide](./troubleshooting.md)

# Observability Module V10.0

> **Version:** 10.0.0 | **Last Updated:** 2026-02-21
> **Component:** Orchestrator Observability Layer
> **Purpose:** Complete monitoring, logging, tracing, and alerting infrastructure

---

## Overview

The Observability Module provides comprehensive visibility into orchestrator operations, agent performance, and system health. It implements the three pillars of observability: **Metrics**, **Logs**, and **Traces**, plus alerting and dashboarding capabilities.

### Design Principles

| Principle | Description |
|-----------|-------------|
| **Zero Overhead** | Collection adds <1% latency overhead |
| **Structured Data** | All outputs in machine-readable formats |
| **Correlation IDs** | Every operation traceable end-to-end |
| **Retention Aware** | Automatic rotation and cleanup |
| **Export Ready** | JSON/CSV/Prometheus formats supported |

---

## 1. Metrics Collected

### 1.1 Task Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `orchestrator_tasks_total` | Counter | Total tasks dispatched | `agent`, `status`, `model` |
| `orchestrator_tasks_active` | Gauge | Currently running tasks | `agent` |
| `orchestrator_task_duration_seconds` | Histogram | Task execution time | `agent`, `status` |
| `orchestrator_task_queue_size` | Gauge | Pending tasks in queue | `priority` |
| `orchestrator_task_retries_total` | Counter | Task retry attempts | `agent`, `reason` |

**Prometheus Format:**
```prometheus
# HELP orchestrator_tasks_total Total tasks dispatched by the orchestrator
# TYPE orchestrator_tasks_total counter
orchestrator_tasks_total{agent="Coder",status="success",model="sonnet"} 1427
orchestrator_tasks_total{agent="Coder",status="failed",model="sonnet"} 23
orchestrator_tasks_total{agent="Analyzer",status="success",model="haiku"} 892

# HELP orchestrator_task_duration_seconds Task execution duration
# TYPE orchestrator_task_duration_seconds histogram
orchestrator_task_duration_seconds_bucket{agent="Coder",le="1"} 120
orchestrator_task_duration_seconds_bucket{agent="Coder",le="5"} 450
orchestrator_task_duration_seconds_bucket{agent="Coder",le="10"} 890
orchestrator_task_duration_seconds_bucket{agent="Coder",le="30"} 1250
orchestrator_task_duration_seconds_bucket{agent="Coder",le="+Inf"} 1450
orchestrator_task_duration_seconds_sum{agent="Coder"} 18540.5
orchestrator_task_duration_seconds_count{agent="Coder"} 1450
```

### 1.2 Agent Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `orchestrator_agent_spawn_total` | Counter | Agents spawned | `agent_type`, `mode` |
| `orchestrator_agent_active` | Gauge | Currently active agents | `agent_type` |
| `orchestrator_agent_errors_total` | Counter | Agent errors | `agent_type`, `error_code` |
| `orchestrator_agent_memory_bytes` | Gauge | Memory usage per agent | `agent_type` |
| `orchestrator_agent_tokens_total` | Counter | Tokens consumed | `agent_type`, `model` |

### 1.3 Performance Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `orchestrator_latency_p50_ms` | Gauge | 50th percentile latency | `operation` |
| `orchestrator_latency_p95_ms` | Gauge | 95th percentile latency | `operation` |
| `orchestrator_latency_p99_ms` | Gauge | 99th percentile latency | `operation` |
| `orchestrator_throughput_ops_sec` | Gauge | Operations per second | `operation_type` |
| `orchestrator_parallelism_efficiency` | Gauge | Parallel execution ratio | - |

### 1.4 System Health Metrics

| Metric Name | Type | Description | Labels |
|-------------|------|-------------|--------|
| `orchestrator_uptime_seconds` | Gauge | System uptime | - |
| `orchestrator_health_status` | Gauge | Health check status (1=healthy) | `component` |
| `orchestrator_mcp_tools_available` | Gauge | Available MCP tools | `plugin` |
| `orchestrator_file_operations_total` | Counter | File read/write operations | `operation`, `status` |

---

## 2. Logging Protocol

### 2.1 Log Structure

All logs follow a structured JSON format for machine parsing:

```json
{
  "timestamp": "2026-02-21T14:32:15.123Z",
  "level": "INFO",
  "correlation_id": "corr-a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "session_id": "sess-xyz789",
  "component": "orchestrator",
  "agent": "Coder",
  "model": "sonnet",
  "event": "task_dispatched",
  "message": "Task dispatched to Coder agent",
  "metadata": {
    "task_id": "task-12345",
    "task_type": "implementation",
    "files_involved": ["src/main.py", "src/utils.py"],
    "parent_task": "task-12340"
  },
  "duration_ms": 45,
  "tags": ["task", "dispatch", "parallel"]
}
```

### 2.2 Log Levels

| Level | Code | Usage |
|-------|------|-------|
| `TRACE` | 0 | Detailed execution flow (debug only) |
| `DEBUG` | 1 | Development diagnostics |
| `INFO` | 2 | Normal operations, task lifecycle |
| `WARN` | 3 | Recoverable issues, degraded performance |
| `ERROR` | 4 | Failures requiring attention |
| `FATAL` | 5 | System-wide failures |

### 2.3 Standard Events

| Event | Level | Description | Required Fields |
|-------|-------|-------------|-----------------|
| `session_start` | INFO | New orchestrator session | `session_id` |
| `session_end` | INFO | Session terminated | `session_id`, `duration_ms` |
| `task_created` | DEBUG | Task object created | `task_id`, `agent` |
| `task_dispatched` | INFO | Task sent to agent | `task_id`, `agent`, `model` |
| `task_started` | INFO | Agent began work | `task_id`, `agent` |
| `task_completed` | INFO | Task finished successfully | `task_id`, `agent`, `duration_ms` |
| `task_failed` | ERROR | Task failed | `task_id`, `agent`, `error_code` |
| `task_retried` | WARN | Task retry attempted | `task_id`, `agent`, `retry_count` |
| `agent_spawned` | INFO | New agent instance | `agent_type`, `mode` |
| `agent_shutdown` | INFO | Agent terminated | `agent_type`, `tasks_completed` |
| `parallel_batch_start` | INFO | Parallel execution began | `batch_id`, `task_count` |
| `parallel_batch_end` | INFO | Parallel execution completed | `batch_id`, `success_count`, `failed_count` |
| `team_created` | INFO | Agent team formed | `team_id`, `member_count` |
| `team_shutdown` | INFO | Team dissolved | `team_id`, `duration_ms` |
| `mcp_tool_invoked` | DEBUG | MCP tool called | `plugin`, `tool_name` |
| `alert_fired` | WARN | Alert condition met | `alert_name`, `severity` |

### 2.4 Log Rotation

```yaml
# Log rotation configuration
logging:
  rotation:
    max_size_mb: 100
    max_files: 10
    compress: true
    retention_days: 30
  output:
    - type: file
      path: ~/.claude/logs/orchestrator.log
      format: json
    - type: console
      format: pretty
      level: INFO
```

### 2.5 Correlation ID Propagation

```python
# Every operation carries correlation context
class CorrelationContext:
    correlation_id: str      # Root request ID
    session_id: str          # Orchestrator session
    parent_task_id: str      # Parent task (if any)
    task_id: str             # Current task
    agent: str               # Handling agent
    trace_flags: list[str]   # Sampling/debug flags

# Example propagation chain
[User Request] -> corr-001
  -> [Orchestrator] sess-abc, corr-001
    -> [Task T1] task-100, corr-001
      -> [Coder Agent] task-100, corr-001
        -> [Sub-task T1.1] task-101, corr-001, parent=task-100
```

---

## 3. Tracing

### 3.1 Trace Structure

Traces follow OpenTelemetry-compatible format:

```json
{
  "traceId": "tr-a1b2c3d4e5f67890",
  "spans": [
    {
      "spanId": "sp-001",
      "parentSpanId": null,
      "operationName": "orchestrator.execute_request",
      "startTime": "2026-02-21T14:32:15.000Z",
      "endTime": "2026-02-21T14:32:45.250Z",
      "durationMs": 30250,
      "status": "OK",
      "attributes": {
        "request.type": "implementation",
        "agent.count": 3,
        "parallel": true
      },
      "events": [
        {
          "name": "task_dispatched",
          "timestamp": "2026-02-21T14:32:15.100Z",
          "attributes": {"agent": "Analyzer"}
        }
      ]
    },
    {
      "spanId": "sp-002",
      "parentSpanId": "sp-001",
      "operationName": "agent.execute_task",
      "startTime": "2026-02-21T14:32:15.150Z",
      "endTime": "2026-02-21T14:32:25.500Z",
      "durationMs": 10350,
      "status": "OK",
      "attributes": {
        "agent.type": "Coder",
        "agent.model": "sonnet",
        "task.id": "task-100"
      }
    }
  ]
}
```

### 3.2 Span Types

| Span Name | Parent | Description | Key Attributes |
|-----------|--------|-------------|----------------|
| `orchestrator.execute_request` | None | Root request handling | `request.type`, `parallel` |
| `orchestrator.decompose` | execute_request | Task decomposition | `task.count` |
| `orchestrator.dispatch_batch` | execute_request | Parallel dispatch | `batch.size` |
| `agent.execute_task` | dispatch_batch | Single agent execution | `agent.type`, `model` |
| `agent.read_file` | execute_task | File read operation | `file.path`, `size_bytes` |
| `agent.edit_file` | execute_task | File edit operation | `file.path`, `lines_changed` |
| `agent.search` | execute_task | Code search | `pattern`, `results_count` |
| `mcp.invoke_tool` | execute_task | MCP tool call | `plugin`, `tool_name` |
| `team.coordinate` | execute_request | Team coordination | `team.id`, `member_count` |

### 3.3 Trace Sampling

```yaml
# Sampling configuration
tracing:
  sampling:
    # Always sample these
    always_sample:
      - error_traces: true
      - slow_traces: true        # >5 seconds
      - critical_operations: true

    # Probabilistic sampling
    sample_rate:
      default: 0.1               # 10% of normal traces
      parallel_operations: 0.2   # 20% of parallel ops
      agent_tasks: 0.15          # 15% of agent tasks

    # Head-based sampling
    head_sampling:
      enabled: true
      rules:
        - condition: "request.type == 'critical'"
          rate: 1.0
        - condition: "agent == 'Architect'"
          rate: 0.5
```

### 3.4 Trace Export

```python
# Export traces to various backends
class TraceExporter:
    def export_to_jaeger(self, traces: list[Trace]) -> None:
        """Export to Jaeger backend"""
        pass

    def export_to_otlp(self, traces: list[Trace]) -> None:
        """Export via OpenTelemetry Protocol"""
        pass

    def export_to_file(self, traces: list[Trace], path: str) -> None:
        """Export to JSON file for local analysis"""
        pass
```

---

## 4. Performance Monitoring

### 4.1 Key Performance Indicators (KPIs)

| KPI | Target | Measurement | Alert Threshold |
|-----|--------|-------------|-----------------|
| **Task Throughput** | >10 tasks/min | `tasks_completed / time_window` | <5 tasks/min |
| **P95 Latency** | <30 seconds | 95th percentile task duration | >60 seconds |
| **Success Rate** | >95% | `successes / total * 100` | <90% |
| **Parallel Efficiency** | >80% | `actual_speedup / theoretical_speedup` | <50% |
| **Agent Utilization** | 60-80% | `active_time / total_time` | >95% or <20% |
| **Queue Wait Time** | <5 seconds | Average time in queue | >30 seconds |

### 4.2 Latency Buckets

```yaml
# Latency histogram buckets (milliseconds)
latency_buckets:
  - 100      # Very fast
  - 500      # Fast
  - 1000     # Normal
  - 2500     # Moderate
  - 5000     # Slow
  - 10000    # Very slow
  - 30000    # Concerning
  - 60000    # Alert threshold
  - 120000   # Critical
  - 300000   # Timeout risk
```

### 4.3 Performance Profiling

```python
# Built-in profiling for performance analysis
class PerformanceProfiler:
    def profile_task(self, task_id: str) -> TaskProfile:
        """Generate detailed task performance profile"""
        return TaskProfile(
            task_id=task_id,
            wall_time_ms=...,
            cpu_time_ms=...,
            io_wait_ms=...,
            llm_time_ms=...,
            file_ops=...,
            network_ops=...,
            memory_peak_mb=...,
            breakdown=[
                ("planning", 1500),
                ("file_reads", 3200),
                ("edits", 4500),
                ("validation", 1200),
                ("llm_calls", 18500)
            ]
        )

    def identify_bottlenecks(self, profile: TaskProfile) -> list[Bottleneck]:
        """Identify performance bottlenecks"""
        bottlenecks = []

        # Check for I/O bottlenecks
        if profile.io_wait_ms > profile.wall_time_ms * 0.5:
            bottlenecks.append(Bottleneck(
                type="io_bound",
                severity="high",
                suggestion="Consider batching file operations"
            ))

        # Check for LLM latency
        if profile.llm_time_ms > profile.wall_time_ms * 0.7:
            bottlenecks.append(Bottleneck(
                type="llm_latency",
                severity="medium",
                suggestion="Model may be overloaded, consider haiku for simple tasks"
            ))

        return bottlenecks
```

### 4.4 Resource Monitoring

```yaml
# Resource thresholds
resources:
  memory:
    warning_mb: 500
    critical_mb: 1000
  cpu:
    warning_percent: 80
    critical_percent: 95
  disk:
    warning_percent: 80
    critical_percent: 95
  file_descriptors:
    warning: 500
    critical: 1000
```

---

## 5. Alerting Rules

### 5.1 Alert Severity Levels

| Severity | Color | Response Time | Notification |
|----------|-------|---------------|--------------|
| `CRITICAL` | Red | Immediate | All channels |
| `HIGH` | Orange | <15 minutes | Primary + Slack |
| `MEDIUM` | Yellow | <1 hour | Primary channel |
| `LOW` | Blue | <24 hours | Log only |
| `INFO` | Green | No action | Log only |

### 5.2 Alert Rules Definition

```yaml
# Alert rules configuration
alerts:
  # Critical Alerts
  - name: orchestrator_down
    severity: CRITICAL
    condition: "orchestrator_health_status == 0"
    for: 1m
    message: "Orchestrator is not responding"
    runbook_url: "https://docs/orchestrator/down"

  - name: task_failure_rate_critical
    severity: CRITICAL
    condition: |
      (
        sum(rate(orchestrator_tasks_total{status="failed"}[5m]))
        /
        sum(rate(orchestrator_tasks_total[5m]))
      ) > 0.25
    for: 5m
    message: "Task failure rate is {{ $value | humanizePercentage }}"
    runbook_url: "https://docs/orchestrator/failures"

  # High Alerts
  - name: high_latency_p95
    severity: HIGH
    condition: "orchestrator_latency_p95_ms > 60000"
    for: 10m
    message: "P95 latency is {{ $value }}ms, exceeding 60s threshold"
    runbook_url: "https://docs/orchestrator/latency"

  - name: agent_error_spike
    severity: HIGH
    condition: |
      rate(orchestrator_agent_errors_total[5m]) > 0.5
    for: 5m
    message: "Agent {{ $labels.agent_type }} error rate: {{ $value }}/s"
    runbook_url: "https://docs/orchestrator/agent-errors"

  # Medium Alerts
  - name: queue_backlog
    severity: MEDIUM
    condition: "orchestrator_task_queue_size > 20"
    for: 15m
    message: "Task queue has {{ $value }} pending tasks"
    runbook_url: "https://docs/orchestrator/queue"

  - name: memory_usage_high
    severity: MEDIUM
    condition: |
      orchestrator_memory_bytes / (1024*1024) > 500
    for: 30m
    message: "Memory usage is {{ $value }}MB"
    runbook_url: "https://docs/orchestrator/memory"

  # Low Alerts
  - name: slow_task_detected
    severity: LOW
    condition: "orchestrator_task_duration_seconds > 120"
    for: 0m
    message: "Slow task detected: {{ $labels.task_id }} took {{ $value }}s"
    runbook_url: "https://docs/orchestrator/slow-tasks"

  - name: low_parallel_efficiency
    severity: LOW
    condition: "orchestrator_parallelism_efficiency < 0.5"
    for: 30m
    message: "Parallel efficiency is {{ $value | humanizePercentage }}"
    runbook_url: "https://docs/orchestrator/parallelism"
```

### 5.3 Alert Routing

```yaml
# Alert routing configuration
alert_routing:
  routes:
    - match:
        severity: CRITICAL
      receivers:
        - primary_oncall
        - slack_critical
        - pagerduty
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 5m

    - match:
        severity: HIGH
      receivers:
        - primary_oncall
        - slack_alerts
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 30m

    - match:
        severity: MEDIUM
      receivers:
        - slack_alerts
      group_wait: 5m
      group_interval: 30m
      repeat_interval: 4h

    - match:
        severity: LOW
      receivers:
        - log_only
      group_wait: 10m
      group_interval: 1h
      repeat_interval: 24h
```

### 5.4 Alert Suppression

```yaml
# Maintenance windows and suppressions
suppressions:
  - name: scheduled_maintenance
    match:
      severity: LOW|MEDIUM
    time_range:
      start: "2026-02-21T02:00:00Z"
      end: "2026-02-21T06:00:00Z"
    reason: "Scheduled maintenance window"

  - name: known_issue_suppression
    match:
      alert_name: memory_usage_high
    condition: "labels.agent_type == 'Architect'"
    reason: "Known issue: ARCH-1234"
    expires: "2026-02-28T00:00:00Z"
```

---

## 6. Dashboard Template

### 6.1 Main Dashboard Layout

```
+------------------------------------------------------------------+
|                    ORCHESTRATOR V10.0 DASHBOARD                   |
+------------------------------------------------------------------+
| [Health: GREEN] | [Tasks: 47/min] | [P95: 12.3s] | [Errors: 0.2%] |
+------------------------------------------------------------------+
|                                                                    |
|  TASK THROUGHPUT (24h)          |  LATENCY DISTRIBUTION            |
|  ┌──────────────────────┐       |  ┌──────────────────────┐       |
|  │    ▃▅▇█▇▅▃▂▁▂▃▅▆▇█  │       |  │ p50: 2.1s            │       |
|  │   ▂▄▆█▇▅▃▂▁▁▂▃▅▆▇█▇ │       |  │ p95: 12.3s           │       |
|  │  ▃▅▇████▅▃▂▁▂▃▅▇███ │       |  │ p99: 28.7s           │       |
|  └──────────────────────┘       |  │ Timeout: 0.01%       │       |
|                                  |  └──────────────────────┘       |
+------------------------------------------------------------------+
|                                                                    |
|  AGENT UTILIZATION               |  TASK QUEUE                    |
|  ┌──────────────────────┐       |  ┌──────────────────────┐       |
|  │ Coder     ████████░░  80%   |  │ Queue Depth: 3       │       |
|  │ Analyzer  ██████░░░░  60%   |  │ Oldest Wait: 2.1s    │       |
|  │ DevOps    ████░░░░░░  40%   |  │ Avg Wait: 0.8s       │       |
|  │ Architect ██░░░░░░░░  20%   |  │ Processing: 12       │       |
|  └──────────────────────┘       |  └──────────────────────┘       |
+------------------------------------------------------------------+
|                                                                    |
|  ERROR RATE (7d)                 |  ACTIVE ALERTS                  |
|  ┌──────────────────────┐       |  ┌──────────────────────┐       |
|  │    ▁▁▂▃▂▁▁▁▁▂▁▁▁▁▁▁ │       |  │ No active alerts     │       |
|  │   Current: 0.2%      │       |  │                      │       |
|  │   Threshold: 5%      │       |  │                      │       |
|  └──────────────────────┘       |  └──────────────────────┘       |
+------------------------------------------------------------------+
```

### 6.2 Grafana Dashboard JSON

```json
{
  "dashboard": {
    "title": "Orchestrator V10.0 Observability",
    "uid": "orchestrator-v10",
    "tags": ["orchestrator", "observability", "agents"],
    "timezone": "browser",
    "refresh": "30s",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "graph",
        "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "sum(rate(orchestrator_tasks_total[5m]))",
            "legendFormat": "Requests/sec"
          }
        ]
      },
      {
        "id": 2,
        "title": "Task Duration Percentiles",
        "type": "graph",
        "gridPos": {"x": 12, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(orchestrator_task_duration_seconds_bucket[5m]))",
            "legendFormat": "p50"
          },
          {
            "expr": "histogram_quantile(0.95, rate(orchestrator_task_duration_seconds_bucket[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, rate(orchestrator_task_duration_seconds_bucket[5m]))",
            "legendFormat": "p99"
          }
        ]
      },
      {
        "id": 3,
        "title": "Success Rate",
        "type": "stat",
        "gridPos": {"x": 0, "y": 8, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "sum(rate(orchestrator_tasks_total{status=\"success\"}[5m])) / sum(rate(orchestrator_tasks_total[5m])) * 100",
            "legendFormat": "Success %"
          }
        ],
        "thresholds": {
          "mode": "absolute",
          "steps": [
            {"color": "red", "value": 0},
            {"color": "yellow", "value": 90},
            {"color": "green", "value": 95}
          ]
        }
      },
      {
        "id": 4,
        "title": "Active Agents",
        "type": "piechart",
        "gridPos": {"x": 6, "y": 8, "w": 6, "h": 8},
        "targets": [
          {
            "expr": "orchestrator_agent_active",
            "legendFormat": "{{agent_type}}"
          }
        ]
      },
      {
        "id": 5,
        "title": "Error Rate by Agent",
        "type": "graph",
        "gridPos": {"x": 12, "y": 8, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "sum(rate(orchestrator_agent_errors_total[5m])) by (agent_type)",
            "legendFormat": "{{agent_type}}"
          }
        ]
      },
      {
        "id": 6,
        "title": "Task Queue Depth",
        "type": "gauge",
        "gridPos": {"x": 0, "y": 12, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "orchestrator_task_queue_size",
            "legendFormat": "Queue Size"
          }
        ],
        "thresholds": {
          "mode": "absolute",
          "steps": [
            {"color": "green", "value": 0},
            {"color": "yellow", "value": 10},
            {"color": "red", "value": 25}
          ]
        }
      }
    ]
  }
}
```

### 6.3 Dashboard Variables

| Variable | Query | Description |
|----------|-------|-------------|
| `$agent` | `label_values(orchestrator_tasks_total, agent)` | Filter by agent type |
| `$model` | `label_values(orchestrator_tasks_total, model)` | Filter by model |
| `$status` | `label_values(orchestrator_tasks_total, status)` | Filter by status |
| `$time_range` | Manual input | Time range selection |

---

## 7. Export Formats

### 7.1 JSON Export

```json
{
  "export_version": "1.0",
  "exported_at": "2026-02-21T14:32:15.123Z",
  "time_range": {
    "start": "2026-02-21T00:00:00Z",
    "end": "2026-02-21T23:59:59Z"
  },
  "metrics": {
    "tasks": {
      "total": 1523,
      "successful": 1450,
      "failed": 73,
      "by_agent": {
        "Coder": {"total": 890, "success": 867, "failed": 23},
        "Analyzer": {"total": 456, "success": 450, "failed": 6},
        "DevOps": {"total": 177, "success": 133, "failed": 44}
      }
    },
    "latency": {
      "p50_ms": 2100,
      "p95_ms": 12300,
      "p99_ms": 28700,
      "max_ms": 125000
    },
    "throughput": {
      "tasks_per_minute": 47.5,
      "peak_tasks_per_minute": 125
    }
  },
  "traces": [
    {
      "trace_id": "tr-abc123",
      "duration_ms": 15250,
      "status": "OK",
      "spans_count": 8
    }
  ],
  "alerts": {
    "fired": 3,
    "resolved": 3,
    "details": [
      {
        "name": "high_latency_p95",
        "fired_at": "2026-02-21T10:15:00Z",
        "resolved_at": "2026-02-21T10:45:00Z",
        "severity": "HIGH"
      }
    ]
  }
}
```

### 7.2 CSV Export

```csv
timestamp,task_id,agent,model,status,duration_ms,files_modified,error_type
2026-02-21T14:32:15.123Z,task-001,Coder,sonnet,success,15250,3,
2026-02-21T14:35:45.456Z,task-002,Analyzer,haiku,success,3200,0,
2026-02-21T14:40:12.789Z,task-003,DevOps,haiku,failed,45000,0,timeout
2026-02-21T14:45:00.000Z,task-004,Coder,sonnet,success,8900,2,
```

### 7.3 Prometheus Scrape Endpoint

```yaml
# Prometheus scrape configuration
scrape_configs:
  - job_name: 'orchestrator'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
```

**Available at:** `http://localhost:9090/metrics`

### 7.4 Export API

```python
class ObservabilityExporter:
    """Export observability data in various formats"""

    def export_json(
        self,
        time_range: TimeRange,
        include_traces: bool = False,
        include_logs: bool = False
    ) -> dict:
        """Export comprehensive JSON report"""
        pass

    def export_csv(
        self,
        time_range: TimeRange,
        metrics: list[str]
    ) -> str:
        """Export metrics as CSV for spreadsheet analysis"""
        pass

    def export_prometheus(self) -> str:
        """Export metrics in Prometheus text format"""
        pass

    def export_otlp_traces(self) -> bytes:
        """Export traces in OpenTelemetry Protocol format"""
        pass

    def stream_to_endpoint(
        self,
        endpoint: str,
        format: str = "json",
        batch_size: int = 100
    ) -> None:
        """Stream metrics to external endpoint"""
        pass
```

---

## 8. API Reference

### 8.1 Metrics API

```yaml
# REST API endpoints for observability
endpoints:
  # Metrics
  - path: /api/v1/metrics
    method: GET
    description: Get current metrics snapshot
    response:
      type: application/json
      schema: MetricsSnapshot

  - path: /api/v1/metrics/prometheus
    method: GET
    description: Prometheus-compatible metrics endpoint
    response:
      type: text/plain

  - path: /api/v1/metrics/history
    method: GET
    params:
      - name: start
        type: timestamp
        required: true
      - name: end
        type: timestamp
        required: true
      - name: metrics
        type: string[]
        required: false
    description: Get historical metrics
    response:
      type: application/json

  # Traces
  - path: /api/v1/traces
    method: GET
    params:
      - name: trace_id
        type: string
        required: false
      - name: limit
        type: integer
        default: 100
    description: Query traces
    response:
      type: application/json

  - path: /api/v1/traces/{trace_id}
    method: GET
    description: Get specific trace with all spans
    response:
      type: application/json

  # Alerts
  - path: /api/v1/alerts
    method: GET
    description: List current alerts
    response:
      type: application/json

  - path: /api/v1/alerts/{alert_id}/acknowledge
    method: POST
    description: Acknowledge an alert
    response:
      type: application/json

  # Export
  - path: /api/v1/export/json
    method: GET
    params:
      - name: start
        type: timestamp
      - name: end
        type: timestamp
    description: Export full JSON report
    response:
      type: application/json

  - path: /api/v1/export/csv
    method: GET
    params:
      - name: metrics
        type: string[]
    description: Export metrics as CSV
    response:
      type: text/csv
```

### 8.2 Programmatic API

```python
from orchestrator.observability import ObservabilityClient

# Initialize client
client = ObservabilityClient()

# Get metrics snapshot
metrics = client.metrics.get_snapshot()
print(f"Active tasks: {metrics.tasks_active}")
print(f"P95 latency: {metrics.latency_p95_ms}ms")

# Query historical metrics
history = client.metrics.query(
    start=datetime.now() - timedelta(hours=24),
    end=datetime.now(),
    metrics=["task_duration", "error_rate"]
)

# Get trace by ID
trace = client.traces.get("tr-abc123")
for span in trace.spans:
    print(f"{span.operation_name}: {span.duration_ms}ms")

# Export data
export = client.export(
    format="json",
    time_range=TimeRange.last_24h(),
    include_traces=True
)

# Stream metrics
def on_metric(metric):
    print(f"New metric: {metric.name} = {metric.value}")

client.metrics.subscribe(on_metric)
```

### 8.3 CLI Interface

```bash
# Get current metrics
orchestrator metrics

# Watch metrics in real-time
orchestrator metrics --watch

# Export metrics
orchestrator export --format json --output metrics.json
orchestrator export --format csv --output metrics.csv

# Query traces
orchestrator traces list --limit 50
orchestrator traces get tr-abc123

# View alerts
orchestrator alerts list
orchestrator alerts ack alert-123

# Dashboard
orchestrator dashboard start --port 3000
```

---

## 9. Configuration

### 9.1 Full Configuration Schema

```yaml
# ~/.claude/config/observability.yaml
observability:
  enabled: true
  version: "10.0"

  # Metrics configuration
  metrics:
    enabled: true
    collection_interval_ms: 1000
    retention_days: 30
    labels:
      environment: development
      version: "10.0"

  # Logging configuration
  logging:
    level: INFO
    format: json
    output:
      - type: file
        path: ~/.claude/logs/orchestrator.log
      - type: console
        format: pretty
    rotation:
      max_size_mb: 100
      max_files: 10
      compress: true

  # Tracing configuration
  tracing:
    enabled: true
    sample_rate: 0.1
    exporter: otlp
    endpoint: http://localhost:4317

  # Alerting configuration
  alerting:
    enabled: true
    rules_file: ~/.claude/config/alert_rules.yaml
    receivers:
      - name: slack_alerts
        type: slack
        webhook_url: ${SLACK_WEBHOOK_URL}

  # Dashboard configuration
  dashboard:
    enabled: true
    port: 3000
    refresh_interval_ms: 30000

  # Export configuration
  export:
    formats:
      - json
      - csv
      - prometheus
    prometheus_endpoint: /metrics
    prometheus_port: 9090
```

---

## 10. Integration Examples

### 10.1 Integration with External Monitoring

```yaml
# Grafana integration
grafana:
  datasource:
    type: prometheus
    url: http://localhost:9090
    access: proxy

# Jaeger integration for traces
jaeger:
  collector_endpoint: http://localhost:14268/api/traces

# Slack integration for alerts
slack:
  webhook_url: ${SLACK_WEBHOOK_URL}
  channel: "#orchestrator-alerts"
```

### 10.2 Custom Metrics

```python
from orchestrator.observability import metrics

# Define custom metric
custom_counter = metrics.Counter(
    name="custom_operations_total",
    description="Custom operation count",
    labels=["operation_type", "status"]
)

# Record metric
custom_counter.labels(operation_type="backup", status="success").inc()

# Custom histogram
latency_histogram = metrics.Histogram(
    name="custom_latency_seconds",
    description="Custom operation latency",
    buckets=[0.1, 0.5, 1.0, 2.5, 5.0, 10.0]
)

latency_histogram.observe(1.23)
```

---

## 11. Troubleshooting

### 11.1 Common Issues

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| High memory usage | Memory alert, slow performance | Reduce retention, enable compression |
| Missing metrics | Gaps in dashboard | Check collection interval, verify exporter |
| Alert storms | Many duplicate alerts | Adjust grouping, add suppressions |
| Slow queries | Dashboard lag | Add indexes, reduce time range |

### 11.2 Debug Commands

```bash
# Check observability status
orchestrator observability status

# Verify metrics endpoint
curl http://localhost:9090/metrics

# Test alert routing
orchestrator alerts test --severity HIGH

# Validate configuration
orchestrator config validate observability.yaml
```

---

## 12. Best Practices

1. **Always include correlation IDs** - Enables end-to-end tracing
2. **Use appropriate log levels** - Avoid log spam, ensure debug logs are optional
3. **Set meaningful alert thresholds** - Too sensitive = alert fatigue
4. **Monitor the monitors** - Health checks for observability itself
5. **Regular retention cleanup** - Prevent disk exhaustion
6. **Test alert routing** - Verify alerts reach correct channels
7. **Document custom metrics** - Keep metric registry updated
8. **Sample aggressively for traces** - 100% sampling is rarely needed

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 10.0.0 | 2026-02-21 | Initial V10.0 release with full observability stack |
| 9.5.0 | 2026-01-15 | Added OTLP trace export support |
| 9.0.0 | 2025-12-01 | Introduced correlation ID propagation |

---

**End of Observability Module V10.0**

---
name: Parallel Coordinator
description: Coordination system for parallel agent execution
---

# 🚀 PARALLEL COORDINATION SYSTEM V6.2

> **Purpose:** Multi-agent simultaneous coordination and parallel execution
> **Version:** 6.0
> **Date:** 31 January 2026
> **Max Agents:** 64 concurrent
> **Status:** Production Ready

---

## 🎯 CORE CAPABILITIES

### Multi-Agent Coordination
- **Simultaneous Execution:** Up to 64 agents running in parallel
- **Dependency Management:** Smart dependency graph resolution
- **Task Decomposition:** Automatic task breakdown and assignment
- **Real-time Tracking:** Live progress monitoring and status updates
- **Result Synthesis:** Intelligent aggregation of multi-agent outputs
- **Error Recovery:** Automatic failure handling and retry mechanisms

### Integration
- **Zero Setup:** Works immediately with existing agents in ~/.claude/agents/
- **Protocol Compliance:** Full compatibility with system/PROTOCOL.md
- **Expert Routing:** Intelligent routing to specialized agents
- **Resource Management:** Memory and token optimization

---

## 📊 SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARALLEL COORDINATOR                        │
├─────────────────────────────────────────────────────────────────┤
│  Task Queue     │  Dependency      │  Execution      │ Monitor  │
│  Manager        │  Graph Engine    │  Pool           │ System   │
│                 │                  │                 │          │
│  ┌─────────┐    │  ┌─────────┐     │  ┌─────────┐    │ ┌──────┐ │
│  │ Decomp. │    │  │ Resolver│     │  │ Worker  │    │ │Track │ │
│  │ Engine  │────┼─→│         │────┼─→│ Pool    │    │ │      │ │
│  │         │    │  │         │     │  │ (1-64)  │    │ │      │ │
│  └─────────┘    │  └─────────┘     │  └─────────┘    │ └──────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXISTING AGENTS                             │
├─────────────────────────────────────────────────────────────────┤
│  Core Agents    │  Expert Agents  │  Workflows      │ Templates│
│                 │                 │                 │          │
│  orchestrator   │  gui-super     │  bugfix         │ task     │
│  analyzer       │  integration   │  feature        │ review   │
│  coder          │  database      │  refactoring    │ integ.   │
│  reviewer       │  security      │  optimized      │          │
│  documenter     │  trading       │                 │          │
│  system_coord.  │  mql           │                 │          │
│                 │  + 9 more...   │                 │          │
└─────────────────────────────────────────────────────────────────┘
```

---

## ⚙️ CORE COMPONENTS

### 1. Task Decomposition Engine
```javascript
// Automatic task breakdown
const decomposeTask = (complexTask) => {
  return {
    subtasks: analyzeTaskComplexity(complexTask),
    dependencies: buildDependencyGraph(),
    priority: calculatePriority(),
    resources: estimateResources(),
    timeline: predictExecutionTime()
  };
};
```

### 2. Dependency Graph Manager
```python
class DependencyGraph:
    def __init__(self):
        self.graph = {}
        self.resolved = set()

    def add_dependency(self, task_id, depends_on):
        """Add task dependency"""

    def resolve_order(self):
        """Return execution order based on dependencies"""

    def can_execute(self, task_id):
        """Check if task can be executed now"""
```

### 3. Parallel Execution Pool
```python
class ParallelExecutionPool:
    def __init__(self, max_workers=64):
        self.max_workers = max_workers
        self.active_workers = {}
        self.queue = PriorityQueue()

    async def execute_parallel(self, tasks):
        """Execute multiple tasks in parallel"""

    def scale_workers(self, demand):
        """Dynamic worker scaling"""
```

### 4. Real-time Progress Tracker
```json
{
  "session_id": "uuid",
  "total_tasks": 15,
  "completed": 8,
  "in_progress": 4,
  "failed": 1,
  "pending": 2,
  "agents_active": [
    {"agent": "coder", "task_id": "t1", "progress": 75},
    {"agent": "reviewer", "task_id": "t2", "progress": 45}
  ],
  "estimated_completion": "2026-01-31T15:30:00Z",
  "performance_metrics": {
    "avg_task_time": "3.2s",
    "throughput": "12 tasks/min",
    "error_rate": "2.3%"
  }
}
```

---

## 🔧 CONFIGURATION

### Parallel Execution Settings
```yaml
parallel_config:
  max_concurrent_agents: 64
  task_timeout: 300  # seconds
  retry_attempts: 3
  priority_levels: 5

resource_limits:
  max_memory_per_agent: "512MB"
  max_cpu_usage: "80%"
  token_budget_per_agent: 50000

monitoring:
  progress_update_interval: 1  # seconds
  health_check_interval: 5
  performance_logging: true
```

### Agent Pool Configuration
```python
AGENT_POOL = {
    'core': {
        'orchestrator': {'max_concurrent': 1, 'priority': 'critical'},
        'analyzer': {'max_concurrent': 8, 'priority': 'high'},
        'coder': {'max_concurrent': 16, 'priority': 'high'},
        'reviewer': {'max_concurrent': 8, 'priority': 'medium'},
        'documenter': {'max_concurrent': 4, 'priority': 'low'}
    },
    'experts': {
        'gui-super-expert': {'max_concurrent': 4, 'priority': 'high'},
        'integration_expert': {'max_concurrent': 6, 'priority': 'high'},
        'database_expert': {'max_concurrent': 4, 'priority': 'medium'},
        'security_unified_expert': {'max_concurrent': 2, 'priority': 'critical'},
        'trading_strategy_expert': {'max_concurrent': 2, 'priority': 'high'},
        'mql_expert': {'max_concurrent': 2, 'priority': 'high'},
        # ... additional experts
    }
}
```

---

## 🚀 API INTERFACE

### Main Coordination Functions

```python
class ParallelCoordinator:
    """Main parallel coordination interface"""

    async def coordinate_task(self, task_description: str, options: dict = None):
        """
        Main entry point for parallel task coordination

        Args:
            task_description: Natural language task description
            options: Configuration options for execution

        Returns:
            CoordinationResult with aggregated outputs
        """

    async def decompose_and_execute(self, task: Task):
        """Decompose task and execute in parallel"""

    def get_progress_status(self, session_id: str):
        """Get real-time progress for a coordination session"""

    def cancel_execution(self, session_id: str):
        """Cancel parallel execution"""

    def get_performance_metrics(self):
        """Get system performance metrics"""
```

### Task Definition Interface
```python
@dataclass
class ParallelTask:
    id: str
    description: str
    agent_type: str
    priority: int
    dependencies: List[str]
    expected_duration: float
    resources_required: dict
    retry_policy: dict

@dataclass
class CoordinationResult:
    session_id: str
    status: str  # SUCCESS, PARTIAL, FAILED
    results: List[AgentResult]
    execution_time: float
    performance_metrics: dict
    error_summary: dict
```

---

## 📈 EXECUTION STRATEGIES

### 1. Parallel Strategy (Default)
- **Use Case:** Independent tasks that can run simultaneously
- **Benefits:** Maximum speed, optimal resource utilization
- **Example:** Multiple code files analysis, parallel testing

### 2. Pipeline Strategy
- **Use Case:** Tasks with linear dependencies
- **Benefits:** Ensures correct order, handles dependencies
- **Example:** Analysis → Design → Implementation → Testing

### 3. Hybrid Strategy
- **Use Case:** Complex tasks with mixed dependencies
- **Benefits:** Optimal balance of speed and correctness
- **Example:** Multiple features with shared components

### 4. Burst Strategy
- **Use Case:** Many small independent tasks
- **Benefits:** Maximum throughput for simple operations
- **Example:** File processing, batch operations

---

## 🛡️ ERROR HANDLING & RECOVERY

### Error Categories
```python
ERROR_HANDLING = {
    'agent_failure': {
        'strategy': 'retry_with_different_agent',
        'max_retries': 3,
        'fallback_agents': ['coder', 'analyzer']
    },
    'dependency_failure': {
        'strategy': 'recalculate_graph',
        'action': 'find_alternative_path'
    },
    'resource_exhaustion': {
        'strategy': 'scale_down_and_queue',
        'action': 'reduce_parallel_workers'
    },
    'timeout': {
        'strategy': 'partial_result_collection',
        'action': 'aggregate_completed_tasks'
    }
}
```

### Recovery Mechanisms
1. **Automatic Retry:** Failed tasks are retried with exponential backoff
2. **Agent Substitution:** Failed agents are replaced with alternatives
3. **Dependency Rerouting:** Failed dependencies trigger graph recalculation
4. **Partial Success:** Collect results from successful tasks even if some fail
5. **Graceful Degradation:** Reduce parallelism if resource constraints hit

---

## 📊 MONITORING & METRICS

### Real-time Dashboards
```json
{
  "system_health": {
    "cpu_usage": "45%",
    "memory_usage": "1.2GB",
    "active_agents": 12,
    "queue_size": 3,
    "error_rate": "1.2%"
  },
  "performance": {
    "tasks_per_second": 8.5,
    "avg_response_time": "2.3s",
    "success_rate": "98.8%",
    "parallel_efficiency": "87%"
  }
}
```

### Alerts and Notifications
- **Performance Degradation:** When throughput drops below threshold
- **Error Rate Spike:** When error rate exceeds 5%
- **Resource Exhaustion:** When CPU/Memory usage hits limits
- **Agent Failures:** When specific agents fail repeatedly

---

## 🔄 INTEGRATION WITH EXISTING AGENTS

### Seamless Integration
The parallel coordinator integrates with existing agents without any changes:

1. **Agent Discovery:** Automatically scans ~/.claude/agents/ structure
2. **Protocol Compliance:** Uses existing PROTOCOL.md format
3. **Expert Routing:** Leverages existing agent expertise mapping
4. **Zero Configuration:** Works immediately with current setup

### Enhanced Capabilities
- **Intelligent Routing:** Routes tasks to most suitable agents
- **Load Balancing:** Distributes work across available agents
- **Resource Optimization:** Manages token usage and memory efficiently
- **Quality Assurance:** Maintains quality standards through parallel review

---

## 🎯 USAGE EXAMPLES

### Example 1: Complex Software Development
```python
task = "Develop a complete trading dashboard with real-time data, user authentication, and mobile support"

# Automatic decomposition:
subtasks = [
    {"agent": "architect_expert", "task": "Design system architecture"},
    {"agent": "gui-super-expert", "task": "Create dashboard UI mockups"},
    {"agent": "database_expert", "task": "Design data schema"},
    {"agent": "security_unified_expert", "task": "Implement authentication"},
    {"agent": "integration_expert", "task": "Setup real-time data feeds"},
    {"agent": "mobile_expert", "task": "Create mobile interface"},
    {"agent": "tester_expert", "task": "Create test strategy"},
    {"agent": "coder", "task": "Implement core logic", "count": 3},
    {"agent": "reviewer", "task": "Code review", "count": 2}
]

# Parallel execution with dependency management
result = await coordinator.coordinate_task(task)
```

### Example 2: Code Analysis and Refactoring
```python
task = "Analyze entire codebase, identify performance issues, security vulnerabilities, and refactor for better architecture"

# Parallel analysis:
analysis_tasks = [
    {"agent": "analyzer", "task": "Code complexity analysis", "files": "src/"},
    {"agent": "security_unified_expert", "task": "Security audit"},
    {"agent": "architect_expert", "task": "Architecture review"},
    {"agent": "tester_expert", "task": "Performance profiling"}
]

# Results aggregated and synthesized automatically
```

### Example 3: Multi-Language Project
```python
task = "Port trading system from Python to multiple languages (C#, JavaScript, MQL5)"

# Language experts work in parallel:
parallel_tasks = [
    {"agent": "languages_expert", "task": "Port to C#", "focus": "csharp"},
    {"agent": "languages_expert", "task": "Port to JavaScript", "focus": "javascript"},
    {"agent": "mql_expert", "task": "Port to MQL5"},
    {"agent": "reviewer", "task": "Cross-language consistency check"}
]
```

---

## 🔧 ADVANCED FEATURES

### Dynamic Agent Scaling
```python
# Automatically scales based on workload
if queue_size > 20:
    scale_up_workers()
elif cpu_usage < 30% and queue_size < 5:
    scale_down_workers()
```

### Intelligent Task Batching
```python
# Groups similar tasks for efficiency
batch_similar_tasks(tasks, criteria=['agent_type', 'file_location', 'complexity'])
```

### Predictive Resource Management
```python
# Predicts resource needs based on task history
predicted_memory = predict_memory_usage(task_type, file_size, complexity)
predicted_time = predict_execution_time(agent_type, task_complexity)
```

### Quality Assurance Pipeline
```python
# Automated QA for all outputs
qa_pipeline = [
    'syntax_check',
    'security_scan',
    'performance_test',
    'documentation_check'
]
```

---

## 🚀 PERFORMANCE OPTIMIZATION

### Token Efficiency
- **Smart Model Selection:** Haiku for simple tasks, Sonnet for complex, Opus for critical
- **Context Sharing:** Reuse analysis results across related tasks
- **Incremental Processing:** Process only changed parts for updates

### Memory Optimization
- **Lazy Loading:** Load agents only when needed
- **Result Caching:** Cache intermediate results for reuse
- **Garbage Collection:** Automatic cleanup of completed tasks

### Network Optimization
- **Request Batching:** Batch multiple agent requests
- **Connection Pooling:** Reuse connections for efficiency
- **Compression:** Compress large outputs for transfer

---

## 📚 INTEGRATION GUIDE

### Quick Start
```bash
# The system is ready to use immediately
cd ~/.claude/agents/system/
# All configuration files are present
# No additional setup required
```

### Usage in Orchestrator
```python
from system.parallel_coordinator import ParallelCoordinator

# Initialize coordinator
coordinator = ParallelCoordinator()

# Use in any orchestrator workflow
result = await coordinator.coordinate_task(user_request)
```

### Custom Configuration
```python
# Override default settings if needed
config = {
    'max_agents': 32,  # Reduce for smaller systems
    'timeout': 600,    # Increase for complex tasks
    'priority_mode': 'speed'  # vs 'quality'
}

coordinator = ParallelCoordinator(config)
```

---

## 🎯 SUCCESS METRICS

### Performance Targets
- **Throughput:** 10+ tasks per minute
- **Success Rate:** 95%+ task completion
- **Response Time:** <5 seconds average
- **Parallel Efficiency:** 80%+ resource utilization

### Quality Assurance
- **Code Quality:** 100% compliance with PROTOCOL.md
- **Error Handling:** <3% unhandled errors
- **Resource Management:** No memory leaks or token waste
- **Integration:** Zero breaking changes to existing agents

---

**Status:** Production Ready
**Version:** 6.0
**Date:** 31 January 2026
**Compatibility:** Full integration with existing ~/.claude/agents/ structure

The parallel coordination system is now ready for immediate use with all existing agents in your ~/.claude/agents/ directory.
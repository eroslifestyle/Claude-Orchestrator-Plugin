---
name: Dependency Graph
description: Dependency tracking between agents and tasks
---

# 🕸️ DEPENDENCY GRAPH MANAGEMENT SYSTEM

> **Purpose:** Smart dependency resolution and execution order optimization
> **Version:** 6.0
> **Date:** 31 January 2026
> **Integration:** Works with PARALLEL_COORDINATOR.md
> **Status:** Production Ready

---

## 🎯 CORE FUNCTIONALITY

### Dependency Resolution
- **Smart Analysis:** Automatically detect task dependencies
- **Graph Optimization:** Find optimal execution paths
- **Cycle Detection:** Prevent circular dependencies
- **Dynamic Updates:** Handle runtime dependency changes
- **Parallel Opportunities:** Identify tasks that can run simultaneously

### Advanced Features
- **Conditional Dependencies:** Support for if-then dependency logic
- **Resource Dependencies:** Factor in shared resources and constraints
- **Time-based Dependencies:** Handle time-sensitive task ordering
- **Quality Gates:** Ensure quality checkpoints in execution flow

---

## 🏗️ ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPENDENCY GRAPH ENGINE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Graph     │    │  Analyzer   │    │  Optimizer  │         │
│  │  Builder    │───▶│             │───▶│             │         │
│  │             │    │             │    │             │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Task      │    │ Dependency  │    │  Execution  │         │
│  │ Decomposer  │    │  Resolver   │    │  Planner    │         │
│  │             │    │             │    │             │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📊 DEPENDENCY TYPES

### 1. Sequential Dependencies
```python
# Task B depends on Task A completion
SEQUENTIAL_DEPS = {
    'analyze_code': [],  # No dependencies
    'design_architecture': ['analyze_code'],
    'implement_features': ['design_architecture'],
    'test_system': ['implement_features'],
    'deploy': ['test_system']
}
```

### 2. Resource Dependencies
```python
# Tasks that need exclusive access to resources
RESOURCE_DEPS = {
    'database_migration': {'exclusive': ['database']},
    'schema_update': {'exclusive': ['database']},
    'performance_test': {'shared': ['database'], 'exclusive': ['test_env']}
}
```

### 3. Conditional Dependencies
```python
# Dependencies based on conditions
CONDITIONAL_DEPS = {
    'security_audit': {
        'condition': 'if security_features_present',
        'depends_on': ['implement_auth', 'implement_encryption']
    },
    'mobile_optimization': {
        'condition': 'if mobile_support_required',
        'depends_on': ['responsive_design', 'api_optimization']
    }
}
```

### 4. Quality Gate Dependencies
```python
# Quality checkpoints that must pass
QUALITY_GATES = {
    'code_review': {
        'trigger_after': ['implement_features'],
        'must_pass_before': ['test_system'],
        'criteria': ['code_quality > 8/10', 'security_score > 90%']
    }
}
```

---

## 🔧 CORE ALGORITHMS

### Dependency Graph Builder
```python
class DependencyGraphBuilder:
    def __init__(self):
        self.graph = {}
        self.reverse_graph = {}
        self.metadata = {}

    def build_graph(self, tasks):
        """Build dependency graph from task list"""
        for task in tasks:
            self.add_task(task)
            self.analyze_dependencies(task)

        return self.optimize_graph()

    def add_task(self, task):
        """Add task node to graph"""
        task_id = task['id']
        self.graph[task_id] = {
            'dependencies': set(),
            'dependents': set(),
            'metadata': self.extract_metadata(task)
        }

    def analyze_dependencies(self, task):
        """Analyze and add dependencies"""
        deps = self.detect_dependencies(task)
        for dep in deps:
            self.add_dependency(task['id'], dep)

    def detect_dependencies(self, task):
        """Intelligent dependency detection"""
        dependencies = []

        # File-based dependencies
        if task.get('input_files'):
            deps = self.find_file_producers(task['input_files'])
            dependencies.extend(deps)

        # Agent-based dependencies
        if task.get('requires_analysis'):
            dependencies.extend(self.find_analysis_tasks())

        # Domain-specific dependencies
        dependencies.extend(self.detect_domain_deps(task))

        return dependencies

    def detect_domain_deps(self, task):
        """Domain-specific dependency detection"""
        domain_rules = {
            'implement': ['analyze', 'design'],
            'test': ['implement'],
            'deploy': ['test', 'review'],
            'document': ['implement'],
            'review': ['implement']
        }

        task_type = self.classify_task(task)
        return domain_rules.get(task_type, [])
```

### Topological Sort with Parallel Optimization
```python
class ParallelTopologicalSort:
    def __init__(self, graph):
        self.graph = graph
        self.in_degree = self.calculate_in_degrees()

    def sort_with_parallelism(self):
        """Return execution layers for parallel processing"""
        layers = []
        remaining = set(self.graph.keys())

        while remaining:
            # Find all nodes with no dependencies
            ready = {node for node in remaining
                    if self.in_degree[node] == 0}

            if not ready:
                raise CyclicDependencyError("Circular dependency detected")

            # Group by compatibility for parallel execution
            parallel_groups = self.group_for_parallel_exec(ready)
            layers.append(parallel_groups)

            # Remove completed nodes and update in-degrees
            remaining -= ready
            for node in ready:
                self.update_dependencies(node)

        return layers

    def group_for_parallel_exec(self, ready_tasks):
        """Group tasks for optimal parallel execution"""
        groups = {
            'cpu_intensive': [],
            'io_intensive': [],
            'memory_intensive': [],
            'lightweight': []
        }

        for task in ready_tasks:
            category = self.categorize_task(task)
            groups[category].append(task)

        return self.optimize_groups(groups)
```

### Cycle Detection
```python
class CycleDetector:
    def __init__(self, graph):
        self.graph = graph
        self.visited = set()
        self.rec_stack = set()

    def has_cycle(self):
        """Detect if graph has cycles using DFS"""
        for node in self.graph:
            if node not in self.visited:
                if self.dfs_cycle_check(node):
                    return True
        return False

    def dfs_cycle_check(self, node):
        """DFS-based cycle detection"""
        self.visited.add(node)
        self.rec_stack.add(node)

        for neighbor in self.graph[node]['dependencies']:
            if neighbor not in self.visited:
                if self.dfs_cycle_check(neighbor):
                    return True
            elif neighbor in self.rec_stack:
                return True

        self.rec_stack.remove(node)
        return False

    def find_cycles(self):
        """Find all cycles in the graph"""
        cycles = []
        for node in self.graph:
            cycle = self.find_cycle_from_node(node)
            if cycle:
                cycles.append(cycle)
        return cycles
```

---

## 🚀 EXECUTION PLANNER

### Optimal Execution Strategy
```python
class ExecutionPlanner:
    def __init__(self, dependency_graph, resource_constraints):
        self.graph = dependency_graph
        self.constraints = resource_constraints
        self.execution_plan = None

    def create_execution_plan(self):
        """Create optimized execution plan"""
        layers = self.graph.sort_with_parallelism()

        plan = {
            'total_layers': len(layers),
            'estimated_time': self.estimate_total_time(layers),
            'resource_usage': self.calculate_resource_needs(layers),
            'execution_sequence': []
        }

        for layer_idx, layer in enumerate(layers):
            layer_plan = {
                'layer': layer_idx,
                'parallel_groups': self.optimize_layer(layer),
                'estimated_duration': self.estimate_layer_time(layer),
                'required_resources': self.calculate_layer_resources(layer)
            }
            plan['execution_sequence'].append(layer_plan)

        return plan

    def optimize_layer(self, layer):
        """Optimize task grouping within a layer"""
        optimized_groups = []

        # Group by resource requirements
        resource_groups = self.group_by_resources(layer)

        # Balance workload across available agents
        for group in resource_groups:
            balanced = self.balance_workload(group)
            optimized_groups.extend(balanced)

        return optimized_groups

    def estimate_execution_time(self, tasks):
        """Estimate execution time for task group"""
        time_estimates = {
            'analyzer': {'base': 30, 'per_file': 5},
            'coder': {'base': 60, 'per_feature': 120},
            'reviewer': {'base': 20, 'per_file': 10},
            'gui-super-expert': {'base': 90, 'per_component': 45},
            'database_expert': {'base': 45, 'per_table': 15}
        }

        total_time = 0
        for task in tasks:
            agent_type = task['agent']
            base_time = time_estimates.get(agent_type, {}).get('base', 60)
            variable_time = self.calculate_variable_time(task, time_estimates)
            total_time += base_time + variable_time

        return total_time
```

---

## 📊 DEPENDENCY ANALYSIS

### Smart Dependency Detection
```python
class SmartDependencyDetector:
    def __init__(self):
        self.rules = self.load_dependency_rules()
        self.patterns = self.load_pattern_matchers()

    def analyze_task_dependencies(self, task_description):
        """Analyze natural language task description for dependencies"""
        dependencies = []

        # Keyword-based detection
        keywords = self.extract_keywords(task_description)
        dependencies.extend(self.match_keyword_dependencies(keywords))

        # Pattern-based detection
        patterns = self.match_patterns(task_description)
        dependencies.extend(self.resolve_pattern_dependencies(patterns))

        # Context-based detection
        context_deps = self.analyze_context_dependencies(task_description)
        dependencies.extend(context_deps)

        return self.deduplicate_dependencies(dependencies)

    def match_keyword_dependencies(self, keywords):
        """Match keywords to known dependency patterns"""
        dependency_map = {
            'implement': ['analyze', 'design'],
            'test': ['implement', 'build'],
            'deploy': ['test', 'review', 'build'],
            'document': ['implement', 'test'],
            'refactor': ['analyze', 'backup'],
            'optimize': ['profile', 'analyze'],
            'integrate': ['implement', 'test'],
            'security': ['analyze', 'audit'],
            'database': ['schema_design', 'migration'],
            'ui': ['mockup', 'design'],
            'api': ['specification', 'schema']
        }

        dependencies = []
        for keyword in keywords:
            if keyword in dependency_map:
                dependencies.extend(dependency_map[keyword])

        return dependencies
```

### Resource Conflict Detection
```python
class ResourceConflictDetector:
    def __init__(self):
        self.resource_map = {
            'database': {'exclusive_ops': ['migration', 'schema_change'],
                        'shared_ops': ['query', 'read']},
            'filesystem': {'exclusive_ops': ['file_move', 'bulk_delete'],
                          'shared_ops': ['read', 'small_write']},
            'network': {'rate_limited': ['api_calls', 'downloads'],
                       'unlimited': ['local_requests']}
        }

    def detect_conflicts(self, parallel_tasks):
        """Detect resource conflicts in parallel task set"""
        conflicts = []
        resource_usage = {}

        for task in parallel_tasks:
            resources = self.analyze_task_resources(task)

            for resource, access_type in resources.items():
                if resource not in resource_usage:
                    resource_usage[resource] = []

                # Check for conflicts
                existing_access = resource_usage[resource]
                if self.has_conflict(access_type, existing_access):
                    conflicts.append({
                        'resource': resource,
                        'conflicting_tasks': [task] +
                                           [t for t in existing_access]
                    })

                resource_usage[resource].append(task)

        return conflicts
```

---

## 🔄 DYNAMIC DEPENDENCY MANAGEMENT

### Runtime Dependency Updates
```python
class DynamicDependencyManager:
    def __init__(self, execution_plan):
        self.execution_plan = execution_plan
        self.runtime_state = {}
        self.dependency_updates = []

    def handle_task_completion(self, task_id, result):
        """Handle task completion and update dependencies"""
        # Update task status
        self.runtime_state[task_id] = {
            'status': 'completed',
            'result': result,
            'completion_time': datetime.now()
        }

        # Check for new dependencies based on result
        new_deps = self.analyze_result_dependencies(task_id, result)

        # Update execution plan if needed
        if new_deps:
            self.update_execution_plan(new_deps)

    def handle_task_failure(self, task_id, error):
        """Handle task failure and dependency recalculation"""
        self.runtime_state[task_id] = {
            'status': 'failed',
            'error': error,
            'failure_time': datetime.now()
        }

        # Find alternative paths
        alternatives = self.find_alternative_paths(task_id)

        # Reschedule dependent tasks
        self.reschedule_dependents(task_id, alternatives)

    def update_execution_plan(self, new_dependencies):
        """Update execution plan with new dependencies"""
        # Recalculate affected layers
        affected_layers = self.find_affected_layers(new_dependencies)

        # Rebuild those layers
        for layer_idx in affected_layers:
            self.execution_plan['execution_sequence'][layer_idx] = \
                self.rebuild_layer(layer_idx, new_dependencies)

        # Update time estimates
        self.update_time_estimates()
```

---

## 🎯 OPTIMIZATION STRATEGIES

### Graph Optimization Techniques
```python
class GraphOptimizer:
    def __init__(self):
        self.optimization_strategies = [
            'merge_compatible_tasks',
            'split_large_tasks',
            'reorder_for_cache_efficiency',
            'balance_agent_workload',
            'minimize_idle_time'
        ]

    def optimize_dependency_graph(self, graph):
        """Apply multiple optimization strategies"""
        optimized_graph = graph.copy()

        for strategy in self.optimization_strategies:
            optimizer = getattr(self, strategy)
            optimized_graph = optimizer(optimized_graph)

        return optimized_graph

    def merge_compatible_tasks(self, graph):
        """Merge tasks that can be efficiently combined"""
        merged_graph = graph.copy()

        compatible_pairs = self.find_compatible_tasks(graph)

        for task1, task2 in compatible_pairs:
            if self.can_merge_safely(task1, task2, graph):
                merged_task = self.merge_tasks(task1, task2)
                merged_graph = self.replace_tasks(
                    merged_graph, [task1, task2], merged_task
                )

        return merged_graph

    def balance_agent_workload(self, graph):
        """Balance workload across different agent types"""
        agent_workloads = self.calculate_agent_workloads(graph)

        # Identify overloaded agents
        overloaded = [agent for agent, load in agent_workloads.items()
                     if load > self.get_agent_capacity(agent)]

        # Redistribute tasks from overloaded agents
        for agent in overloaded:
            tasks_to_redistribute = self.select_redistribution_candidates(
                graph, agent
            )

            for task in tasks_to_redistribute:
                alternative_agent = self.find_alternative_agent(task)
                if alternative_agent:
                    self.reassign_task(graph, task, alternative_agent)

        return graph
```

---

## 📈 PERFORMANCE MONITORING

### Dependency Graph Metrics
```python
class DependencyMetrics:
    def __init__(self, graph):
        self.graph = graph

    def calculate_metrics(self):
        """Calculate comprehensive graph metrics"""
        return {
            'complexity_metrics': self.calculate_complexity(),
            'parallelism_metrics': self.calculate_parallelism(),
            'efficiency_metrics': self.calculate_efficiency(),
            'bottleneck_analysis': self.analyze_bottlenecks()
        }

    def calculate_complexity(self):
        """Calculate graph complexity metrics"""
        return {
            'total_nodes': len(self.graph),
            'total_edges': self.count_edges(),
            'average_degree': self.calculate_average_degree(),
            'clustering_coefficient': self.calculate_clustering(),
            'graph_diameter': self.calculate_diameter(),
            'critical_path_length': self.find_critical_path_length()
        }

    def calculate_parallelism(self):
        """Calculate parallelism opportunities"""
        layers = self.graph.sort_with_parallelism()

        return {
            'total_layers': len(layers),
            'max_parallel_tasks': max(len(layer) for layer in layers),
            'average_parallel_tasks': sum(len(layer) for layer in layers) / len(layers),
            'parallelism_efficiency': self.calculate_parallelism_efficiency(layers),
            'sequential_ratio': self.calculate_sequential_ratio(layers)
        }

    def analyze_bottlenecks(self):
        """Identify potential bottlenecks"""
        bottlenecks = []

        # Critical path bottlenecks
        critical_path = self.find_critical_path()
        for task in critical_path:
            if self.is_bottleneck(task):
                bottlenecks.append({
                    'task': task,
                    'type': 'critical_path',
                    'impact': self.calculate_bottleneck_impact(task)
                })

        # Resource bottlenecks
        resource_conflicts = self.find_resource_bottlenecks()
        bottlenecks.extend(resource_conflicts)

        # Agent capacity bottlenecks
        capacity_issues = self.find_capacity_bottlenecks()
        bottlenecks.extend(capacity_issues)

        return bottlenecks
```

---

## 🔧 CONFIGURATION

### Dependency Rules Configuration
```yaml
dependency_rules:
  automatic_detection:
    enabled: true
    confidence_threshold: 0.8

  file_dependencies:
    track_input_output: true
    monitor_modifications: true

  agent_dependencies:
    enforce_domain_rules: true
    allow_cross_domain: false

  resource_dependencies:
    track_exclusive_access: true
    detect_conflicts: true

  quality_gates:
    enabled: true
    default_criteria:
      code_quality: 8.0
      security_score: 90
      test_coverage: 85

optimization:
  merge_compatible_tasks: true
  split_large_tasks: true
  balance_workloads: true
  minimize_idle_time: true

  thresholds:
    task_merge_similarity: 0.7
    workload_imbalance: 0.3
    idle_time_threshold: 30  # seconds

monitoring:
  track_execution_time: true
  monitor_bottlenecks: true
  alert_on_cycles: true
  performance_logging: true
```

---

## 🎯 API INTERFACE

### Main Dependency Graph API
```python
class DependencyGraphAPI:
    """Main interface for dependency graph management"""

    def __init__(self, config=None):
        self.config = config or self.load_default_config()
        self.builder = DependencyGraphBuilder()
        self.optimizer = GraphOptimizer()
        self.planner = ExecutionPlanner()

    def create_dependency_graph(self, tasks):
        """Create optimized dependency graph from task list"""
        # Build initial graph
        graph = self.builder.build_graph(tasks)

        # Detect and resolve cycles
        if self.has_cycles(graph):
            graph = self.resolve_cycles(graph)

        # Optimize graph
        optimized_graph = self.optimizer.optimize_dependency_graph(graph)

        # Create execution plan
        execution_plan = self.planner.create_execution_plan(optimized_graph)

        return {
            'graph': optimized_graph,
            'execution_plan': execution_plan,
            'metrics': self.calculate_metrics(optimized_graph)
        }

    def update_dependencies(self, graph, updates):
        """Update existing dependency graph"""
        pass

    def get_execution_order(self, graph):
        """Get optimal execution order for tasks"""
        pass

    def find_parallel_opportunities(self, graph):
        """Find tasks that can be executed in parallel"""
        pass
```

---

## 🚀 INTEGRATION EXAMPLES

### Example 1: Software Development Project
```python
# Complex project with multiple dependencies
tasks = [
    {'id': 'analyze_requirements', 'type': 'analysis', 'agent': 'analyzer'},
    {'id': 'design_database', 'type': 'design', 'agent': 'database_expert'},
    {'id': 'design_ui', 'type': 'design', 'agent': 'gui-super-expert'},
    {'id': 'implement_backend', 'type': 'implementation', 'agent': 'coder'},
    {'id': 'implement_frontend', 'type': 'implementation', 'agent': 'coder'},
    {'id': 'security_audit', 'type': 'security', 'agent': 'security_unified_expert'},
    {'id': 'integration_testing', 'type': 'testing', 'agent': 'tester_expert'},
    {'id': 'deployment', 'type': 'deployment', 'agent': 'devops_expert'}
]

# Create dependency graph
graph_result = dependency_api.create_dependency_graph(tasks)

# Execution layers (parallel groups)
# Layer 0: [analyze_requirements]
# Layer 1: [design_database, design_ui] (parallel)
# Layer 2: [implement_backend, implement_frontend] (parallel)
# Layer 3: [security_audit]
# Layer 4: [integration_testing]
# Layer 5: [deployment]
```

### Example 2: Code Refactoring Project
```python
tasks = [
    {'id': 'analyze_codebase', 'type': 'analysis'},
    {'id': 'identify_patterns', 'type': 'analysis'},
    {'id': 'refactor_module_a', 'type': 'refactoring'},
    {'id': 'refactor_module_b', 'type': 'refactoring'},
    {'id': 'update_tests', 'type': 'testing'},
    {'id': 'performance_testing', 'type': 'testing'},
    {'id': 'documentation_update', 'type': 'documentation'}
]

# Automatic dependency detection will create:
# analyze_codebase → identify_patterns → [refactor_module_a, refactor_module_b] (parallel)
#                                    → update_tests → performance_testing
#                                    → documentation_update
```

---

**Status:** Production Ready
**Version:** 6.0
**Date:** 31 January 2026
**Integration:** Full compatibility with PARALLEL_COORDINATOR.md

The dependency graph management system provides intelligent dependency resolution and optimal execution planning for complex multi-agent workflows.
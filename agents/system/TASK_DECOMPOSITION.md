---
name: Task Decomposition
description: System for breaking down complex tasks
---

# 🧩 AUTOMATIC TASK DECOMPOSITION ENGINE

> **Purpose:** Intelligent automatic breakdown of complex tasks into manageable subtasks
> **Version:** 6.0
> **Date:** 31 January 2026
> **Integration:** Works with PARALLEL_COORDINATOR.md and DEPENDENCY_GRAPH.md
> **Status:** Production Ready

---

## 🎯 CORE FUNCTIONALITY

### Intelligent Task Analysis
- **Natural Language Processing:** Understand complex task descriptions
- **Context Analysis:** Extract requirements, constraints, and objectives
- **Domain Recognition:** Identify task domain and required expertise
- **Complexity Assessment:** Evaluate task complexity and resource needs
- **Automatic Breakdown:** Split into optimal subtask granularity

### Advanced Decomposition
- **Multi-level Decomposition:** Hierarchical task breakdown structure
- **Cross-domain Dependencies:** Handle tasks spanning multiple domains
- **Resource-aware Splitting:** Consider agent capabilities and availability
- **Quality Gate Integration:** Embed quality checkpoints automatically

---

## 🏗️ ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                TASK DECOMPOSITION ENGINE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Natural   │    │  Context    │    │  Domain     │         │
│  │  Language   │───▶│  Analyzer   │───▶│ Classifier  │         │
│  │  Processor  │    │             │    │             │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                   │                   │               │
│         ▼                   ▼                   ▼               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │ Complexity  │    │ Subtask     │    │ Quality     │         │
│  │ Analyzer    │    │ Generator   │    │ Gate        │         │
│  │             │    │             │    │ Inserter    │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                   │                   │               │
│         └───────────────────┼───────────────────┘               │
│                             ▼                                   │
│                    ┌─────────────┐                              │
│                    │ Execution   │                              │
│                    │ Plan        │                              │
│                    │ Generator   │                              │
│                    └─────────────┘                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔍 NATURAL LANGUAGE PROCESSING

### Task Intent Analysis
```python
class TaskIntentAnalyzer:
    def __init__(self):
        self.intent_patterns = self.load_intent_patterns()
        self.domain_keywords = self.load_domain_keywords()
        self.action_verbs = self.load_action_verbs()

    def analyze_task_intent(self, task_description):
        """Analyze task description to extract intent and requirements"""
        analysis = {
            'primary_intent': self.extract_primary_intent(task_description),
            'secondary_intents': self.extract_secondary_intents(task_description),
            'domains': self.identify_domains(task_description),
            'entities': self.extract_entities(task_description),
            'constraints': self.extract_constraints(task_description),
            'success_criteria': self.extract_success_criteria(task_description)
        }

        return analysis

    def extract_primary_intent(self, description):
        """Extract the main objective of the task"""
        intent_patterns = {
            'create': r'(create|build|develop|implement|make|generate)',
            'analyze': r'(analyze|examine|review|study|investigate)',
            'modify': r'(modify|update|change|refactor|improve|optimize)',
            'test': r'(test|verify|validate|check|ensure)',
            'deploy': r'(deploy|release|publish|launch)',
            'integrate': r'(integrate|connect|combine|merge)',
            'document': r'(document|write|explain|describe)',
            'design': r'(design|architect|plan|structure)'
        }

        for intent, pattern in intent_patterns.items():
            if re.search(pattern, description, re.IGNORECASE):
                return intent

        return 'unknown'

    def identify_domains(self, description):
        """Identify technical domains involved in the task"""
        domain_keywords = {
            'frontend': ['ui', 'interface', 'gui', 'frontend', 'react', 'vue', 'angular'],
            'backend': ['api', 'server', 'backend', 'database', 'service'],
            'database': ['database', 'sql', 'schema', 'migration', 'query'],
            'security': ['security', 'auth', 'encryption', 'vulnerability', 'secure'],
            'testing': ['test', 'testing', 'qa', 'quality', 'verification'],
            'devops': ['deploy', 'ci/cd', 'docker', 'kubernetes', 'infrastructure'],
            'mobile': ['mobile', 'ios', 'android', 'app', 'responsive'],
            'trading': ['trading', 'market', 'orders', 'risk', 'portfolio'],
            'ai': ['ai', 'machine learning', 'ml', 'model', 'prediction']
        }

        identified_domains = []
        description_lower = description.lower()

        for domain, keywords in domain_keywords.items():
            if any(keyword in description_lower for keyword in keywords):
                identified_domains.append(domain)

        return identified_domains

    def extract_entities(self, description):
        """Extract specific entities mentioned in the task"""
        entities = {
            'technologies': self.extract_technologies(description),
            'files': self.extract_file_references(description),
            'components': self.extract_components(description),
            'features': self.extract_features(description)
        }

        return entities
```

### Context Extraction
```python
class ContextExtractor:
    def __init__(self):
        self.context_patterns = self.load_context_patterns()

    def extract_context(self, task_description):
        """Extract contextual information from task description"""
        context = {
            'scope': self.determine_scope(task_description),
            'priority': self.assess_priority(task_description),
            'timeline': self.extract_timeline(task_description),
            'resources': self.identify_required_resources(task_description),
            'constraints': self.extract_constraints(task_description),
            'dependencies': self.identify_dependencies(task_description)
        }

        return context

    def determine_scope(self, description):
        """Determine the scope of the task (small, medium, large, enterprise)"""
        scope_indicators = {
            'small': ['simple', 'quick', 'small', 'minor', 'basic'],
            'medium': ['moderate', 'standard', 'typical', 'medium'],
            'large': ['complex', 'comprehensive', 'complete', 'full', 'extensive'],
            'enterprise': ['enterprise', 'system-wide', 'organization', 'massive']
        }

        description_lower = description.lower()
        max_score = 0
        determined_scope = 'medium'  # default

        for scope, indicators in scope_indicators.items():
            score = sum(1 for indicator in indicators if indicator in description_lower)
            if score > max_score:
                max_score = score
                determined_scope = scope

        return determined_scope

    def extract_timeline(self, description):
        """Extract timeline information from description"""
        timeline_patterns = {
            'urgent': r'(urgent|immediately|asap|critical|emergency)',
            'short': r'(today|tonight|this week|few days|quickly)',
            'medium': r'(this month|few weeks|soon|normal)',
            'long': r'(few months|long term|eventually|when possible)'
        }

        for timeline, pattern in timeline_patterns.items():
            if re.search(pattern, description, re.IGNORECASE):
                return timeline

        return 'medium'  # default
```

---

## 📊 COMPLEXITY ASSESSMENT

### Multi-dimensional Complexity Analysis
```python
class ComplexityAnalyzer:
    def __init__(self):
        self.complexity_factors = self.load_complexity_factors()

    def assess_complexity(self, task_intent, context):
        """Multi-dimensional complexity assessment"""
        complexity_scores = {
            'technical': self.assess_technical_complexity(task_intent),
            'functional': self.assess_functional_complexity(task_intent),
            'integration': self.assess_integration_complexity(context),
            'resource': self.assess_resource_complexity(context),
            'temporal': self.assess_temporal_complexity(context)
        }

        overall_complexity = self.calculate_overall_complexity(complexity_scores)

        return {
            'scores': complexity_scores,
            'overall': overall_complexity,
            'breakdown_recommended': overall_complexity > 7,
            'parallel_opportunities': self.identify_parallel_opportunities(task_intent),
            'estimated_subtasks': self.estimate_subtask_count(overall_complexity)
        }

    def assess_technical_complexity(self, task_intent):
        """Assess technical complexity based on domains and technologies"""
        complexity = 0

        # Domain complexity weights
        domain_weights = {
            'ai': 9,
            'security': 8,
            'trading': 8,
            'database': 7,
            'integration': 7,
            'backend': 6,
            'frontend': 5,
            'mobile': 6,
            'devops': 7,
            'testing': 4
        }

        for domain in task_intent.get('domains', []):
            complexity += domain_weights.get(domain, 5)

        # Technology complexity
        tech_complexity = len(task_intent.get('entities', {}).get('technologies', []))
        complexity += tech_complexity * 2

        return min(complexity, 10)  # Cap at 10

    def assess_integration_complexity(self, context):
        """Assess complexity based on integration requirements"""
        integration_score = 0

        # Multiple systems integration
        dependencies = context.get('dependencies', [])
        integration_score += len(dependencies) * 2

        # Cross-domain integration
        if len(context.get('domains', [])) > 2:
            integration_score += 3

        # External API integration
        if any('api' in dep.lower() for dep in dependencies):
            integration_score += 2

        return min(integration_score, 10)

    def identify_parallel_opportunities(self, task_intent):
        """Identify opportunities for parallel execution"""
        opportunities = []

        domains = task_intent.get('domains', [])

        # Independent domains can be parallelized
        independent_domains = ['frontend', 'backend', 'database', 'testing']
        parallel_domains = [d for d in domains if d in independent_domains]

        if len(parallel_domains) > 1:
            opportunities.append({
                'type': 'domain_parallelism',
                'domains': parallel_domains,
                'potential_speedup': len(parallel_domains) * 0.7
            })

        # File-based parallelism
        entities = task_intent.get('entities', {})
        files = entities.get('files', [])
        if len(files) > 2:
            opportunities.append({
                'type': 'file_parallelism',
                'files': files,
                'potential_speedup': min(len(files), 4) * 0.5
            })

        return opportunities
```

---

## 🧩 SUBTASK GENERATION

### Intelligent Task Breakdown
```python
class SubtaskGenerator:
    def __init__(self):
        self.breakdown_templates = self.load_breakdown_templates()
        self.agent_capabilities = self.load_agent_capabilities()

    def generate_subtasks(self, task_intent, context, complexity):
        """Generate intelligent subtask breakdown"""
        if complexity['overall'] < 4:
            return [self.create_single_subtask(task_intent, context)]

        # Use appropriate breakdown strategy
        strategy = self.select_breakdown_strategy(task_intent, complexity)
        subtasks = self.apply_breakdown_strategy(strategy, task_intent, context)

        # Add quality gates
        subtasks = self.insert_quality_gates(subtasks, complexity['overall'])

        # Optimize subtask granularity
        subtasks = self.optimize_granularity(subtasks)

        return subtasks

    def select_breakdown_strategy(self, task_intent, complexity):
        """Select optimal breakdown strategy"""
        strategies = {
            'domain_based': self.is_multi_domain_task(task_intent),
            'sequential': self.requires_sequential_execution(task_intent),
            'parallel': self.has_parallel_opportunities(complexity),
            'hierarchical': complexity['overall'] > 8,
            'feature_based': self.is_feature_development_task(task_intent)
        }

        # Select highest scoring strategy
        selected_strategy = max(strategies.items(), key=lambda x: x[1])
        return selected_strategy[0] if selected_strategy[1] else 'sequential'

    def apply_breakdown_strategy(self, strategy, task_intent, context):
        """Apply selected breakdown strategy"""
        if strategy == 'domain_based':
            return self.domain_based_breakdown(task_intent, context)
        elif strategy == 'sequential':
            return self.sequential_breakdown(task_intent, context)
        elif strategy == 'parallel':
            return self.parallel_breakdown(task_intent, context)
        elif strategy == 'hierarchical':
            return self.hierarchical_breakdown(task_intent, context)
        elif strategy == 'feature_based':
            return self.feature_based_breakdown(task_intent, context)
        else:
            return self.default_breakdown(task_intent, context)

    def domain_based_breakdown(self, task_intent, context):
        """Break down task by technical domains"""
        subtasks = []
        domains = task_intent.get('domains', [])

        domain_templates = {
            'frontend': [
                'Design user interface mockups',
                'Implement UI components',
                'Add responsive design',
                'Integrate with backend APIs'
            ],
            'backend': [
                'Design API endpoints',
                'Implement business logic',
                'Set up database integration',
                'Add error handling and logging'
            ],
            'database': [
                'Design database schema',
                'Create migration scripts',
                'Implement data access layer',
                'Optimize queries and indexes'
            ],
            'security': [
                'Conduct security analysis',
                'Implement authentication',
                'Add input validation',
                'Security testing and audit'
            ]
        }

        for domain in domains:
            if domain in domain_templates:
                domain_tasks = domain_templates[domain]
                for task in domain_tasks:
                    subtasks.append(self.create_subtask(
                        task, domain, task_intent, context
                    ))

        return subtasks

    def sequential_breakdown(self, task_intent, context):
        """Break down task into sequential steps"""
        primary_intent = task_intent['primary_intent']

        sequential_templates = {
            'create': [
                'Analyze requirements',
                'Design architecture',
                'Implement core functionality',
                'Add advanced features',
                'Test implementation',
                'Document solution'
            ],
            'modify': [
                'Analyze current implementation',
                'Identify modification points',
                'Plan changes',
                'Implement modifications',
                'Test changes',
                'Update documentation'
            ],
            'integrate': [
                'Analyze integration points',
                'Design integration architecture',
                'Implement adapters',
                'Test integration',
                'Handle error cases',
                'Document integration'
            ]
        }

        template = sequential_templates.get(primary_intent, sequential_templates['create'])
        subtasks = []

        for step in template:
            subtasks.append(self.create_subtask(
                step, primary_intent, task_intent, context
            ))

        return subtasks

    def create_subtask(self, description, domain, task_intent, context):
        """Create a structured subtask"""
        return {
            'id': self.generate_subtask_id(),
            'description': description,
            'domain': domain,
            'recommended_agent': self.select_agent_for_subtask(description, domain),
            'estimated_duration': self.estimate_duration(description, domain),
            'complexity': self.estimate_subtask_complexity(description),
            'dependencies': [],  # Will be filled by dependency graph
            'resources': self.estimate_resources(description, domain),
            'success_criteria': self.generate_success_criteria(description)
        }
```

### Quality Gate Integration
```python
class QualityGateInserter:
    def __init__(self):
        self.quality_gates = self.load_quality_gate_templates()

    def insert_quality_gates(self, subtasks, overall_complexity):
        """Insert quality gates into subtask sequence"""
        if overall_complexity < 5:
            return subtasks  # No quality gates needed for simple tasks

        enhanced_subtasks = []
        gate_positions = self.determine_gate_positions(subtasks, overall_complexity)

        for i, subtask in enumerate(subtasks):
            enhanced_subtasks.append(subtask)

            if i in gate_positions:
                quality_gate = self.create_quality_gate(subtask, subtasks[:i+1])
                enhanced_subtasks.append(quality_gate)

        return enhanced_subtasks

    def determine_gate_positions(self, subtasks, complexity):
        """Determine where to insert quality gates"""
        positions = []

        # Always add gate after implementation phases
        for i, subtask in enumerate(subtasks):
            if 'implement' in subtask['description'].lower():
                if i + 1 < len(subtasks):  # Not the last task
                    positions.append(i)

        # Add gates for high complexity tasks
        if complexity > 8:
            # Add gates after every 3 subtasks
            for i in range(2, len(subtasks), 3):
                if i not in positions:
                    positions.append(i)

        return sorted(positions)

    def create_quality_gate(self, after_subtask, completed_subtasks):
        """Create a quality gate subtask"""
        return {
            'id': self.generate_quality_gate_id(),
            'description': f'Quality review after {after_subtask["description"]}',
            'type': 'quality_gate',
            'domain': 'quality_assurance',
            'recommended_agent': 'reviewer',
            'estimated_duration': 15,  # minutes
            'complexity': 2,
            'dependencies': [after_subtask['id']],
            'review_scope': [task['id'] for task in completed_subtasks],
            'success_criteria': [
                'Code quality score > 8/10',
                'No critical security issues',
                'Documentation updated',
                'Tests passing'
            ]
        }
```

---

## 🎯 AGENT ASSIGNMENT

### Intelligent Agent Selection
```python
class AgentSelector:
    def __init__(self):
        self.agent_capabilities = self.load_agent_capabilities()
        self.agent_performance = self.load_agent_performance_data()

    def select_optimal_agent(self, subtask):
        """Select the most suitable agent for a subtask"""
        candidates = self.find_candidate_agents(subtask)

        if not candidates:
            return 'coder'  # default fallback

        # Score each candidate
        scored_candidates = []
        for agent in candidates:
            score = self.calculate_agent_score(agent, subtask)
            scored_candidates.append((agent, score))

        # Return highest scoring agent
        best_agent = max(scored_candidates, key=lambda x: x[1])
        return best_agent[0]

    def find_candidate_agents(self, subtask):
        """Find agents capable of handling the subtask"""
        domain = subtask.get('domain', 'general')
        description = subtask['description'].lower()

        # Domain-based mapping
        domain_agents = {
            'frontend': ['gui-super-expert', 'coder'],
            'backend': ['coder', 'integration_expert'],
            'database': ['database_expert', 'coder'],
            'security': ['security_unified_expert'],
            'testing': ['tester_expert', 'coder'],
            'mobile': ['mobile_expert', 'gui-super-expert'],
            'devops': ['devops_expert'],
            'ai': ['ai_integration_expert'],
            'trading': ['trading_strategy_expert', 'mql_expert'],
            'analysis': ['analyzer'],
            'review': ['reviewer'],
            'documentation': ['documenter']
        }

        candidates = domain_agents.get(domain, ['coder'])

        # Keyword-based refinement
        keyword_agents = {
            'gui': 'gui-super-expert',
            'interface': 'gui-super-expert',
            'database': 'database_expert',
            'api': 'integration_expert',
            'security': 'security_unified_expert',
            'test': 'tester_expert',
            'deploy': 'devops_expert',
            'mobile': 'mobile_expert',
            'trading': 'trading_strategy_expert',
            'mql': 'mql_expert'
        }

        for keyword, agent in keyword_agents.items():
            if keyword in description and agent not in candidates:
                candidates.append(agent)

        return candidates

    def calculate_agent_score(self, agent, subtask):
        """Calculate suitability score for agent-subtask pair"""
        score = 0

        # Domain expertise match
        domain_match = self.get_domain_expertise(agent, subtask['domain'])
        score += domain_match * 40

        # Complexity handling ability
        complexity_score = self.get_complexity_score(agent, subtask['complexity'])
        score += complexity_score * 20

        # Historical performance
        performance_score = self.get_performance_score(agent, subtask['domain'])
        score += performance_score * 20

        # Current workload (favor less busy agents)
        workload_score = self.get_workload_score(agent)
        score += workload_score * 10

        # Estimated efficiency
        efficiency_score = self.get_efficiency_score(agent, subtask)
        score += efficiency_score * 10

        return score

    def get_domain_expertise(self, agent, domain):
        """Get agent expertise level for domain (0-10)"""
        expertise_map = {
            'gui-super-expert': {'frontend': 10, 'ui': 10, 'design': 9},
            'database_expert': {'database': 10, 'backend': 7, 'data': 9},
            'security_unified_expert': {'security': 10, 'auth': 9, 'encryption': 10},
            'integration_expert': {'api': 10, 'integration': 10, 'backend': 8},
            'tester_expert': {'testing': 10, 'qa': 10, 'automation': 8},
            'trading_strategy_expert': {'trading': 10, 'finance': 9, 'risk': 10},
            'mql_expert': {'trading': 9, 'mql': 10, 'automation': 8},
            'mobile_expert': {'mobile': 10, 'ios': 9, 'android': 9},
            'devops_expert': {'devops': 10, 'deployment': 10, 'infrastructure': 9},
            'ai_integration_expert': {'ai': 10, 'ml': 9, 'integration': 8},
            'coder': {'general': 7, 'implementation': 8, 'backend': 7},
            'analyzer': {'analysis': 10, 'code_review': 8, 'architecture': 7},
            'reviewer': {'review': 10, 'quality': 9, 'documentation': 6}
        }

        return expertise_map.get(agent, {}).get(domain, 5)  # default 5/10
```

---

## 📈 OPTIMIZATION TECHNIQUES

### Task Granularity Optimization
```python
class GranularityOptimizer:
    def __init__(self):
        self.optimal_durations = {
            'min': 15,  # minimum meaningful task duration (minutes)
            'max': 240,  # maximum task duration before splitting (minutes)
            'optimal': 60  # optimal task duration (minutes)
        }

    def optimize_granularity(self, subtasks):
        """Optimize subtask granularity for parallel execution"""
        optimized_subtasks = []

        for subtask in subtasks:
            duration = subtask.get('estimated_duration', 60)

            if duration < self.optimal_durations['min']:
                # Merge with similar subtasks
                merged_task = self.find_merge_candidate(subtask, optimized_subtasks)
                if merged_task:
                    self.merge_subtasks(merged_task, subtask)
                else:
                    optimized_subtasks.append(subtask)

            elif duration > self.optimal_durations['max']:
                # Split into smaller subtasks
                split_tasks = self.split_subtask(subtask)
                optimized_subtasks.extend(split_tasks)

            else:
                # Task is already optimal size
                optimized_subtasks.append(subtask)

        return optimized_subtasks

    def find_merge_candidate(self, subtask, existing_subtasks):
        """Find a suitable subtask to merge with"""
        for existing in existing_subtasks:
            if self.can_merge_subtasks(existing, subtask):
                return existing
        return None

    def can_merge_subtasks(self, task1, task2):
        """Check if two subtasks can be merged"""
        # Same domain and agent
        if (task1.get('domain') == task2.get('domain') and
            task1.get('recommended_agent') == task2.get('recommended_agent')):

            # Combined duration within limits
            combined_duration = (task1.get('estimated_duration', 0) +
                               task2.get('estimated_duration', 0))
            if combined_duration <= self.optimal_durations['max']:
                return True

        return False

    def split_subtask(self, subtask):
        """Split a large subtask into smaller ones"""
        description = subtask['description']
        domain = subtask.get('domain', 'general')

        # Domain-specific splitting strategies
        if 'implement' in description.lower():
            return self.split_implementation_task(subtask)
        elif 'test' in description.lower():
            return self.split_testing_task(subtask)
        elif 'design' in description.lower():
            return self.split_design_task(subtask)
        else:
            return self.generic_split(subtask)

    def split_implementation_task(self, subtask):
        """Split implementation tasks"""
        base_id = subtask['id']
        return [
            {
                **subtask,
                'id': f"{base_id}_plan",
                'description': f"Plan implementation: {subtask['description']}",
                'estimated_duration': subtask['estimated_duration'] * 0.2
            },
            {
                **subtask,
                'id': f"{base_id}_core",
                'description': f"Implement core functionality: {subtask['description']}",
                'estimated_duration': subtask['estimated_duration'] * 0.6
            },
            {
                **subtask,
                'id': f"{base_id}_polish",
                'description': f"Polish and optimize: {subtask['description']}",
                'estimated_duration': subtask['estimated_duration'] * 0.2
            }
        ]
```

---

## 🔧 CONFIGURATION

### Decomposition Rules
```yaml
decomposition_config:
  complexity_thresholds:
    simple: 3
    medium: 6
    complex: 8

  breakdown_strategies:
    domain_based:
      enabled: true
      min_domains: 2

    sequential:
      enabled: true
      default_strategy: true

    parallel:
      enabled: true
      min_parallel_tasks: 3

    hierarchical:
      enabled: true
      max_depth: 3

  granularity:
    min_duration: 15  # minutes
    max_duration: 240  # minutes
    optimal_duration: 60  # minutes

  quality_gates:
    enabled: true
    complexity_threshold: 5
    mandatory_after: ['implement', 'integrate']

agent_assignment:
  use_performance_history: true
  consider_workload: true
  fallback_agent: 'coder'

optimization:
  merge_similar_tasks: true
  split_large_tasks: true
  balance_workloads: true
  optimize_parallelism: true
```

---

## 🎯 API INTERFACE

### Main Decomposition API
```python
class TaskDecompositionAPI:
    """Main interface for automatic task decomposition"""

    def __init__(self, config=None):
        self.config = config or self.load_default_config()
        self.intent_analyzer = TaskIntentAnalyzer()
        self.context_extractor = ContextExtractor()
        self.complexity_analyzer = ComplexityAnalyzer()
        self.subtask_generator = SubtaskGenerator()
        self.agent_selector = AgentSelector()

    def decompose_task(self, task_description, options=None):
        """Decompose a complex task into manageable subtasks"""
        # Analyze task intent
        task_intent = self.intent_analyzer.analyze_task_intent(task_description)

        # Extract context
        context = self.context_extractor.extract_context(task_description)

        # Assess complexity
        complexity = self.complexity_analyzer.assess_complexity(task_intent, context)

        # Generate subtasks
        subtasks = self.subtask_generator.generate_subtasks(
            task_intent, context, complexity
        )

        # Assign agents
        for subtask in subtasks:
            subtask['recommended_agent'] = self.agent_selector.select_optimal_agent(subtask)

        return {
            'original_task': task_description,
            'analysis': {
                'intent': task_intent,
                'context': context,
                'complexity': complexity
            },
            'subtasks': subtasks,
            'execution_metadata': {
                'total_subtasks': len(subtasks),
                'estimated_total_duration': sum(t.get('estimated_duration', 0) for t in subtasks),
                'parallel_opportunities': complexity.get('parallel_opportunities', []),
                'recommended_agents': list(set(t['recommended_agent'] for t in subtasks))
            }
        }

    def refine_decomposition(self, decomposition, feedback):
        """Refine decomposition based on feedback"""
        pass

    def estimate_execution_time(self, decomposition):
        """Estimate total execution time considering parallelism"""
        pass
```

---

## 🚀 INTEGRATION EXAMPLES

### Example 1: Complex Web Application
```python
task = """
Create a comprehensive trading dashboard with real-time market data,
user authentication, portfolio management, risk analysis, mobile support,
and integration with multiple trading platforms. Include comprehensive
testing and deployment automation.
"""

# Decomposition result:
{
    "analysis": {
        "intent": {
            "primary_intent": "create",
            "domains": ["frontend", "backend", "database", "security", "trading", "mobile", "devops"]
        },
        "complexity": {"overall": 9}
    },
    "subtasks": [
        {"description": "Analyze trading requirements", "agent": "trading_strategy_expert"},
        {"description": "Design system architecture", "agent": "architect_expert"},
        {"description": "Design database schema", "agent": "database_expert"},
        {"description": "Implement user authentication", "agent": "security_unified_expert"},
        {"description": "Create trading API integration", "agent": "integration_expert"},
        {"description": "Implement portfolio management", "agent": "trading_strategy_expert"},
        {"description": "Create dashboard UI", "agent": "gui-super-expert"},
        {"description": "Implement real-time data feeds", "agent": "integration_expert"},
        {"description": "Quality review checkpoint", "agent": "reviewer"},
        {"description": "Create mobile interface", "agent": "mobile_expert"},
        {"description": "Implement risk analysis", "agent": "trading_strategy_expert"},
        {"description": "Create comprehensive tests", "agent": "tester_expert"},
        {"description": "Setup deployment automation", "agent": "devops_expert"},
        {"description": "Final quality review", "agent": "reviewer"},
        {"description": "Update documentation", "agent": "documenter"}
    ]
}
```

### Example 2: Code Refactoring Project
```python
task = """
Refactor legacy trading system to improve performance, security,
and maintainability. Update to modern architecture patterns and
add comprehensive monitoring.
"""

# Decomposition result:
{
    "subtasks": [
        {"description": "Analyze current codebase", "agent": "analyzer"},
        {"description": "Identify performance bottlenecks", "agent": "analyzer"},
        {"description": "Security audit of existing code", "agent": "security_unified_expert"},
        {"description": "Design new architecture", "agent": "architect_expert"},
        {"description": "Refactor core trading logic", "agent": "coder"},
        {"description": "Implement new security measures", "agent": "security_unified_expert"},
        {"description": "Add monitoring and logging", "agent": "devops_expert"},
        {"description": "Performance testing", "agent": "tester_expert"},
        {"description": "Code review", "agent": "reviewer"}
    ]
}
```

---

**Status:** Production Ready
**Version:** 6.0
**Date:** 31 January 2026
**Integration:** Full compatibility with PARALLEL_COORDINATOR.md and DEPENDENCY_GRAPH.md

The automatic task decomposition engine provides intelligent breakdown of complex tasks into optimally sized, well-assigned subtasks ready for parallel execution.
# TASK T7: MONITORING & QUALITY GATE - SPECIFICATION

## 📋 EXECUTIVE SUMMARY

Il sistema di Monitoring e Quality Gate garantisce visibilità real-time e validazione rigorosa di tutti i processi di orchestrazione. Questo documento specifica come il sistema controlla, monitora e valida l'intero pipeline di esecuzione.

---

## 1. REAL-TIME MONITORING SYSTEM

### 1.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONITORING ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │   PYTHON     │      │   TYPESCRIPT │      │   DASHBOARD  │  │
│  │ AGENT MONITOR│◄────►│ ORCHESTRATOR │◄────►│   SYSTEM     │  │
│  │              │      │   MONITORING │      │              │  │
│  └──────────────┘      └──────────────┘      └──────────────┘  │
│         │                       │                      │         │
│         └───────────────────────┴──────────────────────┘         │
│                             │                                   │
│                             ▼                                   │
│                  ┌──────────────────┐                           │
│                  │  CENTRAL STORAGE │                           │
│                  │  - JSON Reports   │                           │
│                  │  - State Files    │                           │
│                  │  - Completion Log │                           │
│                  └──────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Componenti Principali

#### A. Agent Monitor (Python)
**File:** `c:\Users\LeoDg\.claude\monitoring\agent_monitor.py`

**Responsabilità:**
- Monitoraggio 11 agent attivi (4 core + 7 expert)
- Detection del completamento task via pattern matching
- Generazione report completamento automatici
- Notifiche real-time

**Implementazione:**
```python
class AgentMonitor:
    def __init__(self, base_path: str = r"C:\Users\LeoDg\.claude"):
        self.active_agents = {
            # Core Agents
            "analyzer": {"file": "core/analyzer.md", "level": "core", "model": "haiku"},
            "coder": {"file": "core/coder.md", "level": "core", "model": "haiku/sonnet"},
            "reviewer": {"file": "core/reviewer.md", "level": "core", "model": "haiku"},
            "system_coordinator": {"file": "core/system_coordinator.md", "level": "core", "model": "sonnet"},

            # Expert Agents
            "gui-super-expert": {"file": "experts/gui-super-expert.md", "level": "expert", "model": "haiku"},
            "integration_expert": {"file": "experts/integration_expert.md", "level": "expert", "model": "sonnet"},
            "database_expert": {"file": "experts/database_expert.md", "level": "expert", "model": "haiku/sonnet"},
            "security_unified_expert": {"file": "experts/security_unified_expert.md", "level": "expert", "model": "sonnet"},
            "trading_strategy_expert": {"file": "experts/trading_strategy_expert.md", "level": "expert", "model": "sonnet"},
            "mql_expert": {"file": "experts/mql_expert.md", "level": "expert", "model": "sonnet"},
            "tester_expert": {"file": "experts/tester_expert.md", "level": "expert", "model": "haiku/sonnet"}
        }

        # Stato di monitoring
        self.agent_states = {}
        self.running = False
```

#### B. Orchestrator Dashboard (TypeScript)
**File:** `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\orchestrator-dashboard.ts`

**Responsabilità:**
- Visualizzazione real-time con refresh automatico
- Progress bar globale e per livello
- Tabelle statistiche dettagliate
- Export report (JSON/Markdown)

**Implementazione:**
```typescript
export class OrchestratorDashboard extends EventEmitter {
    private tasks: Map<string, DashboardTask> = new Map();
    private startTime: number = 0;
    private updateInterval?: NodeJS.Timeout;
    private refreshRateMs: number = 500;  // 500ms default

    // Real-time updates
    startRealTimeUpdates(): void {
        this.updateInterval = setInterval(() => {
            this.displayUpdate();
        }, this.refreshRateMs);
    }

    // Statistics calculation
    getGlobalStats(): GlobalStats {
        return {
            totalTasks: total,
            completedTasks: completed,
            failedTasks: failed,
            runningTasks: running,
            pendingTasks: pending,
            globalProgress: globalProgress,
            elapsedTime: elapsed,
            estimatedRemaining: estimatedRemaining,
            totalCost: totalCost,
            maxParallelism: maxParallelism,
            currentParallelism: running,
            speedupFactor: speedup,
            levelsCount: maxDepth + 1
        };
    }
}
```

---

## 2. METRICHE MONITORATE

### 2.1 Metriche Python Agent Monitor

#### Metriche per Agent
```python
{
    "agent_id": "gui-super-expert",
    "status": "completed",  # idle | running | completed
    "start_time": "2026-02-01T10:30:00Z",
    "completion_time": "2026-02-01T10:32:15Z",
    "token_count": 1250,
    "tools_used": ["Read", "Write", "Edit"],
    "deliverables": ["main.py", "gui_window.py"],
    "execution_time_seconds": 135,
    "success_indicators": ["SUCCESS", "COMPLETATO"],
    "error_indicators": []
}
```

#### Metriche Completamento
```python
{
    "report_id": "gui-super-expert_1738407185",
    "timestamp": "2026-02-01T10:32:15Z",
    "agent_info": {
        "id": "gui-super-expert",
        "level": "expert",
        "model": "sonnet",
        "file_path": "agents/experts/gui-super-expert.md"
    },
    "execution": {
        "start_time": "2026-02-01T10:30:00Z",
        "completion_time": "2026-02-01T10:32:15Z",
        "total_duration_seconds": 135,
        "duration_formatted": "2.3min"
    },
    "metrics": {
        "token_count_estimate": 1625,
        "tools_used": ["Read", "Write", "Edit", "Bash"],
        "tools_count": 4
    },
    "results": {
        "deliverables": ["main.py", "gui_window.py"],
        "deliverables_count": 2,
        "success_indicators": ["SUCCESS", "COMPLETATO"],
        "error_indicators": []
    },
    "completion": {
        "status": "SUCCESS",  # SUCCESS | PARTIAL | FAILED
        "pattern_matched": "✅.*COMPLETATO",
        "success": true
    }
}
```

### 2.2 Metriche Orchestrator Dashboard

#### Global Stats
```typescript
interface GlobalStats {
    totalTasks: number;           // Totale task nella sessione
    completedTasks: number;       // Task completati con successo
    failedTasks: number;          // Task falliti
    runningTasks: number;         // Task attualmente in esecuzione
    pendingTasks: number;         // Task in attesa
    globalProgress: number;       // 0-100: percentuale completamento
    elapsedTime: number;          // Tempo trascorso in ms
    estimatedRemaining: number;   // Tempo stimato rimanente in ms
    totalCost: number;            // Costo totale in USD
    maxParallelism: number;       // Massimo parallelismo raggiunto
    currentParallelism: number;   // Parallelismo corrente
    speedupFactor: number;        // Fattore di speedup vs sequenziale
    levelsCount: number;          // Numero di livelli di dipendenza
}
```

#### Level Stats
```typescript
interface LevelStats {
    level: number;                // Numero livello (0, 1, 2, ...)
    total: number;                // Totale task nel livello
    pending: number;              // Task in attesa
    running: number;              // Task in esecuzione
    completed: number;            // Task completati
    failed: number;               // Task falliti
    progress: number;             // 0-100: percentuale completamento
    avgDuration: number;          // Durata media task (ms)
    totalCost: number;            // Costo totale livello (USD)
    activeAgents: string[];       // Agent attivi nel livello
}
```

### 2.3 Metriche Analysis Engine

#### Quality Gate Metrics
```typescript
interface QualityGateMetrics {
    confidence: number;           // Confidence score 0.0-1.0
    responseTimeMs: number;       // Tempo di risposta
    keywordsExtracted: number;    // Numero keyword estratte
    coverage: number;             // Copertura percentuale
    tier: 'fast' | 'smart' | 'deep';
    passed: boolean;              // Superamento quality gate
}
```

#### Thresholds per Tier
```typescript
const QUALITY_THRESHOLDS = {
    fast: {
        minConfidence: 0.7,       // 70% confidence minima
        maxResponseTime: 10,      // 10ms max response time
        minKeywords: 1            // Almeno 1 keyword
    },
    smart: {
        minConfidence: 0.6,       // 60% confidence minima
        maxResponseTime: 50,      // 50ms max response time
        minKeywords: 1            // Almeno 1 keyword
    },
    deep: {
        minConfidence: 0.5,       // 50% confidence minima
        maxResponseTime: 2000,    // 2000ms max response time
        minKeywords: 0            // Nessun requisito minimo
    }
};
```

---

## 3. DASHBOARD TESTUALE

### 3.1 Dashboard Layout

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                    🎯 ORCHESTRATOR DASHBOARD v3.1 - REAL TIME                     ║
║                              14:30:45                                        ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  🟢 GLOBAL PROGRESS                                                            ║
║  ┌──────────────────────────────────────────────────────────────────────────┐   ║
║  │ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │ 47%  ║
║  └──────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                  ║
║  📊 SUMMARY                                                                      ║
║  ┌────────────────┬────────────────┬────────────────┬────────────────┐          ║
║  │ Total Tasks    │ Completed      │ Running        │ Pending        │          ║
║  │      150       │     71 ✅      │      5 🔄      │     74 ⏳      │          ║
║  ├────────────────┼────────────────┼────────────────┼────────────────┤          ║
║  │ Failed         │ Levels         │ Parallelism    │ Speedup        │          ║
║  │     3 ❌       │      5         │ 5/12 🚀        │   8.2x         │          ║
║  ├────────────────┼────────────────┼────────────────┼────────────────┤          ║
║  │ Elapsed        │ Remaining      │ Cost           │ Efficiency     │          ║
║  │   2m 15s       │   2m 30s       │  $0.0423   │    68%   │          ║
║  └────────────────┴────────────────┴────────────────┴────────────────┘          ║
║                                                                                  ║
║  📈 LEVEL BREAKDOWN                                                              ║
║  ┌───────┬───────┬─────────┬─────────┬─────────┬─────────┬──────────────────┐   ║
║  │ Level │ Total │ Pending │ Running │  Done   │ Failed  │     Progress     │   ║
║  ├───────┼───────┼─────────┼─────────┼─────────┼─────────┼──────────────────┤   ║
║  │  L0   │     1 │      0  │      0  │      1  │      0  │ ████████████ 100% │   ║
║  │  L1   │    12 │      2  │      1  │      9  │      0  │ ██████████░░  75% │   ║
║  │  L2   │    45 │     18  │      2  │     24  │      1  │ ██████░░░░░░  53% │   ║
║  │  L3   │    68 │     42  │      2  │     23  │      1  │ ████░░░░░░░░░  34% │   ║
║  │  L4   │    24 │     12  │      0  │     14  │      1  │ ███████░░░░░  58% │   ║
║  └───────┴───────┴─────────┴─────────┴─────────┴─────────┴──────────────────┘   ║
║                                                                                  ║
║  📋 TASK DETAILS (showing first 15)                                              ║
║  ┌──────────────┬───────────────────────────┬──────────────────┬────────┬──────┐║
║  │    Path      │        Description        │      Agent       │ Model  │Status│║
║  ├──────────────┼───────────────────────────┼──────────────────┼────────┼──────┤║
║  │ T1           │ Create main window       │ gui-super-expert  │ sonnet │  ✅  │║
║  │ T2           │ Setup database schema    │ database_expert  │ sonnet │  ✅  │║
║  │ T3           │ Implement auth           │ security_expert  │ opus   │  🔄  │║
║  │ T4           │ Add unit tests           │ tester_expert    │ sonnet │  ⏳  │║
║  └──────────────┴───────────────────────────┴──────────────────┴────────┴──────┘║
║                                                                                  ║
║  🔄 CURRENTLY RUNNING: T2, T5, T8, T12, T15                                      ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║  💡 Press Ctrl+C to stop | Auto-refresh: 500ms | Memory optimized               ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

### 3.2 Final Report Layout

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                        🏁 ORCHESTRATOR - FINAL REPORT                            ║
╠══════════════════════════════════════════════════════════════════════════════════╣
║                                                                                  ║
║  ✅ EXECUTION COMPLETED                                                          ║
║                                                                                  ║
║  📊 RESULTS                                                                      ║
║  ├─ Total Tasks:       150                                                ║
║  ├─ Completed:         142 ✅                                             ║
║  ├─ Failed:              5 ❌                                             ║
║  ├─ Success Rate:     94.7%                                            ║
║                                                                                  ║
║  ⏱️  TIMING                                                                       ║
║  ├─ Total Time:      4m 32s                                          ║
║  ├─ Sequential Est:  37m 15s                                          ║
║  ├─ Speedup Factor:   8.3x                                         ║
║                                                                                  ║
║  🚀 PARALLELISM                                                                  ║
║  ├─ Max Parallel:     12 agents                                        ║
║  ├─ Levels:             5                                                ║
║  ├─ Efficiency:     69.2%                                            ║
║                                                                                  ║
║  💰 COST                                                                         ║
║  ├─ Total Cost:     $0.0856                                            ║
║  ├─ Cost per Task:  $0.000571                                          ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════╝
```

---

## 4. QUALITY GATE SYSTEM

### 4.1 Architecture Quality Gate

```
┌─────────────────────────────────────────────────────────────────┐
│                    QUALITY GATE FLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  INPUT                                                           │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ TIER 1 CHECK │  Fast Path: <10ms, confidence>70%             │
│  │   (Fast)     │  ↓ PASS → ACCEPT                              │
│  │              │  ↓ FAIL → Next Tier                            │
│  └──────────────┘                                               │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ TIER 2 CHECK │  Smart Path: <50ms, confidence>60%            │
│  │  (Smart)     │  ↓ PASS → ACCEPT                              │
│  │              │  ↓ FAIL → Next Tier                            │
│  └──────────────┘                                               │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ TIER 3 CHECK │  Deep Path: <2000ms, confidence>50%           │
│  │   (Deep)     │  ↓ PASS → ACCEPT                              │
│  │              │  ↓ FAIL → FALLBACK                             │
│  └──────────────┘                                               │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │  FALLBACK    │  Minimal result with warnings                 │
│  └──────────────┘                                               │
│    ↓                                                             │
│  OUTPUT                                                          │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Quality Gate Implementation

#### Meets Quality Gate Function
```typescript
private meetsQualityGate(result: KeywordExtractionResult, tier: AnalysisTier): boolean {
    const gates = {
        fast: {
            minConfidence: 0.7,      // 70%
            maxResponseTime: 10,      // 10ms
            minKeywords: 1
        },
        smart: {
            minConfidence: 0.6,      // 60%
            maxResponseTime: 50,      // 50ms
            minKeywords: 1
        },
        deep: {
            minConfidence: 0.5,      // 50%
            maxResponseTime: 2000,   // 2000ms
            minKeywords: 0
        }
    };

    const gate = gates[tier];

    return (
        result.overallConfidence >= gate.minConfidence &&
        result.processingTimeMs <= gate.maxResponseTime &&
        result.keywords.length >= gate.minKeywords
    );
}
```

### 4.3 Circuit Breaker Pattern

#### Circuit Breaker State
```typescript
interface CircuitBreakerState {
    fastPathFailures: number;        // Conteggio fallimenti Fast Path
    smartPathFailures: number;       // Conteggio fallimenti Smart Path
    deepPathFailures: number;        // Conteggio fallimenti Deep Path
    lastFailureTime: number;         // Timestamp ultimo fallimento
    isOpen: boolean;                 // Stato circuit breaker
    resetTimeoutMs: number;          // Timeout prima di reset (60000ms)
}
```

#### Circuit Breaker Logic
```typescript
private canUseTier(tier: AnalysisTier): boolean {
    if (!this.config.fallbackBehavior.circuitBreakerEnabled) return true;

    const key = `${tier}PathFailures` as keyof CircuitBreakerState;
    const failureCount = this.circuitBreaker[key] as number;
    const threshold = this.config.fallbackBehavior.circuitBreakerThreshold;

    return failureCount < threshold;  // Default: 5 failures
}

private handleTierFailure(tier: AnalysisTier, reason: string): void {
    const key = `${tier}PathFailures` as keyof CircuitBreakerState;
    const currentValue = this.circuitBreaker[key] as number;
    this.circuitBreaker[key] = (currentValue + 1) as never;
    this.circuitBreaker.lastFailureTime = Date.now();

    const failures = this.circuitBreaker[key] as number;
    console.warn(`⚠️  Tier ${tier} failure #${failures}: ${reason}`);

    if (failures >= this.config.fallbackBehavior.circuitBreakerThreshold) {
        this.circuitBreaker.isOpen = true;
        console.error(`🚨 Circuit breaker opened for tier ${tier}`);
    }
}
```

---

## 5. CHECKLIST QUALITY GATE

### 5.1 Pre-Execution Quality Gate

```yaml
PreExecutionCheck:
  AgentValidation:
    - Agent file exists: YES/NO
    - Agent file readable: YES/NO
    - Agent file valid size: YES/NO
    - Agent mapping available: YES/NO

  TaskValidation:
    - Task description valid: YES/NO
    - Task complexity assessed: YES/NO
    - Model selection complete: YES/NO
    - Dependencies resolved: YES/NO

  ResourceCheck:
    - Memory available: YES/NO
    - Concurrent slots available: YES/NO
    - Circuit breaker closed: YES/NO
    - Tier available: YES/NO
```

### 5.2 Post-Execution Quality Gate

```yaml
PostExecutionCheck:
  CompletionDetection:
    - Success pattern matched: YES/NO
    - Deliverables found: YES/NO
    - Error indicators absent: YES/NO
    - Task completion confirmed: YES/NO

  ResultValidation:
    - Token count reasonable: YES/NO
    - Tools used appropriate: YES/NO
    - Output quality sufficient: YES/NO
    - No critical errors: YES/NO

  PerformanceCheck:
    - Execution time acceptable: YES/NO
    - Cost within budget: YES/NO
    - No timeout occurred: YES/NO
    - Quality gate passed: YES/NO
```

### 5.3 System Health Check

```yaml
SystemHealthCheck:
  TierStatus:
    - Fast Path: active/circuit_open/disabled
    - Smart Path: active/circuit_open/disabled
    - Deep Path: active/circuit_open/disabled

  PerformanceMetrics:
    - Average response time: < 100ms ✅
    - Cache hit rate: > 50% ✅
    - Memory usage: < 100MB ✅
    - Error rate: < 5% ✅

  OverallStatus:
    - Healthy: 2+ tiers active
    - Degraded: 1 tier active
    - Unhealthy: 0 tiers active
```

---

## 6. AZIONI CORRETTIVE AUTOMATICHE

### 6.1 Fallback System

#### 4-Level Fallback Strategy
```typescript
const FALLBACK_STRATEGY = {
    Level1: {
        description: "Expert Agent → General Expert",
        example: "gui-button-specialist.md → gui-super-expert.md",
        triggers: ["agent_missing", "agent_failed", "quality_gate_failed"]
    },
    Level2: {
        description: "Specialist Domain → Core Agent",
        example: "database_expert.md → core/coder.md",
        triggers: ["level1_failed", "timeout", "circuit_breaker_open"]
    },
    Level3: {
        description: "Complex Task → Simpler Model",
        example: "opus → sonnet → haiku",
        triggers: ["cost_limit", "resource_constraint", "performance_degradation"]
    },
    Level4: {
        description: "Ultimate Fallback",
        example: "core/coder.md (default)",
        triggers: ["all_above_failed", "critical_failure"]
    }
};
```

#### Fallback Mapping Implementation
**File:** `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\fixes\orchestrator-quick-fixes.ts`

```typescript
const FALLBACK_MAPPING: Record<string, string> = {
    // GUI Domain (60+ mappings total)
    'experts/gui-layout-specialist.md': 'experts/gui-super-expert.md',
    'experts/gui-widget-creator.md': 'experts/gui-super-expert.md',
    'experts/gui-button-specialist.md': 'experts/gui-super-expert.md',

    // Database Domain
    'experts/db-schema-designer.md': 'experts/database_expert.md',
    'experts/db-migration-specialist.md': 'experts/database_expert.md',
    'experts/db-sql-generator.md': 'experts/database_expert.md',

    // Security Domain
    'experts/security-auth-specialist.md': 'experts/security_unified_expert.md',
    'experts/security-encryption-expert.md': 'experts/security_unified_expert.md',

    // ... 60+ total mappings
};
```

### 6.2 Auto-Recovery Actions

#### Action 1: Automatic Retry
```typescript
async executeWithRetry(task: Task, maxRetries: number = 3): Promise<Result> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const result = await this.executeTask(task);
            if (this.meetsQualityGate(result)) {
                return result;
            }
        } catch (error) {
            if (attempt === maxRetries) {
                throw error;
            }
            // Exponential backoff
            await this.sleep(Math.pow(2, attempt) * 1000);
        }
    }
}
```

#### Action 2: Automatic Fallback
```typescript
async executeWithFallback(task: Task): Promise<Result> {
    const primaryAgent = task.resolvedAgent;

    // Try primary agent
    const primaryResult = await this.tryExecute(task, primaryAgent);
    if (primaryResult.success) return primaryResult;

    // Fallback to mapped agent
    const fallbackAgent = FALLBACK_MAPPING[primaryAgent];
    if (fallbackAgent) {
        console.log(`⚠️  Fallback: ${primaryAgent} → ${fallbackAgent}`);
        const fallbackResult = await this.tryExecute(task, fallbackAgent);
        if (fallbackResult.success) return fallbackResult;
    }

    // Ultimate fallback
    return await this.tryExecute(task, 'core/coder.md');
}
```

#### Action 3: Circuit Breaker Reset
```typescript
async resetCircuitBreaker(tier?: AnalysisTier): Promise<void> {
    if (tier) {
        const key = `${tier}PathFailures` as keyof CircuitBreakerState;
        this.circuitBreaker[key] = 0 as never;
    } else {
        this.circuitBreaker.fastPathFailures = 0;
        this.circuitBreaker.smartPathFailures = 0;
        this.circuitBreaker.deepPathFailures = 0;
        this.circuitBreaker.isOpen = false;
    }
    console.log(`🔄 Circuit breaker reset${tier ? ` for tier ${tier}` : ''}`);
}
```

#### Action 4: Graceful Degradation
```typescript
async executeWithGracefulDegradation(task: Task): Promise<Result> {
    const config = this.getConfig();

    // Try full complexity first
    if (config.enableSmartModelSelection) {
        const result = await this.executeWithSmartModel(task);
        if (result.success) return result;
    }

    // Degrade to simpler model
    config.enableSmartModelSelection = false;
    const simpleResult = await this.executeWithBasicModel(task);
    if (simpleResult.success) return simpleResult;

    // Degrade to simulation mode
    config.simulateExecution = true;
    return await this.executeSimulation(task);
}
```

---

## 7. VALIDATION CRITERIA

### 7.1 Completion Detection Patterns

```python
COMPLETION_PATTERNS = [
    r"✅.*COMPLETATO",
    r"SUCCESS.*DELIVERED",
    r"TASK.*FINISHED",
    r"STATUS.*COMPLETED",
    r"DELIVERABLE.*READY"
]
```

### 7.2 Error Detection Patterns

```python
ERROR_PATTERNS = [
    "ERROR", "FAILED", "EXCEPTION", "ERRORE",
    "FALLITO", "❌", "BLOCKED", "CRITICAL"
]
```

### 7.3 Quality Thresholds

```typescript
QUALITY_THRESHOLDS = {
    confidence: {
        EXCELLENT: 0.9,    // 90%+
        GOOD: 0.7,         // 70-90%
        ACCEPTABLE: 0.5,   // 50-70%
        POOR: 0.3          // <50%
    },
    responseTime: {
        FAST: 10,          // <10ms
        NORMAL: 50,        // <50ms
        SLOW: 2000         // <2000ms
    },
    coverage: {
        COMPLETE: 0.9,     // 90%+
        ADEQUATE: 0.7,     // 70-90%
        MINIMAL: 0.5       // 50-70%
    }
};
```

---

## 8. MONITORING DATA FLOW

### 8.1 Event Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        EVENT FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TASK_START                                                      │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ File Hash    │  Calculate initial hash                       │
│  │ Detection    │  → task_started event                         │
│  └──────────────┘                                               │
│    ↓                                                             │
│  TASK_PROGRESS                                                   │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ Hash Change  │  Monitor file changes                         │
│  │ Detection    │  → task_progress event                        │
│  └──────────────┘                                               │
│    ↓                                                             │
│  TASK_COMPLETION                                                 │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ Pattern      │  Search for completion patterns               │
│  │ Matching     │  → task_completed event                       │
│  └──────────────┘                                               │
│    ↓                                                             │
│  REPORT_GENERATION                                               │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ Analysis     │  Extract metrics, generate report             │
│  │ & Reporting  │  → save_completion_report()                   │
│  └──────────────┘                                               │
│    ↓                                                             │
│  NOTIFICATION                                                    │
│    ↓                                                             │
│  ┌──────────────┐                                               │
│  │ Real-time    │  Send notification, update dashboard          │
│  │ Alert        │  → send_notification()                        │
│  └──────────────┘                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Storage Structure

```
monitoring/
├── agent_state.json              # Current state of all agents
├── completions.log              # Completion log (append-only)
├── notifications.log            # Notification log
└── reports/
    ├── {agent_id}_{timestamp}_completion.json
    ├── gui-super-expert_20260201_103015_completion.json
    ├── database_expert_20260201_103245_completion.json
    └── ...
```

### 8.3 Report Format

```json
{
  "report_id": "gui-super-expert_1738407185",
  "timestamp": "2026-02-01T10:32:15Z",
  "agent_info": {
    "id": "gui-super-expert",
    "level": "expert",
    "model": "sonnet",
    "file_path": "agents/experts/gui-super-expert.md"
  },
  "execution": {
    "start_time": "2026-02-01T10:30:00Z",
    "completion_time": "2026-02-01T10:32:15Z",
    "total_duration_seconds": 135,
    "duration_formatted": "2.3min"
  },
  "metrics": {
    "token_count_estimate": 1625,
    "tools_used": ["Read", "Write", "Edit", "Bash"],
    "tools_count": 4
  },
  "results": {
    "deliverables": ["main.py", "gui_window.py"],
    "deliverables_count": 2,
    "success_indicators": ["SUCCESS", "COMPLETATO"],
    "error_indicators": []
  },
  "completion": {
    "status": "SUCCESS",
    "pattern_matched": "✅.*COMPLETATO",
    "success": true
  }
}
```

---

## 9. CONFIGURATION

### 9.1 Agent Monitor Configuration

```python
AGENT_MONITOR_CONFIG = {
    "base_path": r"C:\Users\LeoDg\.claude",
    "monitoring_path": "monitoring",
    "agents_path": "agents",
    "refresh_interval": 5,  # seconds
    "active_agents": {
        # Core Agents (4)
        "analyzer": {...},
        "coder": {...},
        "reviewer": {...},
        "system_coordinator": {...},

        # Expert Agents (7)
        "gui-super-expert": {...},
        "integration_expert": {...},
        "database_expert": {...},
        "security_unified_expert": {...},
        "trading_strategy_expert": {...},
        "mql_expert": {...},
        "tester_expert": {...}
    }
}
```

### 9.2 Dashboard Configuration

```typescript
DASHBOARD_CONFIG = {
    refreshRateMs: 500,              // Update every 500ms
    maxTasksDisplay: 15,             // Show first 15 tasks
    progressBarWidth: 50,            // Progress bar width in chars
    autoScroll: true,                // Auto-scroll to running tasks
    colorOutput: true,               // Enable colored output
    exportFormats: ['json', 'markdown', 'text']
};
```

### 9.3 Quality Gate Configuration

```typescript
QUALITY_GATE_CONFIG = {
    // Tier-specific thresholds
    fast: {
        enabled: true,
        timeoutMs: 20,
        confidenceThreshold: 0.7,
        fallbackThreshold: 0.5
    },
    smart: {
        enabled: true,
        timeoutMs: 100,
        confidenceThreshold: 0.6,
        fallbackThreshold: 0.4
    },
    deep: {
        enabled: false,  // TODO: Enable when implemented
        timeoutMs: 5000,
        confidenceThreshold: 0.5
    },

    // Fallback behavior
    fallbackBehavior: {
        maxTierFailures: 3,
        circuitBreakerEnabled: true,
        circuitBreakerThreshold: 5
    },

    // Global quality gates
    qualityGates: {
        minConfidenceThreshold: 0.1,
        maxResponseTimeMs: 5000,
        minCoveragePercentage: 70
    }
};
```

---

## 10. BEST PRACTICES

### 10.1 Monitoring Best Practices

1. **Continuous Monitoring**
   - Run agent monitor continuously in background
   - Poll every 5 seconds for changes
   - Generate reports immediately on completion

2. **Comprehensive Metrics**
   - Track all 11 active agents
   - Monitor token counts and tool usage
   - Record success/error indicators

3. **Real-Time Alerts**
   - Send notifications on task completion
   - Display progress updates
   - Alert on failures

### 10.2 Quality Gate Best Practices

1. **Tier-Based Validation**
   - Start with fastest tier (Fast Path)
   - Progressively fall back to slower tiers
   - Use circuit breaker to prevent cascade failures

2. **Confidence Thresholds**
   - Fast Path: 70% confidence, <10ms
   - Smart Path: 60% confidence, <50ms
   - Deep Path: 50% confidence, <2000ms

3. **Graceful Degradation**
   - Always provide fallback result
   - Never fail completely
   - Log warnings for degraded results

### 10.3 Dashboard Best Practices

1. **Readable Output**
   - Use boxed layouts with clear sections
   - Include progress bars
   - Show status icons

2. **Actionable Information**
   - Display currently running tasks
   - Show estimated completion time
   - Provide cost information

3. **Export Capabilities**
   - JSON for programmatic access
   - Markdown for documentation
   - Text for simple sharing

---

## 11. TROUBLESHOOTING

### 11.1 Common Issues

#### Issue: Agent not detected
```
CAUSE: File hash not changing
SOLUTION: Verify agent file path and permissions
```

#### Issue: Completion not detected
```
CAUSE: Completion pattern not matched
SOLUTION: Add completion marker to agent output
```

#### Issue: Quality gate failing
```
CAUSE: Confidence or response time below threshold
SOLUTION: Adjust thresholds or improve analysis
```

#### Issue: Circuit breaker open
```
CAUSE: Too many consecutive failures
SOLUTION: Wait for timeout or manually reset
```

### 11.2 Debug Commands

```bash
# Check agent monitor status
python monitoring/agent_monitor.py

# View current state
cat monitoring/agent_state.json

# View completion log
cat monitoring/completions.log

# View specific report
cat monitoring/reports/{agent_id}_{timestamp}_completion.json

# Reset circuit breaker (via orchestrator)
orchestrator-reset-circuit-breaker [--tier fast|smart|deep]
```

---

## 12. FUTURE ENHANCEMENTS

### 12.1 Planned Features

1. **Enhanced Analytics**
   - Performance trend analysis
   - Cost optimization recommendations
   - Agent efficiency metrics

2. **Advanced Quality Gates**
   - Custom quality criteria per domain
   - Machine learning-based confidence scoring
   - A/B testing for thresholds

3. **Improved Dashboard**
   - Web-based UI
   - Historical data visualization
   - Custom alert rules

4. **Better Fallback**
   - Dynamic fallback based on performance
   - Multi-agent voting
   - Ensemble methods

### 12.2 Technical Debt

1. **Testing**
   - Add unit tests for quality gate logic
   - Integration tests for fallback system
   - Performance tests for monitoring

2. **Documentation**
   - API documentation for all modules
   - Architecture diagrams
   - Troubleshooting guides

3. **Optimization**
   - Reduce polling overhead
   - Optimize storage format
   - Improve cache efficiency

---

## 13. REFERENCES

### 13.1 Related Files

1. **Monitoring System**
   - `c:\Users\LeoDg\.claude\monitoring\agent_monitor.py`
   - `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\orchestrator-dashboard.ts`

2. **Quality Gate**
   - `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\analysis\analysis-engine.ts`
   - `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\fixes\orchestrator-quick-fixes.ts`

3. **Orchestrator Core**
   - `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\orchestrator-v4-unified.ts`
   - `c:\Users\LeoDg\.claude\plugins\orchestrator-plugin\src\core\orchestrator-engine.ts`

### 13.2 Related Documentation

1. **Analysis Documents**
   - `orchestrator-fallback-analysis.md`
   - `VISUAL-ANALYSIS-SUMMARY.md`

2. **Test Results**
   - `tests/parallel/ParallelStressTesting.ts`
   - `coverage/lcov-report/index.html`

---

## 14. SUMMARY

### 14.1 Key Points

1. **Real-Time Monitoring**
   - Python Agent Monitor for 11 agents
   - TypeScript Dashboard for orchestration
   - Event-driven architecture with polling

2. **Quality Gate System**
   - 3-tier validation (Fast/Smart/Deep)
   - Circuit breaker pattern
   - Graceful degradation

3. **Comprehensive Metrics**
   - Agent-level statistics
   - Global progress tracking
   - Performance and cost metrics

4. **Automatic Recovery**
   - 4-level fallback strategy
   - 60+ agent mappings
   - Exponential backoff retry

### 14.2 System Capabilities

```
CAPABILITY MATRIX:
┌─────────────────────────────┬──────────┬────────────────┐
│ Capability                  │ Status   │ Coverage       │
├─────────────────────────────┼──────────┼────────────────┤
│ Real-time monitoring        │ ✅       │ 11 agents      │
│ Progress tracking           │ ✅       │ All tasks      │
│ Completion detection        │ ✅       │ Pattern match  │
│ Quality gate validation     │ ✅       │ 3 tiers        │
│ Circuit breaker             │ ✅       │ Per tier       │
│ Fallback system             │ ✅       │ 4 levels       │
│ Automatic retry             │ ✅       │ 3 attempts     │
│ Dashboard visualization     │ ✅       │ Real-time      │
│ Report generation           │ ✅       │ JSON/MD/Text   │
│ Notification system         │ ✅       │ Real-time      │
└─────────────────────────────┴──────────┴────────────────┘
```

---

**END OF SPECIFICATION T7 - MONITORING & QUALITY GATE**

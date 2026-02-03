# Piano Sviluppo Plugin Orchestrator

## Obiettivo
Convertire il sistema orchestrator esistente (730KB di agent files) in un plugin Claude Code che automatizza completamente la selezione degli agent, gestisce parallelismo complesso, e documenta tutto automaticamente.

## Architettura di Alto Livello

### Struttura Plugin
```
Sviluppo Plugin/Orchestrator/
├── src/
│   ├── core/orchestrator-engine.ts        # Logica principale orchestrazione
│   ├── analysis/keyword-extractor.ts      # Estrae keyword da richieste utente
│   ├── routing/agent-router.ts             # Mappa keyword → agent files
│   ├── execution/task-launcher.ts          # Wrapper intelligente Task tool
│   ├── tracking/progress-tracker.ts        # Tracking progresso real-time
│   └── documentation/auto-documenter.ts   # Documentazione automatica
├── config/
│   ├── agent-registry.json                # Registry 20+ agent con metadata
│   ├── keyword-mappings.json              # Mappature keyword → expert
│   └── model-defaults.json                # Selezione modelli ottimizzata
├── docs/
│   ├── PRD.md                             # Product Requirements Document
│   ├── TECHNICAL_SPEC.md                  # Specifiche tecniche dettagliate
│   └── USER_GUIDE.md                      # Guida utente
└── planning/
    ├── todolist.md                        # Development todolist
    ├── CONTEXT_HISTORY.md                 # Storico sviluppo
    └── claude.me                          # File progetto Claude
```

### Integrazione con Sistema Esistente

**File Critici da Utilizzare:**
- `/agents/core/orchestrator.md` (118KB) - Logica orchestrazione completa da portare
- `/agents/system/PROTOCOL.md` - Formato obbligatorio comunicazione agent
- `/agents/experts/*.md` (15 expert) - Definizioni specializzazioni da parsare
- `/agents/INDEX.md` - Registry master di tutti i 20+ agent

**Pattern di Integrazione:**
1. Plugin wrapper attorno al Task tool esistente
2. Parsing automatico degli agent .md files per estrarre specializzazioni
3. Compliance obbligatoria con PROTOCOL.md per tutte le comunicazioni
4. Zero modifiche ai file agent esistenti

## Implementazione Fasi

### Fase 1: Setup Progetto (Settimana 1)
**Obiettivo:** Struttura base e documentazione iniziale

**Task Specifici:**
1. Creare struttura cartelle `Sviluppo Plugin/Orchestrator/`
2. Scrivere PRD completo con objectives e success metrics
3. Creare `agent-registry.json` da `/agents/INDEX.md` + exploration dei 20 agent
4. Creare `keyword-mappings.json` da analisi orchestrator.md sezione mappature
5. Setup build system TypeScript con configurazione appropriata

**Deliverable:** Struttura progetto completa + documentazione base

### Fase 2: Core Engine (Settimana 2-3)
**Obiettivo:** Implementare orchestrazione core

**Task Specifici:**
1. `keyword-extractor.ts` - Estrae domini/keyword da testo utente
2. `agent-router.ts` - Implementa mappature keyword → agent file path
3. `model-selector.ts` - Logic haiku/sonnet/opus selection con escalation
4. `dependency-graph.ts` - Risolve dipendenze task per parallelismo ottimale
5. `orchestrator-engine.ts` - Main coordinator che lega tutti i componenti

**Deliverable:** Core orchestration funzionante con test coverage 80%

### Fase 3: Execution & Progress (Settimana 4)
**Obiettivo:** Esecuzione task e tracking progresso

**Task Specifici:**
1. `task-launcher.ts` - Wrapper Task tool che invia agent file content + task description
2. `progress-tracker.ts` - Real-time tracking con callback per UI updates
3. `result-aggregator.ts` - Parse PROTOCOL.md compliant responses e merge
4. `escalation-handler.ts` - Auto-escalation modelli su failure patterns
5. Integration testing con agent files reali

**Deliverable:** Sistema di esecuzione completo con error handling

### Fase 4: UI & Documentation (Settimana 5)
**Obiettivo:** User experience e auto-documentazione

**Task Specifici:**
1. Command interface `/orchestrate` con preview e opzioni
2. Tabella 9-colonne agent plan (formato orchestrator.md esistente)
3. Progress indicators visivi per CLI
4. `auto-documenter.ts` - Implementa REGOLA #5 (documentazione obbligatoria)
5. Integration con documenter agent automatico

**Deliverable:** UX completa + auto-documentation funzionante

### Fase 5: Deployment (Settimana 6)
**Obiettivo:** Deploy e testing production

**Task Specifici:**
1. Plugin manifest (.claude-plugin/plugin.json)
2. Deploy script per installazione in `.claude/plugins/`
3. End-to-end testing con workflow reali
4. Performance optimization e cost tracking
5. Documentazione deployment completa

**Deliverable:** Plugin pronto per produzione

## Specifiche Tecniche Chiave

### User Experience Target
```bash
# Invece di orchestrazione manuale complessa:
USER: /orchestrate "Add dark mode toggle to settings GUI"

PLUGIN:
🎯 ORCHESTRATOR PLUGIN v1.0 - Analyzing request...

📊 REQUEST ANALYSIS
├─ Keywords: GUI, settings, toggle, dark mode
├─ Domains: UI/UX, Configuration
├─ Complexity: Medium
├─ Files: 3-5
└─ Est. time: 12-15 min

🤖 EXECUTION PLAN
| # | Task | Agent Expert File | Model | Depends | Est. |
|---|------|-------------------|-------|---------|------|
| T1 | Analyze settings module | core/analyzer.md | haiku | - | 2m |
| T2 | Design dark mode arch | experts/architect_expert.md | opus | T1 | 3m |
| T3 | Implement UI toggle | experts/gui-super-expert.md | sonnet | T2 | 4m |
| T4 | Theme persistence | experts/database_expert.md | sonnet | T2 | 3m |
| T5 | Update styles | core/coder.md | sonnet | T3,T4 | 3m |
| T6 | Test implementation | experts/tester_expert.md | sonnet | T5 | 2m |
| T7 | Document changes | core/documenter.md | haiku | T6 | 1m |

Total: 7 agents | 3 parallel batches | ~18 min | Est. cost: $0.15

Proceed? (Y/n): Y

⚡ EXECUTING...
[Real-time progress tracking]

✨ ORCHESTRATION COMPLETE
📊 Success: 7/7 | Time: 16.2m | Cost: $0.13 | Files: 4 modified
```

### API Design Core
```typescript
interface OrchestratorEngine {
  // Main entry point
  orchestrate(request: string, options?: OrchestratorOptions): Promise<OrchestratorResult>;

  // Preview senza esecuzione
  preview(request: string): Promise<ExecutionPlan>;

  // Resume da failure
  resume(sessionId: string): Promise<OrchestratorResult>;
}

interface ExecutionPlan {
  tasks: Task[];
  dependencies: DependencyGraph;
  parallelBatches: Task[][];
  estimatedCost: number;
  estimatedTime: number;
}

interface Task {
  id: string;
  description: string;
  agentFile: string;                // e.g., "experts/gui-super-expert.md"
  model: 'haiku' | 'sonnet' | 'opus';
  dependencies: string[];
  specialization: string;
}
```

### Integration Points

**1. Task Tool Wrapper**
```typescript
// Plugin trasforma richiesta utente in chiamata Task tool ottimizzata
async launchTask(task: Task): Promise<TaskResult> {
  const agentContent = await readFile(task.agentFile);
  const instructions = `${agentContent}\n\nTASK: ${task.description}\n\nFollow PROTOCOL.md for output.`;

  return await TaskTool({
    subagent_type: mapToSubagentType(task.agentFile),
    instructions: instructions,
    model: task.model,
    agent_id: generateUniqueId()
  });
}
```

**2. PROTOCOL.md Compliance**
```typescript
interface ProtocolValidator {
  // Parse response secondo PROTOCOL.md format
  parseResponse(response: string): {
    header: { agent: string; taskId: string; status: string; model: string };
    summary: string;
    filesModified: string[];
    issues: Issue[];
    handoff: { to: string; context: string };
  }
}
```

**3. Agent File Parsing**
```typescript
interface AgentFileLoader {
  // Carica e parsa agent .md files per estrarre metadata
  loadAgent(path: string): {
    name: string;
    specialization: string;
    keywords: string[];
    defaultModel: string;
    instructions: string;
  }
}
```

## Configurazione e Customizzazione

### agent-registry.json (Generato da INDEX.md)
```json
{
  "core": [
    {
      "name": "orchestrator",
      "file": "core/orchestrator.md",
      "role": "Central coordination",
      "keywords": ["coordinate", "orchestrate", "manage"],
      "defaultModel": "sonnet"
    },
    {
      "name": "analyzer",
      "file": "core/analyzer.md",
      "role": "Code exploration",
      "keywords": ["analyze", "explore", "search", "find"],
      "defaultModel": "haiku"
    }
  ],
  "experts": [
    {
      "name": "gui-super-expert",
      "file": "experts/gui-super-expert.md",
      "role": "UI/UX specialist",
      "keywords": ["gui", "ui", "interface", "widget", "pyqt", "layout"],
      "defaultModel": "sonnet"
    },
    {
      "name": "database_expert",
      "file": "experts/database_expert.md",
      "role": "Database specialist",
      "keywords": ["database", "sql", "query", "schema", "sqlite"],
      "defaultModel": "sonnet"
    }
    // ... tutti i 20+ agent
  ]
}
```

### keyword-mappings.json (Estratto da orchestrator.md)
```json
{
  "gui": ["gui-super-expert"],
  "database": ["database_expert"],
  "security": ["security_unified_expert"],
  "trading": ["trading_strategy_expert", "mql_expert"],
  "api": ["integration_expert"],
  "test": ["tester_expert"],
  "architecture": ["architect_expert"]
}
```

## Verifica End-to-End

### Test Scenario 1: Simple Request
```bash
# Input
/orchestrate "Fix typo in README.md"

# Expected:
- 1 task to core/coder.md
- Model: haiku (simple task)
- No dependencies
- Auto-document with core/documenter.md
- Total: 2 agents, ~3 minutes
```

### Test Scenario 2: Complex Multi-Domain
```bash
# Input
/orchestrate "Add OAuth2 login with Google and secure user session storage"

# Expected:
- Security domain: experts/security_unified_expert.md
- Social login: experts/social_identity_expert.md
- Database: experts/database_expert.md
- Architecture: experts/architect_expert.md
- Integration: experts/integration_expert.md
- Testing: experts/tester_expert.md
- Documentation: core/documenter.md
# Total: 7 agents, multiple parallel batches, ~25-30 minutes
```

### Test Scenario 3: Error Recovery & Escalation
```bash
# Input: Complex GUI task that fails with sonnet

# Expected:
- Task launches with experts/gui-super-expert.md + sonnet
- Fails 2 times (complex layout logic)
- Auto-escalates to opus
- Succeeds with opus
- Cost tracking shows escalation impact
- Final report mentions escalation reasoning
```

### Success Metrics
- **Agent Selection Accuracy**: ≥95% correct domain expert chosen
- **Cost Optimization**: ≥30% reduction vs. manual orchestration
- **Parallelism Efficiency**: ≥80% of eligible tasks run in parallel
- **User Commands**: 1 command `/orchestrate` vs. 5-10 manual commands
- **Documentation Coverage**: 100% automatic documentation via REGOLA #5

### Validation Checklist
- [ ] All 20+ agent files parsed correctly
- [ ] PROTOCOL.md compliance enforced
- [ ] Keyword mappings cover all domains
- [ ] Model escalation logic functional
- [ ] Progress tracking real-time updates
- [ ] Cost tracking accurate
- [ ] Auto-documentation generates proper files
- [ ] Error recovery handles all failure modes
- [ ] Integration with Task tool seamless
- [ ] Plugin installable via standard process

## File di Output Previsti

Al completamento, il plugin genererà automaticamente:
- `C:\Users\LeoDg\.claude\Sviluppo Plugin\Orchestrator\` - Progetto completo
- `C:\Users\LeoDg\.claude\plugins\orchestrator-plugin\` - Plugin installato
- Documentazione completa (PRD, specs, user guide)
- Test suite completa con coverage ≥85%
- Examples e benchmarks di performance

Questo piano trasforma completamente l'esperienza utente da gestione manuale complessa di agent multipli a un singolo comando che automatizza intelligentemente l'intera orchestrazione.
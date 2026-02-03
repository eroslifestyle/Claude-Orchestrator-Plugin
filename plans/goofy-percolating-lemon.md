# PIANO: Sistema Multi-Agent Parallelo REALE

## OBIETTIVO PRINCIPALE
**Ridurre drasticamente i tempi di sviluppo** attraverso:
- Decomposizione automatica di ogni richiesta in N task
- Esecuzione SIMULTANEA di tutti i task indipendenti
- Rispetto di dipendenze e gerarchie (L0 → L1 → L2)
- Aggregazione intelligente dei risultati

---

## ARCHITETTURA DI ESECUZIONE

```
RICHIESTA UTENTE: "Crea sistema auth con GUI, DB e API"
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  FASE 1: DECOMPOSIZIONE (Orchestrator)                      │
│  Analizza richiesta → Identifica domini → Crea task tree    │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ WAVE 1          │  │ WAVE 1          │  │ WAVE 1          │
│ (PARALLELO)     │  │ (PARALLELO)     │  │ (PARALLELO)     │
│                 │  │                 │  │                 │
│ T1: Analyze DB  │  │ T2: Analyze GUI │  │ T3: Analyze API │
│ haiku           │  │ haiku           │  │ haiku           │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │ SYNC POINT
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ WAVE 2          │  │ WAVE 2          │  │ WAVE 2          │
│ (PARALLELO)     │  │ (PARALLELO)     │  │ (PARALLELO)     │
│                 │  │                 │  │                 │
│ T4: Impl DB     │  │ T5: Impl GUI    │  │ T6: Impl API    │
│ database_expert │  │ gui_expert      │  │ integration_exp │
│ sonnet          │  │ sonnet          │  │ sonnet          │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         │      ┌─────────────┼─────────────┐      │
         │      ▼             ▼             ▼      │
         │ ┌─────────┐  ┌─────────┐  ┌─────────┐   │
         │ │ SUB T4a │  │ SUB T5a │  │ SUB T6a │   │
         │ │ L2 spec │  │ L2 spec │  │ L2 spec │   │
         │ └─────────┘  └─────────┘  └─────────┘   │
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │ SYNC POINT
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ WAVE 3: INTEGRATION                                         │
│ T7: architect_expert (opus) - Integra tutto                 │
└─────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ WAVE 4          │  │ WAVE 4          │  │ WAVE 4          │
│ (PARALLELO)     │  │ (PARALLELO)     │  │ (PARALLELO)     │
│                 │  │                 │  │                 │
│ T8: Security    │  │ T9: Testing     │  │ T10: Review     │
│ security_expert │  │ tester_expert   │  │ reviewer        │
│ sonnet          │  │ sonnet          │  │ sonnet          │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ WAVE 5: DOCUMENTAZIONE (SEMPRE ULTIMO)                      │
│ T11: documenter (haiku) - Aggiorna docs                     │
└─────────────────────────────────────────────────────────────┘
```

---

## COME FUNZIONA IL PARALLELISMO

### Regola Fondamentale Claude Code
> "If you intend to call multiple tools and there are no dependencies between them,
> make all independent tool calls in parallel."

**IMPLEMENTAZIONE**: Un singolo messaggio con MULTIPLE Task tool calls

```
// WAVE 1 - Lancio simultaneo
<tool_calls>
  <Task subagent="Explore" prompt="Analizza schema DB per auth..." model="haiku"/>
  <Task subagent="Explore" prompt="Analizza GUI per login form..." model="haiku"/>
  <Task subagent="Explore" prompt="Analizza API endpoints auth..." model="haiku"/>
</tool_calls>

// Attendi completamento WAVE 1

// WAVE 2 - Lancio simultaneo (dipende da WAVE 1)
<tool_calls>
  <Task subagent="general-purpose" prompt="[DB Expert] Implementa schema..." model="sonnet"/>
  <Task subagent="general-purpose" prompt="[GUI Expert] Implementa form..." model="sonnet"/>
  <Task subagent="general-purpose" prompt="[API Expert] Implementa endpoints..." model="sonnet"/>
</tool_calls>
```

---

## DECOMPOSIZIONE AUTOMATICA

### Input: Richiesta Utente
```
"Crea sistema di autenticazione con login, registrazione,
 refresh token, GUI PyQt5 e persistenza SQLite"
```

### Output: Task Tree
```json
{
  "request": "Sistema autenticazione completo",
  "complexity": "alta",
  "domains": ["security", "gui", "database", "api"],
  "waves": [
    {
      "id": "W1",
      "name": "Analysis",
      "parallel": true,
      "tasks": [
        {"id": "T1", "domain": "database", "action": "analyze", "model": "haiku"},
        {"id": "T2", "domain": "gui", "action": "analyze", "model": "haiku"},
        {"id": "T3", "domain": "security", "action": "analyze", "model": "haiku"},
        {"id": "T4", "domain": "api", "action": "analyze", "model": "haiku"}
      ]
    },
    {
      "id": "W2",
      "name": "Implementation",
      "parallel": true,
      "depends_on": ["W1"],
      "tasks": [
        {"id": "T5", "domain": "database", "expert": "database_expert", "model": "sonnet"},
        {"id": "T6", "domain": "gui", "expert": "gui-super-expert", "model": "sonnet"},
        {"id": "T7", "domain": "security", "expert": "security_unified_expert", "model": "sonnet"},
        {"id": "T8", "domain": "api", "expert": "integration_expert", "model": "sonnet"}
      ]
    },
    {
      "id": "W3",
      "name": "Integration",
      "parallel": false,
      "depends_on": ["W2"],
      "tasks": [
        {"id": "T9", "domain": "architecture", "expert": "architect_expert", "model": "opus"}
      ]
    },
    {
      "id": "W4",
      "name": "Validation",
      "parallel": true,
      "depends_on": ["W3"],
      "tasks": [
        {"id": "T10", "domain": "security", "action": "review", "model": "sonnet"},
        {"id": "T11", "domain": "testing", "expert": "tester_expert", "model": "sonnet"},
        {"id": "T12", "domain": "review", "expert": "reviewer", "model": "sonnet"}
      ]
    },
    {
      "id": "W5",
      "name": "Documentation",
      "parallel": false,
      "depends_on": ["W4"],
      "tasks": [
        {"id": "T13", "domain": "docs", "expert": "documenter", "model": "haiku"}
      ]
    }
  ]
}
```

---

## FASI DI IMPLEMENTAZIONE

### FASE 1: Pulizia Sistema (10 min)
- [x] Identificare copie duplicate
- [ ] Eliminare: `orchestrator-plugin-workspace/`, `projects/sviluppo-plugin/Orchestrator/`
- [ ] Mantenere: `plugins/orchestrator-plugin/`, `agents/`

### FASE 2: Creare Decomposer (30 min)
**File:** `skills/orchestrator/decomposer.md`

Logica per:
1. Estrarre keywords dalla richiesta
2. Identificare domini coinvolti
3. Creare task tree con dipendenze
4. Assegnare expert e model a ogni task

### FASE 3: Creare Wave Executor (40 min)
**File:** `skills/orchestrator/wave-executor.md`

Logica per:
1. Prendere task tree dal decomposer
2. Raggruppare task per wave (dipendenze)
3. Per ogni wave: lanciare TUTTI i task in parallelo
4. Attendere completamento wave
5. Passare a wave successiva

### FASE 4: Creare Expert Injector (20 min)
**File:** `skills/orchestrator/expert-injector.md`

Logica per:
1. Per ogni task, caricare file expert appropriato
2. Iniettare contenuto expert nel prompt del Task
3. Selezionare subagent_type corretto (Explore/general-purpose/Plan)

### FASE 5: Aggiornare Hook Principale (20 min)
**File:** `.claude-plugin/hooks/auto-orchestrate.md`

Modificare per:
1. Intercettare OGNI richiesta
2. Chiamare decomposer
3. Chiamare wave executor
4. Mostrare progress in tempo reale

### FASE 6: Test End-to-End (30 min)
- Test con richiesta semplice (1 dominio)
- Test con richiesta media (2-3 domini)
- Test con richiesta complessa (4+ domini)
- Verificare parallelismo reale

---

## FILE DA CREARE

| File | Scopo | Priorità |
|------|-------|----------|
| `skills/orchestrator/SKILL.md` | Entry point skill | ALTA |
| `skills/orchestrator/decomposer.md` | Scompone richiesta in task | ALTA |
| `skills/orchestrator/wave-executor.md` | Esegue wave parallele | ALTA |
| `skills/orchestrator/expert-injector.md` | Inietta contenuto expert | MEDIA |
| `config/domain-mapping.json` | Mappa domini → expert | MEDIA |

---

## ESEMPIO DI ESECUZIONE REALE

### Input
```
/orchestrator Implementa sistema trading con GUI, connessione MT5,
risk management e logging su SQLite
```

### Output Atteso

```
🎯 ORCHESTRATOR V7 - ESECUZIONE PARALLELA

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DECOMPOSIZIONE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Richiesta: Sistema trading completo
Domini: GUI, MQL/MT5, Trading, Database
Task totali: 12
Waves: 5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WAVE 1: ANALYSIS (4 task paralleli)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T1] Analyze GUI structure      → haiku    ▶️ RUNNING
[T2] Analyze MT5 connection     → haiku    ▶️ RUNNING
[T3] Analyze risk requirements  → haiku    ▶️ RUNNING
[T4] Analyze DB schema          → haiku    ▶️ RUNNING

... 2 secondi dopo ...

[T1] Analyze GUI structure      → haiku    ✅ DONE
[T2] Analyze MT5 connection     → haiku    ✅ DONE
[T3] Analyze risk requirements  → haiku    ✅ DONE
[T4] Analyze DB schema          → haiku    ✅ DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WAVE 2: IMPLEMENTATION (4 task paralleli)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T5] Impl GUI (gui-super-expert)     → sonnet  ▶️ RUNNING
[T6] Impl MT5 (mql_expert)           → sonnet  ▶️ RUNNING
[T7] Impl Risk (trading_strategy)    → sonnet  ▶️ RUNNING
[T8] Impl DB (database_expert)       → sonnet  ▶️ RUNNING

... 8 secondi dopo ...

[T5-T8] ✅ ALL DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WAVE 3: INTEGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T9] Integration (architect_expert)  → opus    ✅ DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WAVE 4: VALIDATION (3 task paralleli)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T10] Security review    → sonnet  ✅ DONE
[T11] Testing            → sonnet  ✅ DONE
[T12] Code review        → sonnet  ✅ DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WAVE 5: DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T13] Documentation (documenter)     → haiku   ✅ DONE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 RIEPILOGO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task completati: 13/13
Tempo totale: 18 secondi
Tempo sequenziale stimato: 65 secondi
SPEEDUP: 3.6x

Expert utilizzati:
- gui-super-expert, mql_expert, trading_strategy_expert
- database_expert, architect_expert, security_unified_expert
- tester_expert, reviewer, documenter
```

---

## ESEMPIO: 10 FIX SIMULTANEI

### Scenario
```
Utente: "Fix questi 10 bug nel modulo trading"
- Bug 1: Calcolo errato position size
- Bug 2: GUI non aggiorna balance
- Bug 3: Query lenta su trade history
- Bug 4: JWT scade senza refresh
- Bug 5: Errore di arrotondamento pip
- Bug 6: Memory leak in chart
- Bug 7: Timeout su API call
- Bug 8: Colori sbagliati dark mode
- Bug 9: Log non scrive su file
- Bug 10: Test fallisce su mock
```

### Analisi Dipendenze
```
INDIPENDENTI (possono essere paralleli):
├── Bug 1 (trading logic)     → trading_strategy_expert
├── Bug 2 (GUI)               → gui-super-expert
├── Bug 3 (database)          → database_expert
├── Bug 4 (security)          → security_unified_expert
├── Bug 5 (trading logic)     → trading_strategy_expert
├── Bug 6 (GUI)               → gui-super-expert
├── Bug 7 (API)               → integration_expert
├── Bug 8 (GUI)               → gui-super-expert
├── Bug 9 (logging)           → coder
└── Bug 10 (testing)          → tester_expert

DIPENDENZE TROVATE:
└── Nessuna! Tutti i bug sono in moduli diversi
```

### Esecuzione
```
⚡ WAVE 1: FIX PARALLELI (10 task simultanei!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[F1]  Position size calc    → trading_strategy  → sonnet  ▶️
[F2]  GUI balance update    → gui-super-expert  → sonnet  ▶️
[F3]  Query optimization    → database_expert   → sonnet  ▶️
[F4]  JWT refresh           → security_expert   → sonnet  ▶️
[F5]  Pip rounding          → trading_strategy  → sonnet  ▶️
[F6]  Memory leak fix       → gui-super-expert  → sonnet  ▶️
[F7]  API timeout           → integration_exp   → sonnet  ▶️
[F8]  Dark mode colors      → gui-super-expert  → haiku   ▶️
[F9]  File logging          → coder             → haiku   ▶️
[F10] Test mock fix         → tester_expert     → sonnet  ▶️

... tutti in esecuzione simultanea ...

⚡ WAVE 2: REVIEW (dopo che TUTTI i fix sono completati)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[R1] Review fix F1-F10      → reviewer          → sonnet  ▶️

⚡ WAVE 3: TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[T1] Run test suite         → tester_expert     → sonnet  ▶️

RISULTATO: 10 fix in ~12 secondi invece di ~120 secondi sequenziali
SPEEDUP: 10x
```

### Se ci fossero Dipendenze
```
Esempio: Bug 2 (GUI balance) dipende da Bug 1 (calcolo position size)

WAVE 1: [F1, F3, F4, F5, F6, F7, F8, F9, F10]  → 9 paralleli
WAVE 2: [F2]                                    → dipende da F1
WAVE 3: [Review, Test]
```

---

## VANTAGGI DEL SISTEMA

| Aspetto | Sequenziale | Parallelo Multi-Wave |
|---------|-------------|---------------------|
| Task 4 domini | ~60 sec | ~15 sec |
| Utilizzo expert | 1 alla volta | 4+ simultanei |
| Speedup | 1x | 3-5x |
| Scalabilità | Lineare | Costante per wave |

---

## VERIFICA FINALE

### Checklist
- [ ] Decomposizione automatica funziona
- [ ] Wave executor lancia Task in parallelo (verificare con log)
- [ ] Expert files vengono caricati e iniettati
- [ ] Dipendenze rispettate (wave 2 aspetta wave 1)
- [ ] Model selection intelligente (haiku/sonnet/opus)
- [ ] Documenter sempre ultimo
- [ ] Progress mostrato in tempo reale

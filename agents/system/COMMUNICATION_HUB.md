---
name: Communication Hub
description: Protocol for structured inter-agent communication
---

# COMMUNICATION HUB V6.2 - Sistema Comunicazione Multi-Agent

> **Versione:** 6.0
> **Data:** 25 Gennaio 2026
> **Scopo:** Protocollo comunicazione strutturata tra Orchestrator e Agent
> **Architettura:** Hub-and-Spoke (Orchestrator al centro)

---

## ARCHITETTURA COMUNICAZIONE

```
                              ┌─────────────────────┐
                              │                     │
                              │    ORCHESTRATOR     │
                              │    (HUB CENTRALE)   │
                              │                     │
                              └──────────┬──────────┘
                                         │
              ┌──────────────────────────┼──────────────────────────┐
              │                          │                          │
              │                          │                          │
    ┌─────────┴─────────┐      ┌─────────┴─────────┐      ┌─────────┴─────────┐
    │                   │      │                   │      │                   │
    │   CORE AGENTS     │      │  EXPERT AGENTS    │      │   SUB-AGENTS      │
    │                   │      │                   │      │                   │
    │  - analyzer       │      │  - gui-super      │      │  (spawned by      │
    │  - coder          │      │  - integration    │      │   main agents)    │
    │  - reviewer       │      │  - database       │      │                   │
    │  - documenter     │      │  - security       │      │                   │
    │                   │      │  - trading        │      │                   │
    │                   │      │  - mql            │      │                   │
    │                   │      │  - ... (altri)    │      │                   │
    └───────────────────┘      └───────────────────┘      └───────────────────┘

              │                          │                          │
              └──────────────────────────┼──────────────────────────┘
                                         │
                              ┌──────────┴──────────┐
                              │                     │
                              │   COMMUNICATION     │
                              │      PROTOCOL       │
                              │                     │
                              └─────────────────────┘
```

---

## REGOLA FONDAMENTALE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   ⛔ COMUNICAZIONE DIRETTA TRA AGENT = VIETATA                             │
│                                                                             │
│   ✅ Agent A → Orchestrator → Agent B                                      │
│   ❌ Agent A → Agent B (MAI)                                               │
│                                                                             │
│   L'Orchestrator è l'UNICO punto di smistamento messaggi.                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## TIPI DI MESSAGGIO

### 1. TASK_REQUEST (Orchestrator → Agent)

```json
{
  "message_type": "TASK_REQUEST",
  "task_id": "uuid-v4",
  "timestamp": "2026-01-25T14:30:00Z",
  "from": "orchestrator",
  "to": "gui-super-expert",
  "priority": "HIGH|MEDIUM|LOW",
  "model": "haiku|sonnet|opus",
  "payload": {
    "action": "implement|analyze|review|fix",
    "description": "Descrizione task",
    "context": {
      "files": ["path/to/file1.py", "path/to/file2.py"],
      "requirements": ["req1", "req2"],
      "constraints": ["constraint1"]
    },
    "dependencies": ["task-id-1", "task-id-2"],
    "deadline": "2026-01-25T15:00:00Z"
  }
}
```

### 2. TASK_RESPONSE (Agent → Orchestrator)

```json
{
  "message_type": "TASK_RESPONSE",
  "task_id": "uuid-v4",
  "timestamp": "2026-01-25T14:35:00Z",
  "from": "gui-super-expert",
  "to": "orchestrator",
  "status": "SUCCESS|PARTIAL|FAILED|BLOCKED|NEEDS_INFO|ESCALATE",
  "model_used": "haiku",
  "execution_time_ms": 1500,
  "payload": {
    "summary": "Riassunto 1-3 righe",
    "details": {
      "work_done": "Descrizione lavoro svolto",
      "metrics": {
        "lines_added": 150,
        "lines_removed": 30,
        "files_modified": 3
      }
    },
    "files_modified": [
      {"path": "path/file.py", "action": "modified", "description": "Aggiunta funzione X"}
    ],
    "issues_found": [
      {"name": "Issue1", "severity": "HIGH", "description": "Descrizione"}
    ],
    "next_actions": ["Azione suggerita 1", "Azione suggerita 2"],
    "escalate_to": null
  }
}
```

### 3. STATUS_UPDATE (Agent → Orchestrator, durante esecuzione)

```json
{
  "message_type": "STATUS_UPDATE",
  "task_id": "uuid-v4",
  "timestamp": "2026-01-25T14:32:00Z",
  "from": "coder",
  "to": "orchestrator",
  "payload": {
    "progress_percent": 60,
    "current_step": "Implementazione funzione principale",
    "eta_seconds": 120,
    "warnings": ["Warning opzionale"]
  }
}
```

### 4. ESCALATION_REQUEST (Agent → Orchestrator)

```json
{
  "message_type": "ESCALATION_REQUEST",
  "task_id": "uuid-v4",
  "timestamp": "2026-01-25T14:33:00Z",
  "from": "coder",
  "to": "orchestrator",
  "payload": {
    "reason": "COMPLEXITY|BLOCKED|NEEDS_EXPERT|CONFLICT",
    "description": "Motivo escalation",
    "suggested_agent": "architect_expert",
    "suggested_model": "sonnet",
    "context_for_escalation": {
      "attempted": "Cosa ho tentato",
      "failed_because": "Perché non ha funzionato",
      "needs": "Cosa serve per risolvere"
    }
  }
}
```

### 5. DEPENDENCY_REQUEST (Agent → Orchestrator)

```json
{
  "message_type": "DEPENDENCY_REQUEST",
  "task_id": "uuid-v4",
  "timestamp": "2026-01-25T14:31:00Z",
  "from": "coder",
  "to": "orchestrator",
  "payload": {
    "needs": "OUTPUT da altro task",
    "depends_on_task_id": "task-id-analyzer",
    "blocking": true,
    "can_proceed_partial": false
  }
}
```

### 6. SUB_AGENT_SPAWN (Agent principale → Orchestrator → Sub-Agent)

```json
{
  "message_type": "SUB_AGENT_SPAWN",
  "parent_task_id": "uuid-v4-parent",
  "sub_task_id": "uuid-v4-sub",
  "timestamp": "2026-01-25T14:34:00Z",
  "from": "integration_expert",
  "to": "orchestrator",
  "payload": {
    "sub_agent_type": "coder",
    "sub_agent_model": "haiku",
    "reason": "Implementazione specifica parsing JSON",
    "sub_task": {
      "action": "implement",
      "description": "Implementa parser JSON per risposta API",
      "files": ["path/parser.py"]
    }
  }
}
```

---

## FLUSSO COMUNICAZIONE STANDARD

### Flusso Semplice (1 Agent)

```
┌──────────┐    TASK_REQUEST    ┌────────────┐
│          │ ────────────────▶  │            │
│ ORCHESTR │                    │   AGENT    │
│          │ ◀────────────────  │            │
└──────────┘   TASK_RESPONSE    └────────────┘
```

### Flusso Multi-Agent Parallelo

```
                              TASK_REQUEST
                    ┌────────────────────────────▶ Agent A
                    │         TASK_REQUEST
    ORCHESTRATOR ───┼────────────────────────────▶ Agent B
                    │         TASK_REQUEST
                    └────────────────────────────▶ Agent C


                    ◀──────────────────────────── TASK_RESPONSE (A)
    ORCHESTRATOR ───◀──────────────────────────── TASK_RESPONSE (B)
                    ◀──────────────────────────── TASK_RESPONSE (C)

                    │
                    ▼
              MERGE RESULTS
```

### Flusso Con Dipendenze

```
                    TASK_REQUEST
    ORCHESTRATOR ───────────────────▶ Analyzer

                    ◀─────────────── TASK_RESPONSE (analisi)
    ORCHESTRATOR ───
                    │
                    │  (usa output analisi)
                    │
                    │   TASK_REQUEST (con context da analyzer)
                    └───────────────────▶ Coder

                    ◀─────────────────── TASK_RESPONSE (codice)
```

### Flusso Con Escalation

```
                    TASK_REQUEST (haiku)
    ORCHESTRATOR ───────────────────────▶ Coder

                    ◀─────────────────── ESCALATION_REQUEST
                    │                    (troppo complesso per haiku)
                    │
                    │   TASK_REQUEST (sonnet)
                    └───────────────────────▶ Coder (retry)

                    ◀─────────────────────── TASK_RESPONSE
```

### Flusso Multi-Session (Sub-Agents)

```
                    TASK_REQUEST
    ORCHESTRATOR ───────────────────────▶ Integration Expert
                                                │
                                                │ SUB_AGENT_SPAWN
                                                ▼
                                         ┌──────────────┐
                                         │ Sub-Agent 1  │
                                         │ (haiku)      │
                                         └──────┬───────┘
                                                │
                                         ┌──────────────┐
                                         │ Sub-Agent 2  │
                                         │ (haiku)      │
                                         └──────┬───────┘
                                                │
                                                ▼
                                         Integration Expert
                                         (merge sub-results)

                    ◀─────────────────────── TASK_RESPONSE
                                             (includes sub-agent stats)
```

---

## PRIORITY LEVELS

| Priority | Response Time | Use Case |
|----------|---------------|----------|
| **CRITICAL** | Immediato | Bug produzione, security issue |
| **HIGH** | < 5 minuti | Feature urgente, blocco utente |
| **MEDIUM** | < 15 minuti | Task standard |
| **LOW** | < 1 ora | Ottimizzazioni, doc, refactoring |

---

## STATO TASK (Lifecycle)

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ CREATED  │ ──▶ │  QUEUED  │ ──▶ │ RUNNING  │ ──▶ │ COMPLETED│
└──────────┘     └──────────┘     └────┬─────┘     └──────────┘
                                       │
                      ┌────────────────┼────────────────┐
                      │                │                │
                      ▼                ▼                ▼
               ┌──────────┐     ┌──────────┐     ┌──────────┐
               │  FAILED  │     │ BLOCKED  │     │ ESCALATED│
               └──────────┘     └──────────┘     └──────────┘
```

---

## CONTEXT SHARING

### Context Passato Tra Agent

Quando un agent completa e il risultato serve ad un altro:

```json
{
  "shared_context": {
    "from_task_id": "analyzer-task-123",
    "from_agent": "analyzer",
    "summary": "Modulo ha 5 file, 1200 righe totali",
    "key_findings": [
      "File principale: main.py (450 righe)",
      "Dipendenza: database.py",
      "Pattern: Singleton per config"
    ],
    "files_analyzed": ["main.py", "database.py", "config.py"],
    "suggested_approach": "Modificare solo main.py per feature X"
  }
}
```

### Context Persistence

Il context viene mantenuto per tutta la sessione:
- Orchestrator mantiene stato di TUTTI i task
- Ogni agent riceve il context rilevante dai task precedenti
- Context viene pulito solo a fine sessione

---

## ERROR HANDLING

### Timeout

```json
{
  "error_type": "TIMEOUT",
  "task_id": "uuid",
  "timeout_after_ms": 60000,
  "action": "RETRY|ESCALATE|ABORT",
  "retry_count": 0,
  "max_retries": 3
}
```

### Agent Failure

```json
{
  "error_type": "AGENT_FAILURE",
  "task_id": "uuid",
  "agent": "coder",
  "error_message": "Descrizione errore",
  "stack_trace": "...",
  "action": "RETRY_SAME|RETRY_DIFFERENT_MODEL|ESCALATE|ABORT"
}
```

### Conflict Resolution

Se due agent producono risultati conflittuali:

```json
{
  "error_type": "CONFLICT",
  "task_id": "uuid",
  "conflicting_agents": ["agent_a", "agent_b"],
  "conflict_description": "Descrizione conflitto",
  "resolution_strategy": "PREFER_FIRST|PREFER_SECOND|MERGE|ASK_USER|ESCALATE_ARCHITECT"
}
```

---

## METRICHE COMUNICAZIONE

| Metrica | Target | Alert Threshold |
|---------|--------|-----------------|
| **Message Latency** | < 100ms | > 500ms |
| **Task Completion Rate** | > 95% | < 90% |
| **Escalation Rate** | < 10% | > 20% |
| **Retry Rate** | < 5% | > 15% |
| **Timeout Rate** | < 2% | > 5% |

---

## LOGGING

Ogni messaggio viene loggato con:

```
[2026-01-25T14:30:00Z] [INFO] [COMM] TASK_REQUEST | orchestrator → gui-super-expert | task_id=abc123 | priority=HIGH
[2026-01-25T14:30:05Z] [INFO] [COMM] STATUS_UPDATE | gui-super-expert → orchestrator | task_id=abc123 | progress=30%
[2026-01-25T14:30:15Z] [INFO] [COMM] TASK_RESPONSE | gui-super-expert → orchestrator | task_id=abc123 | status=SUCCESS
```

---

## 💰 TOKEN OPTIMIZATION

### Principi Fondamentali

```
┌─────────────────────────────────────────────────────────────────┐
│  🎯 OBIETTIVO: MINIMO TOKEN → MASSIMO OUTPUT                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Ogni token ha un COSTO. Ottimizza sempre.                     │
│                                                                 │
│  haiku  ≈ $0.25/1M input, $1.25/1M output (economico)          │
│  sonnet ≈ $3/1M input, $15/1M output (10x più costoso)         │
│  opus   ≈ $15/1M input, $75/1M output (50x più costoso)        │
│                                                                 │
│  IMPLICAZIONE: Usa haiku il più possibile!                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Regole Ottimizzazione Context

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTEXT MINIMO NECESSARIO                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ✅ INCLUDERE:                                                  │
│     - File PATH (non contenuto completo se evitabile)          │
│     - Righe specifiche da modificare (line numbers)            │
│     - Requisiti essenziali (1-2 righe)                         │
│     - Output task precedente (solo summary)                    │
│                                                                 │
│  ❌ EVITARE:                                                    │
│     - File completo quando basta un path                       │
│     - Storico completo conversazione                           │
│     - Documentazione non necessaria                            │
│     - Ripetizioni informazioni già passate                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Context Size Guidelines

```
┌─────────────────────────────────────────────────────────────────┐
│  DIMENSIONE CONTEXT PER TIPO AGENT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  haiku (task semplice):                                        │
│  - Max 500 token context                                       │
│  - Solo file path + linee specifiche                           │
│  - Istruzioni 1-2 righe                                        │
│                                                                 │
│  haiku (task batch):                                           │
│  - Max 1000 token context                                      │
│  - Lista file/elementi                                         │
│  - Pattern da applicare                                        │
│                                                                 │
│  sonnet (task complesso):                                      │
│  - Max 2000 token context                                      │
│  - Snippet codice rilevanti                                    │
│  - Architettura overview                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Batching Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│  QUANDO USARE BATCHING vs AGENT MULTIPLI                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  USA BATCHING (1 agent, N elementi) quando:                    │
│  - Task identico su N elementi                                 │
│  - Elementi piccoli (< 100 righe ciascuno)                     │
│  - N <= 10 elementi                                            │
│  - Esempio: "Aggiungi docstring a 5 funzioni"                  │
│                                                                 │
│  USA AGENT MULTIPLI (N agent, 1 elemento) quando:              │
│  - Task diversi per ogni elemento                              │
│  - Elementi grandi (> 100 righe ciascuno)                      │
│  - N > 10 elementi                                             │
│  - Parallelismo necessario per velocità                        │
│  - Esempio: "Aggiorna 20 file con pattern diversi"             │
│                                                                 │
│  FORMULA DECISIONALE:                                          │
│  IF task_identico AND elementi_piccoli AND N <= 10:            │
│      usa_batching()                                            │
│  ELSE:                                                         │
│      usa_agent_multipli()                                      │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Prompt Template Ottimizzati

**Template HAIKU (task semplice):**
```
TASK: [azione] in [file_path]
DO: [istruzione 1 riga]
OUTPUT: Solo codice modificato
```

**Template HAIKU (batch):**
```
TASK: [azione] su [N] file
FILES: [lista path]
PATTERN: [cosa fare per ogni file]
OUTPUT: Codice per ogni file
```

**Template SONNET (task complesso):**
```
TASK: [azione complessa]
CONTEXT:
- [info essenziale 1]
- [info essenziale 2]
FILES: [lista path]
REQUIREMENTS:
- [req 1]
- [req 2]
OUTPUT: Codice + test + documentazione
```

### Metriche Token per Sessione

```
┌─────────────────────────────────────────────────────────────────┐
│  TARGET METRICHE TOKEN                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  % uso haiku:       > 90% dei task                             │
│  % uso sonnet:      < 10% dei task                             │
│  % uso opus:        0% (solo orchestrator)                     │
│                                                                 │
│  Avg token/task:    < 1000 (input + output)                    │
│  Context overhead:  < 30% del totale                           │
│  Retry token waste: < 5% del totale                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## BEST PRACTICES

### DO ✅

- Sempre includere `task_id` in ogni messaggio
- Sempre specificare `timestamp` ISO 8601
- Includere `context` rilevante per il task
- Usare `STATUS_UPDATE` per task lunghi (> 30s)
- Includere `next_actions` suggerite nel response
- **Preferire haiku per default (90% task)**
- **Usare file path invece di contenuto completo**
- **Batching per task ripetitivi piccoli**

### DON'T ❌

- Mai comunicare direttamente tra agent
- Mai omettere il `status` nel response
- Mai ignorare le `dependencies`
- Mai usare `ESCALATE` senza motivazione
- Mai dimenticare `files_modified`
- **Mai usare sonnet quando haiku basta**
- **Mai passare context non necessario**
- **Mai ripetere informazioni già condivise**

---

## CHANGELOG

### V1.0 - 25 Gennaio 2026
- Creazione protocollo comunicazione
- 6 tipi messaggio definiti
- Flussi standard documentati
- Error handling strutturato
- Metriche e logging

---

**USO:** Questo file definisce COME comunicano gli agent.
Ogni messaggio DEVE seguire questi formati.

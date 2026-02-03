---
name: Task Tracker
description: Tracking system for task status and progress
---

# TASK TRACKER - Template Tracking Sessione

> **Versione:** 6.0
> **Scopo:** Template che l'Orchestrator compila per tracciare task durante la sessione
> **Uso:** Copiare e aggiornare durante ogni sessione di lavoro

---

## SESSIONE CORRENTE

**Session ID:** `[auto-generato]`
**Inizio:** `[timestamp]`
**Utente:** `[richiesta originale]`
**Status:** `ACTIVE | COMPLETED | FAILED`

---

## TASK BOARD

### IN CODA (Queue)

| ID | Task | Agent | Priority | Depends On |
|----|------|-------|----------|------------|
| - | - | - | - | - |

### IN ESECUZIONE (Running)

| ID | Task | Agent | Model | Started | Progress |
|----|------|-------|-------|---------|----------|
| - | - | - | - | - | - |

### COMPLETATI (Done)

| ID | Task | Agent | Model | Duration | Status |
|----|------|-------|-------|----------|--------|
| - | - | - | - | - | - |

### FALLITI/BLOCCATI (Failed/Blocked)

| ID | Task | Agent | Reason | Action |
|----|------|-------|--------|--------|
| - | - | - | - | - |

---

## ESEMPIO COMPILATO

```markdown
## SESSIONE CORRENTE

**Session ID:** `sess-2026-01-25-001`
**Inizio:** `2026-01-25T14:30:00Z`
**Utente:** "Aggiungi tab Shell a Telegram e cTrader"
**Status:** `ACTIVE`

---

## TASK BOARD

### IN CODA (Queue)

| ID | Task | Agent | Priority | Depends On |
|----|------|-------|----------|------------|
| T4 | Aggiornare CLAUDE.md | documenter | LOW | T1,T2,T3 |

### IN ESECUZIONE (Running)

| ID | Task | Agent | Model | Started | Progress |
|----|------|-------|-------|---------|----------|
| T2 | Registrare in main_window | coder | haiku | 14:32:00 | 60% |
| T3 | Aggiungere traduzioni | coder | haiku | 14:32:00 | 40% |

### COMPLETATI (Done)

| ID | Task | Agent | Model | Duration | Status |
|----|------|-------|-------|----------|--------|
| T1 | Creare tab_shell.py | gui-super-expert | haiku | 45s | SUCCESS |

### FALLITI/BLOCCATI (Failed/Blocked)

| ID | Task | Agent | Reason | Action |
|----|------|-------|--------|--------|
| - | - | - | - | - |
```

---

## STATISTICHE SESSIONE

### Contatori

```
┌─────────────────────────────────────────────────────────────────┐
│  TASK STATS                                                     │
├─────────────────────────────────────────────────────────────────┤
│  Total Tasks:     [ 0 ]                                         │
│  Completed:       [ 0 ] ✅                                      │
│  Running:         [ 0 ] ⏳                                      │
│  Queued:          [ 0 ] 📋                                      │
│  Failed:          [ 0 ] ❌                                      │
│  Blocked:         [ 0 ] 🚫                                      │
│  Escalated:       [ 0 ] ⬆️                                      │
├─────────────────────────────────────────────────────────────────┤
│  AGENT USAGE                                                    │
├─────────────────────────────────────────────────────────────────┤
│  haiku:           [ 0 ] tasks                                   │
│  sonnet:          [ 0 ] tasks                                   │
│  opus:            [ 0 ] tasks (orchestrator only)               │
├─────────────────────────────────────────────────────────────────┤
│  TIMING                                                         │
├─────────────────────────────────────────────────────────────────┤
│  Session Duration: [ 0 ] min                                    │
│  Avg Task Time:    [ 0 ] sec                                    │
│  Parallelism:      [ 0 ] max concurrent                         │
└─────────────────────────────────────────────────────────────────┘
```

### Agent Breakdown

| Agent | Tasks | Success | Failed | Avg Time |
|-------|-------|---------|--------|----------|
| analyzer | 0 | 0 | 0 | 0s |
| coder | 0 | 0 | 0 | 0s |
| gui-super-expert | 0 | 0 | 0 | 0s |
| integration_expert | 0 | 0 | 0 | 0s |
| ... | ... | ... | ... | ... |

---

## DEPENDENCY GRAPH

```
Visualizza dipendenze tra task:

T1 (tab_shell.py)
 │
 ├──▶ T2 (main_window)
 │
 └──▶ T3 (traduzioni)
       │
       └──▶ T4 (cTrader sub-tab)
             │
             └──▶ T5 (documenter)
```

---

## OUTPUT RIEPILOGO (Fine Sessione)

```
╔══════════════════════════════════════════════════════════════════╗
║                     SESSIONE COMPLETATA                          ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Session ID: sess-2026-01-25-001                                ║
║  Durata: 5 min 23 sec                                           ║
║                                                                  ║
║  TASK SUMMARY:                                                   ║
║  ├── Total: 5                                                    ║
║  ├── Completed: 5 ✅                                             ║
║  ├── Failed: 0 ❌                                                ║
║  └── Success Rate: 100%                                          ║
║                                                                  ║
║  AGENT USAGE:                                                    ║
║  ├── haiku: 4 tasks (80%)                                       ║
║  ├── sonnet: 1 task (20%)                                       ║
║  └── opus: 0 tasks                                               ║
║                                                                  ║
║  FILES MODIFIED:                                                 ║
║  ├── TELEGRAM/gui/tabs/tab_shell.py (created)                   ║
║  ├── TELEGRAM/gui/main_window_tray.py (modified)                ║
║  ├── TELEGRAM/gui/utils/translations/general.py (modified)      ║
║  └── TELEGRAM/gui/tabs/ctrader/tab_ctrader.py (modified)        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## INTEGRAZIONE CON ORCHESTRATOR

### Come Orchestrator Usa Questo Template

1. **Inizio Sessione:** Crea nuova istanza del tracker
2. **Per Ogni Task:**
   - Aggiunge alla coda
   - Sposta a "Running" quando lancia agent
   - Aggiorna progress se riceve STATUS_UPDATE
   - Sposta a "Done" o "Failed" al completamento
3. **Fine Sessione:** Genera output riepilogo

### Regole Tracking

| Regola | Descrizione |
|--------|-------------|
| **Sempre aggiornare** | Ogni cambio stato = update tracker |
| **ID univoci** | T1, T2, T3... per sessione |
| **Timestamp ISO** | Sempre formato ISO 8601 |
| **Progress %** | Stima 0-100 per task lunghi |
| **Dipendenze esplicite** | Sempre specificare se task dipende da altri |

---

## COMUNICAZIONE ALL'UTENTE

L'Orchestrator DEVE comunicare il tracker all'utente:

### Prima di Lanciare

```
🤖 MODALITÀ ORCHESTRATOR ATTIVATA

| # | Task | Agent | Model |
|---|------|-------|-------|
| T1 | Creare tab_shell.py | gui-super-expert | haiku |
| T2 | Registrare in main_window | coder | haiku |
| T3 | Aggiungere traduzioni | coder | haiku |
| T4 | Sub-tab Shell cTrader | coder | haiku |

Totale: 4 task, 3 in parallelo (T1→T2,T3,T4)
```

### Durante Esecuzione (se > 30s)

```
⏳ PROGRESS UPDATE

| Task | Status | Progress |
|------|--------|----------|
| T1 | ✅ Done | 100% |
| T2 | ⏳ Running | 60% |
| T3 | ⏳ Running | 40% |
| T4 | 📋 Queued | 0% |
```

### Dopo Completamento

```
✅ TASK COMPLETATO

Agent utilizzati: 4 totali
- haiku: 4 agent
- sonnet: 0 agent
- opus: 0 agent

File modificati: 4
Tempo totale: ~45s
```

---

## CHANGELOG

### V1.0 - 25 Gennaio 2026
- Template creato
- Task board con 4 stati
- Statistiche sessione
- Dependency graph
- Output riepilogo
- Integrazione orchestrator

---

**USO:** L'Orchestrator copia questo template all'inizio di ogni sessione
e lo aggiorna in tempo reale durante l'esecuzione dei task.

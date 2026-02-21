---
name: System Architecture
description: Complete architecture documentation for multi-agent system
---

# 🏗️ SYSTEM ARCHITECTURE V6.2 - Architettura Multi-Agent Completa

> **Versione:** 6.2
> **Data:** 25 Gennaio 2026
> **Scopo:** Definire come TUTTI gli agent collaborano in ogni sessione di sviluppo
> **Principio:** Ogni agent ha un ruolo specifico e DEVE essere attivato quando necessario

---

## 🎯 VISIONE D'INSIEME

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    SISTEMA MULTI-AGENT ORCHESTRATO                           ║
║                                                                              ║
║  ┌─────────────────────────────────────────────────────────────────────┐    ║
║  │                         ORCHESTRATOR                                 │    ║
║  │                    (Cervello del Sistema)                           │    ║
║  │                                                                      │    ║
║  │  Legge: AGENT_REGISTRY → Chi chiamare                               │    ║
║  │  Usa: COMMUNICATION_HUB → Come comunicare                           │    ║
║  │  Delega: SYSTEM_COORDINATOR → Manutenzione                          │    ║
║  │  Traccia: TASK_TRACKER → Stato lavori                               │    ║
║  └─────────────────────────────────────────────────────────────────────┘    ║
║                                    │                                         ║
║              ┌─────────────────────┼─────────────────────┐                  ║
║              │                     │                     │                  ║
║              ▼                     ▼                     ▼                  ║
║  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐         ║
║  │   CORE AGENTS     │ │  EXPERT AGENTS    │ │  SUPPORT AGENTS   │         ║
║  │                   │ │                   │ │                   │         ║
║  │ • analyzer        │ │ • gui-super       │ │ • system_coord    │         ║
║  │ • coder           │ │ • integration     │ │ • documenter      │         ║
║  │ • reviewer        │ │ • database        │ │                   │         ║
║  │                   │ │ • security        │ │                   │         ║
║  │                   │ │ • trading         │ │                   │         ║
║  │                   │ │ • mql             │ │                   │         ║
║  │                   │ │ • architect       │ │                   │         ║
║  │                   │ │ • ... (15 total)  │ │                   │         ║
║  └───────────────────┘ └───────────────────┘ └───────────────────┘         ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## 📊 RUOLI E RESPONSABILITÀ

### LIVELLO 0: ORCHESTRATOR (Hub Centrale)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR V6.2                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  RUOLO: Coordinatore centrale - NON codifica MAI                           │
│  MODEL: opus (default)                                                      │
│                                                                             │
│  RESPONSABILITÀ:                                                            │
│  ✅ Ricevere richieste utente                                              │
│  ✅ Analizzare complessità e domini coinvolti                              │
│  ✅ Consultare AGENT_REGISTRY per routing                                  │
│  ✅ Pianificare task (sequenziali/paralleli)                               │
│  ✅ Comunicare piano all'utente                                            │
│  ✅ Lanciare agent appropriati                                             │
│  ✅ Raccogliere risultati                                                  │
│  ✅ Gestire escalation/errori                                              │
│  ✅ Generare report finale                                                 │
│                                                                             │
│  NON FA MAI:                                                                │
│  ❌ Scrivere codice direttamente                                           │
│  ❌ Modificare file direttamente                                           │
│  ❌ Analizzare codice (delega ad analyzer)                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### LIVELLO 1: CORE AGENTS (Sempre Disponibili)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ANALYZER                                                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  QUANDO: Prima di OGNI implementazione                                      │
│  MODEL: haiku                                                               │
│  TASK: Analizza struttura, identifica problemi, mappa dipendenze           │
│  OUTPUT: Report JSON con findings                                          │
│  ATTIVAZIONE: Automatica se task richiede modifiche a codice esistente     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  CODER                                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  QUANDO: Implementazione codice                                             │
│  MODEL: haiku (semplice) / sonnet (complesso)                              │
│  TASK: Scrive codice, test, seguendo best practices                        │
│  OUTPUT: Codice funzionante + test                                         │
│  ATTIVAZIONE: Dopo analisi, quando serve implementare                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  REVIEWER                                                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  QUANDO: Dopo OGNI implementazione significativa                           │
│  MODEL: haiku                                                               │
│  TASK: Valida codice, verifica qualità, identifica problemi               │
│  OUTPUT: Review con approvazione o richieste modifica                      │
│  ATTIVAZIONE: Automatica dopo coder completa                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### LIVELLO 2: EXPERT AGENTS (Specializzati)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  15 EXPERT DISPONIBILI - OGNUNO CON DOMINIO SPECIFICO                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  GUI-SUPER-EXPERT      │ PyQt5, UI/UX, Design Systems, Accessibility       │
│  INTEGRATION_EXPERT    │ Telegram, cTrader, MT5, Webhooks, API             │
│  DATABASE_EXPERT       │ SQL, SQLite, Schema, Query optimization           │
│  SECURITY_UNIFIED      │ Auth, Encryption, OWASP, Threat modeling          │
│  TRADING_STRATEGY      │ Risk management, Position sizing, Prop firm       │
│  MQL_EXPERT           │ MQL4/5, Expert Advisor, OnTimer, OrderSend        │
│  TESTER_EXPERT        │ Test architecture, QA, Debugging, Coverage        │
│  MOBILE_EXPERT        │ iOS, Android, Flutter, React Native               │
│  LANGUAGES_EXPERT     │ Python, JS, TypeScript, C#, Rust, Go              │
│  ARCHITECT_EXPERT     │ System design, Patterns, Scaling, ADR             │
│  DEVOPS_EXPERT        │ CI/CD, Docker, Kubernetes, Terraform              │
│  N8N_EXPERT           │ Workflow automation, Low-code                      │
│  AI_INTEGRATION       │ LLM, RAG, Embedding, Prompt engineering           │
│  SOCIAL_IDENTITY      │ OAuth2/OIDC, Google/Apple/Facebook login          │
│  CLAUDE_SYSTEMS       │ Claude API, Cost optimization, Caching            │
│                                                                             │
│  ATTIVAZIONE: Basata su keyword matching (vedi AGENT_REGISTRY)             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### LIVELLO 3: SUPPORT AGENTS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SYSTEM_COORDINATOR                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  QUANDO: Inizio/Fine sessione, manutenzione sistema                        │
│  MODEL: haiku                                                               │
│  TASK: Mantiene REGISTRY, TRACKER, INDEX aggiornati                        │
│  OUTPUT: Conferme, report sessione                                         │
│  ATTIVAZIONE: Automatica a inizio/fine sessione                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  DOCUMENTER                                                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  QUANDO: Fine feature, aggiornamento documentazione                        │
│  MODEL: haiku                                                               │
│  TASK: README, CHANGELOG, TODOLIST, commenti codice                        │
│  OUTPUT: Documentazione aggiornata                                         │
│  ATTIVAZIONE: A fine sessione o su richiesta                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 FLUSSO COMPLETO SESSIONE DI SVILUPPO

### FASE 0: INIZIALIZZAZIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  TRIGGER: Utente fa richiesta                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ORCHESTRATOR:                                                              │
│  1. Attiva SYSTEM_COORDINATOR per inizializzare TASK_TRACKER               │
│  2. Legge AGENT_REGISTRY per identificare agent necessari                  │
│  3. Analizza richiesta per identificare domini coinvolti                   │
│                                                                             │
│  SYSTEM_COORDINATOR:                                                        │
│  • Crea nuova sessione nel TASK_TRACKER                                    │
│  • Timestamp inizio                                                         │
│  • Reset contatori                                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### FASE 1: ANALISI E PIANIFICAZIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR:                                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. IDENTIFICA DOMINI                                                       │
│     □ È task GUI? → gui-super-expert                                       │
│     □ È task API? → integration_expert                                     │
│     □ È task DB? → database_expert                                         │
│     □ È task Security? → security_unified_expert                           │
│     □ È task Trading? → trading_strategy_expert / mql_expert               │
│     □ È task Architettura? → architect_expert                              │
│     □ ...                                                                   │
│                                                                             │
│  2. LANCIA ANALYZER (se serve analisi codice esistente)                    │
│     ANALYZER analizza e ritorna report con:                                │
│     • Struttura corrente                                                    │
│     • Dipendenze                                                            │
│     • Problemi trovati                                                      │
│     • Suggerimenti                                                          │
│                                                                             │
│  3. PIANIFICA TASK                                                          │
│     • Crea lista task con ID (T1, T2, T3...)                               │
│     • Assegna agent a ogni task                                            │
│     • Definisce dipendenze                                                  │
│     • Seleziona model (haiku/sonnet)                                       │
│                                                                             │
│  4. COMUNICA PIANO ALL'UTENTE                                              │
│     🤖 MODALITÀ ORCHESTRATOR ATTIVATA                                      │
│     | # | Task | Agent | Model | Dipende Da |                              │
│     |---|------|-------|-------|------------|                              │
│     ...                                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### FASE 2: ESECUZIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR LANCIA AGENT IN PARALLELO (se possibile)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Per ogni task:                                                             │
│                                                                             │
│  1. Invia TASK_REQUEST all'agent appropriato                               │
│     (formato da COMMUNICATION_HUB)                                         │
│                                                                             │
│  2. SYSTEM_COORDINATOR aggiorna TASK_TRACKER                               │
│     • Task aggiunto a "Running"                                            │
│                                                                             │
│  3. Agent esegue task                                                       │
│     • Se expert → usa competenze specifiche                                │
│     • Se coder → implementa codice                                         │
│     • Se complesso → può lanciare SUB-AGENT (multi-session)               │
│                                                                             │
│  4. Agent ritorna TASK_RESPONSE                                            │
│     (formato da PROTOCOL.md)                                               │
│                                                                             │
│  5. SYSTEM_COORDINATOR aggiorna TASK_TRACKER                               │
│     • Task spostato a "Completed" o "Failed"                               │
│                                                                             │
│  6. Se ESCALATION necessaria:                                              │
│     • Orchestrator rilancia con model superiore                            │
│     • O chiede all'utente                                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### FASE 3: REVIEW E VALIDAZIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DOPO IMPLEMENTAZIONE SIGNIFICATIVA                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ORCHESTRATOR lancia REVIEWER:                                             │
│                                                                             │
│  REVIEWER verifica:                                                         │
│  • Qualità codice (best practices)                                         │
│  • Sicurezza (OWASP)                                                       │
│  • Performance (algoritmi, risorse)                                        │
│  • Test coverage                                                            │
│  • Documentazione (commenti, docstring)                                    │
│                                                                             │
│  Se SECURITY coinvolta:                                                     │
│  → SECURITY_UNIFIED_EXPERT fa review aggiuntiva                            │
│                                                                             │
│  Output:                                                                    │
│  • APPROVED → Procedi                                                       │
│  • NEEDS_CHANGES → Torna a coder con feedback                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### FASE 4: DOCUMENTAZIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FINE FEATURE/SESSIONE                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ORCHESTRATOR lancia DOCUMENTER:                                           │
│                                                                             │
│  DOCUMENTER aggiorna:                                                       │
│  • CHANGELOG (se nuova feature)                                            │
│  • README (se cambia struttura)                                            │
│  • TODOLIST (se task completati)                                           │
│  • Commenti codice (se necessario)                                         │
│                                                                             │
│  SYSTEM_COORDINATOR:                                                        │
│  • Aggiorna INDEX se nuovi file                                            │
│  • Aggiorna AGENT_REGISTRY se nuovi expert                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### FASE 5: CHIUSURA SESSIONE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  FINE LAVORO                                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  SYSTEM_COORDINATOR:                                                        │
│  1. Chiude TASK_TRACKER                                                    │
│  2. Genera statistiche sessione                                            │
│  3. Prepara report finale                                                  │
│                                                                             │
│  ORCHESTRATOR:                                                              │
│  1. Comunica report finale all'utente                                      │
│                                                                             │
│  ✅ TASK COMPLETATO                                                        │
│                                                                             │
│  Agent utilizzati: N totali                                                │
│  - haiku: X | sonnet: Y | opus: 0                                         │
│                                                                             │
│  Expert coinvolti:                                                          │
│  - gui-super-expert: 2 task                                                │
│  - integration_expert: 1 task                                              │
│  - ...                                                                      │
│                                                                             │
│  File modificati:                                                           │
│  - path/file1.py (created)                                                 │
│  - path/file2.py (modified)                                                │
│                                                                             │
│  Tempo totale: ~Xs                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 MATRICE ATTIVAZIONE AGENT

### Quando Attivare Ogni Agent

| Condizione | Agent da Attivare | Priorità |
|------------|-------------------|----------|
| Task richiede modifica codice esistente | **analyzer** | SEMPRE prima |
| Task GUI/UI/UX | **gui-super-expert** | SEMPRE |
| Task API/Integration | **integration_expert** | SEMPRE |
| Task Database | **database_expert** | SEMPRE |
| Task Security/Auth | **security_unified_expert** | SEMPRE |
| Task Trading/Risk | **trading_strategy_expert** | SEMPRE |
| Task MQL/EA | **mql_expert** | SEMPRE |
| Task Test/Debug | **tester_expert** | Su richiesta |
| Task Architettura | **architect_expert** | Per decisioni design |
| Implementazione codice | **coder** | Dopo analisi |
| Post-implementazione | **reviewer** | SEMPRE dopo coder |
| Fine feature | **documenter** | SEMPRE |
| Inizio/Fine sessione | **system_coordinator** | AUTOMATICO |

### Combinazioni Comuni

```
FEATURE GUI:
analyzer → gui-super-expert → coder → reviewer → documenter

FEATURE API:
analyzer → integration_expert → coder → security_unified → reviewer → documenter

FEATURE DATABASE:
analyzer → database_expert → coder → reviewer → documenter

FEATURE TRADING:
analyzer → trading_strategy → mql_expert (se EA) → coder → reviewer → documenter

BUG FIX:
tester_expert → analyzer → coder → reviewer

REFACTORING:
architect_expert → analyzer → coder → reviewer → documenter
```

---

## 🔀 MULTI-SESSION (Agent che Lanciano Sub-Agent)

### Quando Usare

- Task complesso che richiede più specializzazioni
- Expert che ha bisogno di coder per implementare
- Parallelismo interno necessario

### Esempio

```
ORCHESTRATOR
    │
    └─▶ integration_expert (sonnet)
             │
             ├─▶ coder (haiku) [parsing API]
             ├─▶ coder (haiku) [error handling]
             └─▶ database_expert (haiku) [persistenza]
             │
             └─▶ MERGE results
             │
         TASK_RESPONSE
```

---

## 📊 FILE DI SISTEMA

| File | Scopo | Gestito Da |
|------|-------|------------|
| `AGENT_REGISTRY.md` | Routing task → agent | system_coordinator |
| `COMMUNICATION_HUB.md` | Protocollo messaggi | (statico) |
| `TASK_TRACKER.md` | Tracking sessione | system_coordinator |
| `PROTOCOL.md` | Formato output | (statico) |
| `INDEX.md` | Navigazione sistema | system_coordinator |
| `SYSTEM_ARCHITECTURE.md` | Questo file | (statico) |

---

## ⚙️ REGOLE FERREE

### 1. Orchestrator NON Codifica
L'orchestrator coordina, non implementa. Sempre delegare a coder/expert.

### 2. Analyzer PRIMA di Modificare
Se il task richiede modifica a codice esistente, lanciare analyzer prima.

### 3. Reviewer DOPO Implementazione
Ogni implementazione significativa va validata da reviewer.

### 4. Expert per Dominio Specifico
Se il task tocca un dominio specifico (GUI, DB, Security, Trading), l'expert va coinvolto.

### 5. Documenter a Fine Feature
Ogni feature completata va documentata.

### 6. System Coordinator per Manutenzione
I file di sistema (REGISTRY, TRACKER, INDEX) sono gestiti dal system_coordinator.

### 7. Comunicazione Sempre via Orchestrator
Nessun agent comunica direttamente con altri agent.

### 8. Haiku Default, Sonnet Eccezione
90% task usa haiku. Sonnet solo per complessità elevata.

---

## 📈 METRICHE SISTEMA

### Target Performance

| Metrica | Target |
|---------|--------|
| Task Success Rate | > 95% |
| Escalation Rate | < 10% |
| Haiku Usage | > 80% |
| Review Pass Rate | > 90% |
| Session Completion | 100% |

### Monitoraggio

- Ogni sessione genera statistiche via TASK_TRACKER
- Trend analizzati per ottimizzare routing
- Escalation patterns identificati per migliorare agent

---

## CHANGELOG

### V1.0 - 25 Gennaio 2026
- Architettura completa definita
- 6 core agents + 15 expert mappati
- Flusso 5 fasi documentato
- Matrice attivazione creata
- Multi-session documentato
- Regole ferree stabilite

---

**PRINCIPIO GUIDA:** Ogni agent ha un ruolo specifico.
L'orchestrator coordina, gli expert specializzano, i core agent eseguono.
Nessuno lavora in isolamento - tutti collaborano verso l'obiettivo.

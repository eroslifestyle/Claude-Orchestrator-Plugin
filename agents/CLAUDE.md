---
name: Sistema Agent MasterCopy
description: Multi-agent system index with orchestrator, core agents, and 15 expert specialists for parallel task execution
---

# 🤖 SISTEMA AGENT MASTERCOPY V6.0

> **Versione:** 6.0
> **Data:** 29 Gennaio 2026
> **Architettura:** Multi-Agent Parallelo con Orchestrator + Expert Files + Ralph Loop

---

## 🚨 REGOLE CRITICHE OBBLIGATORIE

### REGOLA #1: GESTIONE PROCESSI ESTERNI
**OBBLIGATORIO - SEMPRE - SENZA ECCEZIONI**

```
OGNI processo esterno (Python, CMD, PowerShell, Node) DEVE essere:
1. Eseguito solo quando necessario
2. TERMINATO IMMEDIATAMENTE dopo il completamento del task
3. MAI lasciato in background senza motivo
```

**Violazione = Eccessivo consumo CPU/RAM = INACCETTABILE**

**Azioni richieste:**
- Dopo test Python → `taskkill /F /IM python.exe`
- Dopo comandi lunghi → Verificare che il processo sia terminato
- Fine sessione → Pulizia totale processi orfani

**CLEANUP TOTALE - ESEGUIRE ALLA FINE DI OGNI TASK:**
```bash
# BATCH 1: Processi principali
taskkill /F /IM python.exe 2>NUL
taskkill /F /IM node.exe 2>NUL
taskkill /F /IM bash.exe 2>NUL
taskkill /F /IM pwsh.exe 2>NUL

# BATCH 2: Utility
taskkill /F /IM grep.exe 2>NUL
taskkill /F /IM tail.exe 2>NUL
taskkill /F /IM rg.exe 2>NUL
taskkill /F /IM git.exe 2>NUL

# BATCH 3: Shell orfane
taskkill /F /IM cmd.exe /FI "WINDOWTITLE ne Administrator*" 2>NUL
taskkill /F /IM powershell.exe /FI "WINDOWTITLE ne Administrator*" 2>NUL

# BATCH 4: File nul
rm -f ~/.claude/nul ~/.claude/agents/nul ~/nul 2>NUL
```

---

### REGOLA #2: NO FILE "nul"
**OBBLIGATORIO - SEMPRE - SENZA ECCEZIONI**

```
Su Windows:
- MAI usare 2>/dev/null (crea file "nul" invece di scartare output)
- SEMPRE usare 2>NUL (corretto per Windows)
- SEMPRE eliminare file "nul" se trovati
```

**Cleanup file nul (eseguire periodicamente):**
```bash
rm -f ~/.claude/nul ~/.claude/agents/nul ~/nul 2>NUL
```

**Violazione = File bloccanti nel sistema = INACCETTABILE**

---

## 🎯 PRINCIPIO FONDAMENTALE

```
OGNI RICHIESTA → ORCHESTRATOR → DELEGA → AGENT SPECIALIZZATI
```

**L'Orchestrator è SEMPRE il punto di ingresso.**

---

## 📊 ARCHITETTURA

```
┌─────────────────────────────────────────────────────────────────┐
│                         ORCHESTRATOR                            │
│                    (Punto di ingresso UNICO)                    │
│                      MAI codifica - DELEGA                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│   ANALYZER    │   │    CODER      │   │   REVIEWER    │
│  (Analisi)    │   │(Implementa)   │   │  (Valida)     │
│  N istanze    │   │  N istanze    │   │  N istanze    │
└───────────────┘   └───────┬───────┘   └───────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │           EXPERTS (15)                │
        │       (Chiamati al bisogno)           │
        ├───────────────────────────────────────┤
        │ • GUI Expert (PyQt5)                  │
        │ • Database Expert (SQL/SQLite)        │
        │ • Security Expert (OWASP)             │
        │ • MQL Expert (MetaTrader)             │
        │ • Trading Strategy Expert             │
        │ • Architect Expert                    │
        │ • Integration Expert (API)            │
        │ • DevOps Expert (CI/CD)               │
        │ • Languages Expert (Python/JS/C#)     │
        │ • Tester Expert (QA/Debug)            │
        │ • AI Integration Expert (LLM)         │
        │ • Claude Systems Expert               │
        │ • Mobile Expert (iOS/Android)         │
        │ • N8N Expert (Workflow)               │
        │ • Social Identity Expert (OAuth)      │
        └───────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────────┐
        │      DOCUMENTER + SYSTEM COORDINATOR  │
        │   (Documentazione + Resource Mgmt)    │
        └───────────────────────────────────────┘
```

---

## 👥 AGENT DISPONIBILI (20 Totali)

### Core Agents (5)
| Agent | File | Ruolo | Model | Istanze |
|-------|------|-------|-------|---------|
| Orchestrator | `core/orchestrator.md` | Coordinamento | - | 1 |
| Analyzer | `core/analyzer.md` | Analisi rapida | haiku | N parallele |
| Coder | `core/coder.md` | Implementazione | sonnet | N parallele |
| Reviewer | `core/reviewer.md` | Validazione | sonnet | N parallele |
| Documenter | `core/documenter.md` | Documentazione | haiku | 1-2 |
| System Coordinator | `core/system_coordinator.md` | Resource/Token management | haiku | 1 |

### Expert Agents (15)
| Expert | File | Specializzazione | Model |
|--------|------|------------------|-------|
| GUI Super Expert | `experts/gui-super-expert.md` | PyQt5, Qt, Widget, Layout | sonnet |
| Tester Expert | `experts/tester_expert.md` | Testing, QA, Debug, Performance | sonnet |
| Database Expert | `experts/database_expert.md` | SQLite, PostgreSQL, Schema, Query | sonnet |
| Security Expert | `experts/security_unified_expert.md` | Security, Encryption, Auth, OWASP | sonnet |
| MQL Expert | `experts/mql_expert.md` | MQL5/MQL4, MetaTrader, EA | sonnet |
| Trading Strategy | `experts/trading_strategy_expert.md` | Trading, Risk Management, TP/SL | sonnet |
| Architect Expert | `experts/architect_expert.md` | Architecture, Design Patterns | opus |
| Integration Expert | `experts/integration_expert.md` | API, REST, Webhook, cTrader | sonnet |
| DevOps Expert | `experts/devops_expert.md` | DevOps, CI/CD, Deploy, Docker | haiku |
| Languages Expert | `experts/languages_expert.md` | Python, JavaScript, C# | sonnet |
| AI Integration | `experts/ai_integration_expert.md` | AI/LLM, Model Selection, Fine-tuning | sonnet |
| Claude Systems | `experts/claude_systems_expert.md` | Claude Ecosystem, Cost Optimization | sonnet |
| Mobile Expert | `experts/mobile_expert.md` | iOS, Android, Swift, Kotlin, Flutter | sonnet |
| N8N Expert | `experts/n8n_expert.md` | N8N, Workflow Automation | sonnet |
| Social Identity | `experts/social_identity_expert.md` | OAuth2, OIDC, Social Login | sonnet |

### System Components
| Componente | File | Descrizione |
|------------|------|-------------|
| Agent Registry | `system/AGENT_REGISTRY.md` | Registry centralizzato agenti |
| Communication Hub | `system/COMMUNICATION_HUB.md` | Hub comunicazione inter-agenti |
| Protocol | `system/PROTOCOL.md` | Protocolli di comunicazione |
| Task Tracker | `system/TASK_TRACKER.md` | Tracking task distribuito |

---

## 🚀 WORKFLOW

### Flusso Standard
```
T0: Richiesta utente
    └── Orchestrator riceve

T1: Analisi (PARALLELA)
    ├── Analyzer 1 → Modulo A
    ├── Analyzer 2 → Modulo B
    └── Analyzer N → Modulo N

T2: Pianificazione
    └── Orchestrator crea task list

T3: Implementazione (PARALLELA)
    ├── Coder 1 → Task indipendente A
    ├── Coder 2 → Task indipendente B
    └── Expert X → Task specialistico

T4: Review (PARALLELA)
    ├── Reviewer 1 → Review batch A
    └── Reviewer 2 → Review batch B

T5: Documentazione
    └── DocWriter → Aggiorna docs

T6: Risposta finale
```

### Regole Parallelismo
| Condizione | Azione |
|------------|--------|
| Task indipendenti | Lancia in PARALLELO |
| Task dipendenti | Lancia in SEQUENZA |
| Stesso modulo | 1 agent alla volta |
| Moduli diversi | N agent paralleli |

---

## 📁 STRUTTURA FILE

```
C:\Users\LeoDg\.claude\agents\
├── CLAUDE.md                 # Questo file (indice principale)
├── INDEX.md                  # Indice navigazione
│
├── core/                     # Agent fondamentali (5)
│   ├── orchestrator.md       # 🎯 Coordinatore centrale
│   ├── analyzer.md           # 🔍 Analisi codebase
│   ├── coder.md              # 👨‍💻 Implementazione
│   ├── reviewer.md           # ✅ Code review
│   ├── documenter.md         # 📝 Documentazione
│   └── system_coordinator.md # 💰 Resource/Token management
│
├── experts/                  # Agent specializzati (15)
│   ├── gui-super-expert.md       # 🎨 PyQt5/Qt/UI
│   ├── tester_expert.md          # 🧪 Testing/QA/Debug
│   ├── database_expert.md        # 🗄️ SQL/SQLite/PostgreSQL
│   ├── security_unified_expert.md # 🔒 Security/OWASP
│   ├── mql_expert.md             # 📊 MQL5/MetaTrader
│   ├── trading_strategy_expert.md # 📈 Trading/Risk
│   ├── architect_expert.md       # 🏗️ Architettura/Design
│   ├── integration_expert.md     # 🔌 API/REST/Webhook
│   ├── devops_expert.md          # 🚀 DevOps/CI/CD
│   ├── languages_expert.md       # 💻 Python/JS/C#
│   ├── ai_integration_expert.md  # 🤖 AI/LLM Integration
│   ├── claude_systems_expert.md  # 🎛️ Claude Ecosystem
│   ├── mobile_expert.md          # 📱 iOS/Android/Flutter
│   ├── n8n_expert.md             # 🔄 N8N/Workflow
│   └── social_identity_expert.md # 🔑 OAuth/OIDC/Social
│
├── workflows/                # Workflow predefiniti
│   ├── bugfix.md             # Workflow bug fixing
│   ├── feature.md            # Workflow nuove feature
│   ├── refactoring.md        # Workflow refactoring
│   └── OPTIMIZED.md          # Workflow ottimizzato
│
├── templates/                # Template output
│   ├── task.md               # Template task
│   ├── review.md             # Template review
│   └── integration.md        # Template integrazione
│
├── system/                   # Componenti sistema
│   ├── AGENT_REGISTRY.md     # Registry agenti
│   ├── COMMUNICATION_HUB.md  # Hub comunicazione
│   ├── PROTOCOL.md           # Protocolli
│   └── TASK_TRACKER.md       # Task tracking
│
├── docs/                     # Documentazione
│   ├── README.md             # Documentazione generale
│   ├── SYSTEM_ARCHITECTURE.md # Architettura
│   ├── INTEGRATION_REPORT.md # Report integrazione
│   ├── quickstart.md         # Guida rapida
│   ├── getting-started.md    # Getting started
│   ├── quick-reference.md    # Quick reference
│   ├── prompt-library.md     # Libreria prompt
│   ├── implementation-details.md # Dettagli implementazione
│   ├── deploy-checklist.md   # Checklist deploy
│   └── changelog.md          # Changelog
│
└── config/                   # Configurazione
    └── standards.md          # Standard qualità
```

---

## ⚡ QUICK START

### 1. Richiesta generica
```
"Analizza il progetto e trova i bug"
→ Orchestrator lancia N Analyzer paralleli
→ Riceve report
→ Lancia N Coder paralleli per fix
→ Reviewer valida
→ DocWriter aggiorna
```

### 2. Richiesta specifica
```
"Implementa feature X nel modulo Y"
→ Orchestrator lancia 1 Analyzer su Y
→ Pianifica task
→ Lancia Coder (+ Expert se serve)
→ Reviewer valida
→ DocWriter aggiorna
```

### 3. Richiesta complessa
```
"Rifai l'architettura del database"
→ Orchestrator lancia Analyzer
→ Chiama Database Expert
→ Pianifica migration
→ Coder implementa
→ Security Expert review
→ Reviewer finale
→ DocWriter documenta
```

---

## 📏 STANDARD QUALITÀ

- **Coverage test:** ≥80%
- **Complessità ciclomatica:** <10
- **Max righe/funzione:** 30
- **Max righe/file:** 300
- **Type hints:** Obbligatori
- **Docstrings:** Metodi pubblici

---

## 📍 RIFERIMENTO FILE SPOSTATI (v2.0)

### Organizzazione File Sistema
I seguenti file sono stati riorganizzati per migliorare la struttura:

| File Originale | Nuovo Percorso | Contenuto |
|---|---|---|
| `AGENT_REGISTRY.md` | `system/AGENT_REGISTRY.md` | Registry centralizzato agenti |
| `COMMUNICATION_HUB.md` | `system/COMMUNICATION_HUB.md` | Hub comunicazione inter-agenti |
| `PROTOCOL.md` | `system/PROTOCOL.md` | Protocolli di comunicazione |
| `TASK_TRACKER.md` | `system/TASK_TRACKER.md` | Tracking task distribuito |
| `SYSTEM_ARCHITECTURE.md` | `docs/SYSTEM_ARCHITECTURE.md` | Architettura di sistema |
| `README.md` | `docs/README.md` | Documentazione generale |
| `INTEGRATION_REPORT.md` | `docs/INTEGRATION_REPORT.md` | Report integrazione |

**Aggiornamento:** 25 Gennaio 2026 - Reorganizzazione file sistema
**Aggiornamento:** 29 Gennaio 2026 - Aggiunta 6 nuovi agent (V5.1)

---

## 🔑 QUICK REFERENCE - KEYWORD → EXPERT

| Keyword | Expert File | Model |
|---------|-------------|-------|
| GUI, PyQt5, widget, tab, dialog | `experts/gui-super-expert.md` | sonnet |
| Test, debug, bug, QA, performance | `experts/tester_expert.md` | sonnet |
| Database, SQL, query, schema | `experts/database_expert.md` | sonnet |
| Security, auth, encryption, JWT | `experts/security_unified_expert.md` | sonnet |
| MQL, EA, MetaTrader | `experts/mql_expert.md` | sonnet |
| Trading, risk, TP, SL | `experts/trading_strategy_expert.md` | sonnet |
| Architettura, design pattern | `experts/architect_expert.md` | opus |
| API, REST, webhook, cTrader | `experts/integration_expert.md` | sonnet |
| DevOps, deploy, CI/CD, Docker | `experts/devops_expert.md` | haiku |
| Python, JavaScript, C# | `experts/languages_expert.md` | sonnet |
| AI, LLM, GPT, OpenAI | `experts/ai_integration_expert.md` | sonnet |
| Claude, Haiku, Sonnet, Opus | `experts/claude_systems_expert.md` | sonnet |
| Mobile, iOS, Android, Flutter | `experts/mobile_expert.md` | sonnet |
| N8N, automation, workflow | `experts/n8n_expert.md` | sonnet |
| OAuth, OIDC, social login | `experts/social_identity_expert.md` | sonnet |
| Cerca file, esplora codebase | `core/analyzer.md` | haiku |
| Implementa, fix bug | `core/coder.md` | sonnet |
| Review, quality check | `core/reviewer.md` | sonnet |
| Documenta, README | `core/documenter.md` | haiku |
| Token, resource, agent mgmt | `core/system_coordinator.md` | haiku |

---

## 🔁 RALPH LOOP - SVILUPPO ITERATIVO

Ralph Loop è una metodologia per task iterativi che richiedono raffinamento continuo.

### Quando Usare
- ✅ TDD (Test-Driven Development)
- ✅ Feature con test automatici
- ✅ Bug fix con regression test
- ✅ Task con criteri di successo misurabili
- ❌ Task che richiedono giudizio umano
- ❌ Design/UX decisions

### Comandi
```bash
# Avvia loop iterativo
/ralph-loop "<prompt>" --max-iterations <N> --completion-promise "<TESTO>"

# Cancella loop attivo
/cancel-ralph
```

### Esempio
```bash
/ralph-loop "Implementa API utenti con TDD:
1. Crea test
2. Implementa
3. Esegui test
4. Se fallisce → fix e torna a 3
Output <promise>DONE</promise> quando test passano."
--max-iterations 20 --completion-promise "DONE"
```

**Dettagli completi:** Vedi sezione "RALPH LOOP INTEGRATION" in `core/orchestrator.md`

---

**Ultimo aggiornamento:** 29 Gennaio 2026 - V5.2 con 20 agent + Ralph Loop Integration

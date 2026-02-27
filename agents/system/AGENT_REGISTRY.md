---
name: Agent Registry
description: Centralized registry for agent routing and keyword mapping
---

# AGENT REGISTRY V2.0 - Registro Centralizzato Competenze

> **Versione:** 6.0 - L2 Sub-Agents Integration
> **Data:** 2 Febbraio 2026
> **Scopo:** Mappatura COMPLETA task → agent per routing automatico (3 livelli)
> **Usato da:** orchestrator.md per selezione agent
> **Totale Agent:** 43 (6 Core + 22 L1 Expert + 15 L2 Specialist)

---

## QUICK LOOKUP - KEYWORD → AGENT

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  RICERCA RAPIDA: Trova l'agent giusto per parola chiave                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  GUI/UI/UX/PyQt/stile/colori/pulsanti → gui-super-expert                   │
│  API/Telegram/cTrader/MT5/webhook → integration_expert                      │
│  Database/SQL/SQLite/query/schema → database_expert                         │
│  Security/auth/encryption/OWASP → security_unified_expert                   │
│  Trading/risk/position/drawdown/prop firm → trading_strategy_expert         │
│  MQL4/MQL5/EA/Expert Advisor → mql_expert                                   │
│  Test/QA/debug/coverage → tester_expert                                     │
│  Mobile/iOS/Android/Flutter → mobile_expert                                 │
│  Python/JS/TypeScript/C#/Rust → languages_expert                           │
│  Architettura/design/pattern/scaling → architect_expert                     │
│  DevOps/CI/CD/Docker/K8s → devops_expert                                    │
│  N8N/automazione/workflow/low-code → n8n_expert                             │
│  AI/LLM/Claude/GPT/RAG → ai_integration_expert                              │
│  OAuth/Google/Apple/Facebook login → social_identity_expert                 │
│  Claude API/costi/token/model → claude_systems_expert                       │
│                                                                             │
│  Analisi codice/struttura → analyzer (core)                                 │
│  Implementazione/coding → coder (core)                                      │
│  Review/validazione → reviewer (core)                                       │
│  Documentazione/README → documenter (core)                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## MATRICE COMPLETA ROUTING

### CORE AGENTS (Sempre disponibili)

| Agent | File | Trigger Keywords | Quando Usare | Model |
|-------|------|------------------|--------------|-------|
| **orchestrator** | `core/orchestrator.md` | - | Entry point OGNI task | opus |
| **analyzer** | `core/analyzer.md` | analizza, struttura, dipendenze, audit | Prima di implementare | haiku |
| **coder** | `core/coder.md` | implementa, scrivi, crea, aggiungi | Implementazione codice | haiku/sonnet |
| **reviewer** | `core/reviewer.md` | review, valida, controlla, verifica | Post-implementazione | haiku |
| **documenter** | `core/documenter.md` | documenta, README, CHANGELOG | Documentazione | haiku |

---

### EXPERT AGENTS (Specializzati)

#### GUI & Frontend

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **gui-super-expert** | `experts/gui-super-expert.md` | GUI, UI, UX, PyQt5, pulsanti, stile, colori, form, finestra, tab, layout, widget, design system, responsive, accessibilità | Design Systems, PyQt5/PySide, CSS, Accessibility WCAG, Animation, State Management | haiku |

#### Integrations & APIs

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **integration_expert** | `experts/integration_expert.md` | API, Telegram, cTrader, MetaTrader, webhook, REST, gRPC, protobuf, socket, SSL | Telegram Bot API, Telethon, cTrader Open API, MT5 API, TradingView Webhooks, WhatsApp Business | sonnet |

#### Database

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **database_expert** | `experts/database_expert.md` | database, SQL, SQLite, PostgreSQL, query, schema, migrazione, indici, ottimizzazione | Schema Design, Query Optimization, Migrations, Connection Pooling, WAL Mode, ACID | haiku/sonnet |

#### Security

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **security_unified_expert** | `experts/security_unified_expert.md` | security, auth, autenticazione, autorizzazione, encryption, AES, OWASP, vulnerabilità, JWT, token | AppSec, IAM, Cyber Defense, OWASP Top 10, Threat Modeling, Penetration Testing | sonnet |

#### Trading Domain

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **trading_strategy_expert** | `experts/trading_strategy_expert.md` | trading, risk, position sizing, drawdown, prop firm, xFunded, FTMO, TP, SL, break even | Risk Management, Position Sizing, Prop Firm Compliance, Multi-TP, Partial Close | sonnet |
| **mql_expert** | `experts/mql_expert.md` | MQL4, MQL5, Expert Advisor, EA, OnTimer, OnTick, OrderSend, MT4, MT5 | EA Architecture, Trade Execution MQL, CSV Parsing MQL, WebRequest, CPU Optimization | sonnet |

#### Testing & QA

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **tester_expert** | `experts/tester_expert.md` | test, testing, QA, debug, coverage, pytest, unittest, bug critico | Test Architecture, Rapid Testing, QA Strategy, Debugging, CI Integration | haiku/sonnet |

#### Mobile

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **mobile_expert** | `experts/mobile_expert.md` | mobile, iOS, Android, Flutter, React Native, app store, APK | Native iOS/Android, Cross-Platform, App Store Guidelines, Push Notifications | sonnet |

#### Languages & Coding

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **languages_expert** | `experts/languages_expert.md` | Python, JavaScript, TypeScript, C#, Rust, Go, sintassi, idiomi, performance | Syntax, Idioms, Performance Tuning, Best Practices, Type Systems | haiku/sonnet |

#### Architecture

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **architect_expert** | `experts/architect_expert.md` | architettura, design, pattern, scaling, microservizi, monolite, CQRS, event sourcing | System Design, API Design, Trade-offs, ADR, C4 Diagrams, DDD | sonnet |

#### DevOps & Infrastructure

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **devops_expert** | `experts/devops_expert.md` | DevOps, CI/CD, Docker, Kubernetes, terraform, AWS, Azure, monitoring | IaC, CI/CD Pipelines, Container Orchestration, Observability, SRE | sonnet |

#### Automation

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **n8n_expert** | `experts/n8n_expert.md` | N8N, automazione, workflow, low-code, Zapier, Make | Workflow Automation, Low-Code Integration, Trigger Design | haiku |

#### AI & LLM

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **ai_integration_expert** | `experts/ai_integration_expert.md` | AI, LLM, GPT, embedding, RAG, prompt engineering, fine-tuning | LLM APIs, Prompt Engineering, RAG Architecture, Model Selection | sonnet |
| **claude_systems_expert** | `experts/claude_systems_expert.md` | Claude, Anthropic, API Claude, costi token, model selection, haiku/sonnet/opus | Claude API Optimization, Cost Management, Caching, Rate Limiting | haiku |

#### Identity & Auth

| Agent | File | Keywords | Competenze Specifiche | Model |
|-------|------|----------|----------------------|-------|
| **social_identity_expert** | `experts/social_identity_expert.md` | OAuth, Google login, Apple login, Facebook, Microsoft, OIDC, PKCE | OAuth2/OIDC Providers, PKCE, Account Linking, Token Validation | sonnet |

---

## L2 SUB-AGENTS (Specialisti di Secondo Livello)

> **Regola:** Gli L1 Expert delegano automaticamente agli L2 per task specifici
> **Path:** `experts/L2/[nome]-specialist.md`
> **Model Default:** sonnet (problem solving specializzato)

### Mappatura L1 → L2

| L1 Expert | L2 Sub-Agent | File | Keywords Specifiche | Competenze L2 |
|-----------|--------------|------|---------------------|---------------|
| **gui-super-expert** | gui-layout-specialist | `experts/L2/gui-layout-specialist.md` | sidebar, form, grid, layout, dashboard, wizard, collapsible | Qt Layout Manager, Responsive Design, Complex Forms |
| **database_expert** | db-query-optimizer | `experts/L2/db-query-optimizer.md` | query lenta, N+1, index, pagination, bulk, cache query | Query Optimization, Index Strategy, Materialized Views |
| **integration_expert** | api-endpoint-builder | `experts/L2/api-endpoint-builder.md` | endpoint, CRUD, rate limit, versioning, OpenAPI | REST Design, FastAPI Patterns, API Versioning |
| **security_unified_expert** | security-auth-specialist | `experts/L2/security-auth-specialist.md` | JWT, refresh token, MFA, TOTP, brute force, RBAC | JWT Flows, MFA Implementation, Session Security |
| **trading_strategy_expert** | trading-risk-calculator | `experts/L2/trading-risk-calculator.md` | position size, Kelly, drawdown, R:R, portfolio risk | Position Sizing Algorithms, Kelly Criterion, Correlation Risk |
| **mql_expert** | mql-optimization | `experts/L2/mql-optimization.md` | CPU, memoria, tick, array, cache, handle, backtest | EA Performance, Memory Management, Tick Processing |
| **tester_expert** | test-unit-specialist | `experts/L2/test-unit-specialist.md` | pytest, fixture, mock, parametrize, coverage, TDD | pytest Advanced, Mocking, Property-Based Testing |
| **mobile_expert** | mobile-ui-specialist | `experts/L2/mobile-ui-specialist.md` | responsive, SafeArea, RefreshIndicator, adaptive | Flutter/RN Layouts, Platform-Adaptive UI, Responsive Design |
| **languages_expert** | languages-refactor-specialist | `experts/L2/languages-refactor-specialist.md` | refactor, code smell, clean code, extract, rename | Refactoring Patterns, Code Smells, Clean Code |
| **architect_expert** | architect-design-specialist | `experts/L2/architect-design-specialist.md` | pattern, SOLID, DDD, microservizi, bounded context | Design Patterns, SOLID Principles, DDD Tactical |
| **devops_expert** | devops-pipeline-specialist | `experts/L2/devops-pipeline-specialist.md` | pipeline, GitHub Actions, Docker build, multi-stage | CI/CD Pipelines, GitHub Actions, Docker Optimization |
| **n8n_expert** | n8n-workflow-builder | `experts/L2/n8n-workflow-builder.md` | workflow, webhook, error handling, batch, sub-workflow | Workflow Design, Error Recovery, Batch Processing |
| **ai_integration_expert** | ai-model-specialist | `experts/L2/ai-model-specialist.md` | model selection, fine-tune, RAG, embedding, vector | Model Comparison, RAG Architecture, Embedding Strategy |
| **claude_systems_expert** | claude-prompt-optimizer | `experts/L2/claude-prompt-optimizer.md` | prompt, token, few-shot, chain-of-thought, system prompt | Prompt Engineering, Token Optimization, Output Control |
| **social_identity_expert** | social-oauth-specialist | `experts/L2/social-oauth-specialist.md` | OAuth flow, PKCE, provider, callback, token exchange | OAuth2 Implementation, Provider-Specific Flows, PKCE |

### Routing L1 → L2 Automatico

```
┌─────────────────────────────────────────────────────────────────┐
│  L1 EXPERT riceve task                                          │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Task richiede competenza SPECIALIZZATA?                │   │
│  │  (keyword L2 presente nel task)                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│            │                    │                               │
│           YES                  NO                               │
│            │                    │                               │
│            ▼                    ▼                               │
│  ┌──────────────────┐   ┌──────────────────┐                   │
│  │  DELEGA a L2     │   │  L1 gestisce     │                   │
│  │  Sub-Agent       │   │  direttamente    │                   │
│  └──────────────────┘   └──────────────────┘                   │
│            │                                                    │
│            ▼                                                    │
│  L2 esegue con expertise specializzato                         │
│  L2 ritorna risultato a L1                                      │
│  L1 integra e ritorna a Orchestrator                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## DECISION TREE - SELEZIONE AUTOMATICA

```
                        ┌─────────────────┐
                        │  TASK RICEVUTO  │
                        └────────┬────────┘
                                 │
                    ┌────────────┴────────────┐
                    │  È task GUI/UI/UX?      │
                    └────────────┬────────────┘
                           YES   │   NO
                    ┌────────────┘   └────────────┐
                    ▼                             ▼
           gui-super-expert              ┌───────────────────┐
                                         │  È task API/Integ? │
                                         └─────────┬─────────┘
                                              YES  │  NO
                                         ┌────────┘  └────────┐
                                         ▼                    ▼
                               integration_expert    ┌─────────────────┐
                                                     │  È task DB/SQL?  │
                                                     └────────┬────────┘
                                                         YES  │  NO
                                                    ┌─────────┘  └─────────┐
                                                    ▼                      ▼
                                          database_expert         ┌──────────────────┐
                                                                  │  È task Security? │
                                                                  └────────┬─────────┘
                                                                      YES  │  NO
                                                                 ┌─────────┘  └─────────┐
                                                                 ▼                      ▼
                                                    security_unified_expert    ┌──────────────────┐
                                                                               │  È task Trading?  │
                                                                               └────────┬─────────┘
                                                                                   YES  │  NO
                                                                              ┌─────────┘  └─────────┐
                                                                              ▼                      ▼
                                                                 ┌─────────────────┐        ┌──────────────┐
                                                                 │  È MQL/EA?      │        │  DEFAULT     │
                                                                 └────────┬────────┘        │  coder +     │
                                                                     YES  │  NO             │  analyzer    │
                                                                ┌─────────┘  └──────┐       └──────────────┘
                                                                ▼                   ▼
                                                          mql_expert    trading_strategy_expert
```

---

## COMBINAZIONI COMUNI (Multi-Agent)

### Scenario: Nuova Feature GUI
```
| # | Agent | Task |
|---|-------|------|
| 1 | analyzer | Analizza struttura esistente |
| 2 | gui-super-expert | Design e implementazione UI |
| 3 | coder | Logica backend se necessaria |
| 4 | reviewer | Validazione |
```

### Scenario: Integrazione API Trading
```
| # | Agent | Task |
|---|-------|------|
| 1 | analyzer | Analizza API target |
| 2 | integration_expert | Implementa client API |
| 3 | trading_strategy_expert | Logica trading |
| 4 | database_expert | Persistenza dati |
| 5 | security_unified_expert | Review sicurezza |
```

### Scenario: Bug Fix Critico
```
| # | Agent | Task |
|---|-------|------|
| 1 | tester_expert | Isola e riproduce bug |
| 2 | analyzer | Identifica root cause |
| 3 | coder | Fix implementazione |
| 4 | reviewer | Valida fix |
```

### Scenario: Expert Advisor MT5
```
| # | Agent | Task |
|---|-------|------|
| 1 | mql_expert | Implementazione EA |
| 2 | trading_strategy_expert | Logica risk management |
| 3 | tester_expert | Test su demo |
```

### Scenario: Autenticazione Social
```
| # | Agent | Task |
|---|-------|------|
| 1 | social_identity_expert | OAuth2 flow |
| 2 | security_unified_expert | Security review |
| 3 | database_expert | Storage token/session |
| 4 | gui-super-expert | UI login buttons |
```

---

## FALLBACK & ESCALATION

```
┌─────────────────────────────────────────────────────────────────┐
│  ESCALATION CHAIN                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LIVELLO 1: Agent specifico (haiku)                            │
│      │                                                          │
│      ▼ Se fallisce o task complesso                            │
│  LIVELLO 2: Agent specifico (sonnet)                           │
│      │                                                          │
│      ▼ Se fallisce o serve decisione architettonica            │
│  LIVELLO 3: architect_expert + agent specifico                 │
│      │                                                          │
│      ▼ Se conflitto o decisione critica                        │
│  LIVELLO 4: Orchestrator chiede all'utente                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## AGENT STATUS CODES

| Status | Significato | Azione Orchestrator |
|--------|-------------|---------------------|
| `SUCCESS` | Task completato | Procedi |
| `PARTIAL` | Completato con warning | Review + procedi |
| `FAILED` | Task fallito | Retry con sonnet o escalate |
| `BLOCKED` | Dipendenza mancante | Risolvi dipendenza prima |
| `NEEDS_INFO` | Informazioni insufficienti | Chiedi all'utente |
| `ESCALATE` | Serve expert superiore | Chiama expert suggerito |

---

## REGOLE DI ROUTING

### Regola 1: Keyword Matching
Se il task contiene keyword di un expert → usa quell'expert

### Regola 2: Multi-Expert
Se task tocca più domini → lancia agent multipli in parallelo

### Regola 3: Model Default
- **haiku** per task semplici, GUI, config, doc
- **sonnet** per implementazione, analisi complessa
- **opus** MAI per agent (solo orchestrator)

### Regola 4: Parallelismo
Se agent non hanno dipendenze → lancia TUTTI in parallelo

### Regola 5: Sequenza Obbligatoria
```
analyzer → coder → reviewer → documenter
```
Questo ordine quando serve implementazione completa.

---

## METRICHE AGENT

| Agent | Task Tipici/Settimana | Success Rate Target | Model Default |
|-------|----------------------|---------------------|---------------|
| gui-super-expert | 15-20 | 95% | haiku |
| integration_expert | 10-15 | 90% | sonnet |
| database_expert | 8-12 | 95% | haiku |
| security_unified_expert | 5-8 | 98% | sonnet |
| trading_strategy_expert | 10-15 | 92% | sonnet |
| mql_expert | 5-10 | 90% | sonnet |
| tester_expert | 8-12 | 95% | haiku |
| coder | 20-30 | 93% | haiku |
| analyzer | 25-35 | 97% | haiku |

---

## CHANGELOG

### V2.0 - 2 Febbraio 2026
- **NUOVO:** Sezione L2 SUB-AGENTS completa (15 specialist)
- **NUOVO:** Mappatura L1 → L2 con keywords specifiche
- **NUOVO:** Routing automatico L1 → L2 documentato
- Aggiornamento totale agent: 43 (6 Core + 22 L1 Expert + 15 L2 Specialist)

### V1.0 - 25 Gennaio 2026
- Creazione registry completo 15 expert + 4 core
- Decision tree per routing automatico
- Combinazioni comuni multi-agent
- Sistema escalation
- Status codes standardizzati

---

**USO:** Questo file è il LOOKUP principale per l'orchestrator.
Prima di lanciare qualsiasi agent, consulta questo registro.

**GERARCHIA:** L0 (Core) → L1 (Expert) → L2 (Sub-Agent)
**DELEGAZIONE:** L1 delega automaticamente a L2 per task specializzati.

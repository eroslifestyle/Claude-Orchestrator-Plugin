---
name: Sistema Agenti Index
description: Quick navigation index for the multi-agent system with links to all agents and docs
---

# SISTEMA AGENTI - INDICE RAPIDO

> **Data:** 8 Febbraio 2026
> **Versione:** 7.0 SLIM - Anti-Direct Enforcement + Maximum Parallelism + Simplicity Focus
> **Entry Point:** Questo file + docs/README.md

---

## NAVIGAZIONE RAPIDA

### ENTRY POINT PRINCIPALE
- **docs/README.md** - Overview completo del sistema
- **system/PROTOCOL.md** - Protocollo comunicazione (OBBLIGATORIO per tutti gli agent)
- **CLAUDE.md** - Istruzioni globali sistema
- **system/AGENT_REGISTRY.md** - Routing task → agent (V1.0)
- **system/COMMUNICATION_HUB.md** - Protocollo messaggi strutturato (V1.0)
- **system/TASK_TRACKER.md** - Template tracking sessioni (V1.0)
- **docs/SYSTEM_ARCHITECTURE.md** - Architettura completa multi-agent (V1.0)

---

## GERARCHIA AGENT (3 Livelli)

```
┌─────────────────────────────────────────────────────────────────┐
│  ORCHESTRATOR V7.0 SLIM - GERARCHIA COMPLETA                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  L0 - CORE (6 agent)                                           │
│  └── orchestrator, analyzer, coder, reviewer, documenter,      │
│      system_coordinator                                         │
│                                                                 │
│  L1 - EXPERTS (18 expert)                                      │
│  └── gui-super, database, integration, security_unified,       │
│      trading_strategy, mql, mql_decompilation, tester, mobile, │
│      languages, architect, devops, n8n, ai_integration,        │
│      claude_systems, social_identity, reverse_engineering,     │
│      offensive_security                                         │
│                                                                 │
│  L2 - SUB-AGENTS (15 specialist)                               │
│  └── gui-layout, db-query-optimizer, api-endpoint-builder,     │
│      security-auth, trading-risk-calculator, mql-optimization, │
│      test-unit, mobile-ui, languages-refactor, architect-design,│
│      devops-pipeline, n8n-workflow, ai-model, claude-prompt,   │
│      social-oauth                                               │
│                                                                 │
│  TOTALE: 39 AGENT OPERATIVI                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## CORE AGENTS (core/)

| File | Ruolo | Quando Usare |
|------|-------|--------------|
| **orchestrator.md** | Coordinatore centrale V7.0 SLIM | SEMPRE - Entry point per ogni task |
| **system_coordinator.md** | Assistente orchestrator | Manutenzione file sistema |
| **analyzer.md** | Analisi codice | Analisi rapida moduli |
| **coder.md** | Implementazione | Scrittura codice |
| **reviewer.md** | Code review | Revisione qualità |
| **documenter.md** | Documentazione | Aggiornamento doc |

---

## EXPERTS (experts/)

| File | Specializzazione | Competenze |
|------|------------------|-----------|
| **gui-super-expert.md** | GUI/UX | Design Systems, Accessibility, PyQt5 |
| **integration_expert.md** | API/Trading Integration | Telegram, MetaTrader, cTrader, TradingView, messaging |
| **database_expert.md** | Database | Schema, Query optimization, SQLite |
| **security_unified_expert.md** | 🔒 Security UNIFICATO | AppSec + IAM + Cyber Defense (sostituisce 3 expert) |
| **trading_strategy_expert.md** | 📈 Trading Strategy | Risk Management, Position Sizing, Prop Firm Compliance |
| **mql_expert.md** | 📊 MQL4/MQL5 | EA Architecture, CPU 0%, Trade Execution, CSV Parsing |
| **tester_expert.md** | Quality Assurance | Test Architecture, Rapid Testing, QA Strategy |
| **mobile_expert.md** | Mobile Development | iOS/Android, Native & Cross-Platform, App Store |
| **languages_expert.md** | Programming Languages | Syntax, Idioms, Performance, Best Practices |
| **architect_expert.md** | Software Architecture | System Design, API Design, Trade-offs, ADR, C4 Diagrams |
| **devops_expert.md** | DevOps & SRE | IaC, CI/CD, Kubernetes, Monitoring, Observability |
| **n8n_expert.md** | N8N & Automation | Workflow Automation, Low-Code, Integration, DevOps |
| **ai_integration_expert.md** | AI Integration | LLM APIs, Prompt Engineering, RAG, Model Selection |
| **social_identity_expert.md** | 🔑 Social & External Identity | OAuth2/OIDC, Google, Apple, Microsoft, Facebook, GitHub |
| **claude_systems_expert.md** | 🤖 Claude Ecosystem | Model Selection, Cost Optimization, API Patterns, Caching |
| **reverse_engineering_expert.md** | 🔍 Reverse Engineering | Binary Analysis, IDA Pro, Ghidra, Decompilation, Malware Analysis |
| **offensive_security_expert.md** | 🎯 Offensive Security & Pentesting | Penetration Testing, Exploit Development, Red Team, OWASP, Security Assessment |
| **mql_decompilation_expert.md** | 🔓 MQL Decompilation Expert | Reverse engineering file .ex4/.ex5, decompilazione Expert Advisors, bypass protezioni MetaTrader |

---

## L2 SUB-AGENTS (experts/L2/)

> **Specialisti di secondo livello** - Delegati dagli L1 Expert per task specifici

| File | Parent Expert | Specializzazione | Model |
|------|---------------|------------------|-------|
| **gui-layout-specialist.md** | gui-super-expert | Layout Qt, Sidebar, Form, Grid, Dashboard | sonnet |
| **db-query-optimizer.md** | database_expert | Query optimization, Index, N+1, Pagination | sonnet |
| **api-endpoint-builder.md** | integration_expert | REST endpoints, CRUD, Rate limiting, Versioning | sonnet |
| **security-auth-specialist.md** | security_unified_expert | JWT, MFA, TOTP, Brute force protection, RBAC | sonnet |
| **trading-risk-calculator.md** | trading_strategy_expert | Position sizing, Kelly criterion, Drawdown, R:R | sonnet |
| **mql-optimization.md** | mql_expert | EA performance, Memory, Tick processing, Cache | sonnet |
| **test-unit-specialist.md** | tester_expert | pytest, Mocking, Fixtures, Coverage, TDD | sonnet |
| **mobile-ui-specialist.md** | mobile_expert | Flutter layout, React Native, Responsive, SafeArea | sonnet |
| **languages-refactor-specialist.md** | languages_expert | Refactoring patterns, Code smells, Clean code | sonnet |
| **architect-design-specialist.md** | architect_expert | Design patterns, SOLID, DDD, Microservices | sonnet |
| **devops-pipeline-specialist.md** | devops_expert | CI/CD pipelines, GitHub Actions, Docker builds | sonnet |
| **n8n-workflow-builder.md** | n8n_expert | Workflow design, Error handling, Batch processing | sonnet |
| **ai-model-specialist.md** | ai_integration_expert | Model selection, Fine-tuning, RAG optimization | sonnet |
| **claude-prompt-optimizer.md** | claude_systems_expert | Prompt engineering, Token optimization, Few-shot | sonnet |
| **social-oauth-specialist.md** | social_identity_expert | OAuth2 flows, PKCE, Provider integration | sonnet |

---

## WORKFLOWS (workflows/)

| File | Descrizione |
|------|-------------|
| **bugfix.md** | Workflow fix bug standardizzato |
| **feature.md** | Workflow sviluppo feature |
| **refactoring.md** | Workflow refactoring codice |
| **OPTIMIZED.md** | Workflow ottimizzati |

---

## TEMPLATES (templates/)

| File | Uso |
|------|-----|
| **integration.md** | Template integrazione moduli |
| **review.md** | Template code review |
| **task.md** | Template task generici |

---

## DOCUMENTAZIONE (docs/)

| File | Contenuto |
|------|-----------|
| **getting-started.md** | Guida introduttiva (START HERE per nuovi agent) |
| **quickstart.md** | Quick start rapido |
| **quick-reference.md** | Lookup comandi comuni |
| **orchestrator-examples.md** | Esempi pratici orchestrazione V7.0 |
| **orchestrator-advanced.md** | Features avanzate: escalation, error handling |
| **changelog.md** | Storico modifiche |
| **implementation-details.md** | Dettagli tecnici implementazione |
| **prompt-library.md** | Libreria prompt utili |
| **deploy-checklist.md** | Checklist deployment |

---

## CONFIGURAZIONE (config/)

| File | Contenuto |
|------|-----------|
| **routing.md** | Tabelle routing keyword -> agent |
| **circuit-breaker.json** | Stato health agent e fallback |
| **standards.md** | Standard codifica |

---

## QUICK START PER NUOVI AGENT

1. Leggi **docs/getting-started.md** (5 min)
2. Leggi **system/PROTOCOL.md** (10 min) - OBBLIGATORIO
3. Leggi **docs/README.md** (15 min)
4. Identifica il tuo ruolo:
   - Orchestrator → **core/orchestrator.md**
   - Analyzer → **core/analyzer.md**
   - Expert specifico → **experts/[expert].md**
5. Inizia a lavorare seguendo system/PROTOCOL.md

---

## FLUSSO TASK STANDARD

```
User Request
    ↓
core/orchestrator.md (coordina)
    ↓
core/analyzer.md (analizza)
    ↓
experts/[expert].md (implementa)
    ↓
core/reviewer.md (valida)
    ↓
core/documenter.md (documenta)
    ↓
Output finale
```

---

## REGOLE CRITICHE

1. **system/PROTOCOL.md è OBBLIGATORIO** - Tutti gli output DEVONO seguirlo
2. **Handoff SEMPRE a orchestrator** - Zero comunicazione diretta tra agent
3. **Anti-Direct Enforcement (R-4)** - BLOCCO TOTALE task diretti a sub-agent (bypass orchestrator = FATAL ERROR)
4. **Model AI selection** - Haiku per semplici, Sonnet standard, Opus complessi
5. **Struttura rispettata** - File organizzati in cartelle dedicate

---

## METRICHE SISTEMA

- **Totale file .md:** ~57
- **Root:** 2 file (CLAUDE.md, INDEX.md)
- **System:** 8 file (PROTOCOL, AGENT_REGISTRY, COMMUNICATION_HUB, TASK_TRACKER, DEPENDENCY_GRAPH, PARALLEL_COORDINATOR, TASK_DECOMPOSITION, COMPLETION_NOTIFIER)
- **Core agents (L0):** 6 file + TODOLIST.md
- **Experts (L1):** 16 attivi
- **Sub-Agents (L2):** 15 specialist
- **Workflows:** 4 file
- **Templates:** 3 file
- **Docs:** 11 file (README, SYSTEM_ARCHITECTURE, INTEGRATION_REPORT, getting-started, quickstart, quick-reference, orchestrator-examples, orchestrator-advanced, changelog, implementation-details, prompt-library, deploy-checklist)
- **Config:** 3 file (routing.md, circuit-breaker.json, standards.md)

### Gerarchia Completa: 39 Agent

**L0 Core (6):**
- orchestrator, analyzer, coder, reviewer, documenter, system_coordinator

**L1 Expert (18):**
- gui-super-expert, integration, database, security_unified
- trading_strategy, mql, mql_decompilation, tester, mobile
- languages, architect, devops, n8n, ai_integration
- social_identity, claude_systems, reverse_engineering, offensive_security

**L2 Sub-Agent (15):**
- gui-layout, db-query-optimizer, api-endpoint-builder
- security-auth, trading-risk-calculator, mql-optimization
- test-unit, mobile-ui, languages-refactor
- architect-design, devops-pipeline, n8n-workflow
- ai-model, claude-prompt, social-oauth

---

## PATH ASSOLUTI COMUNI

```bash
# Entry point
~/.claude/agents/docs/README.md
~/.claude/agents/system/PROTOCOL.md

# Core
~/.claude/agents/core/orchestrator.md
~/.claude/agents/core/analyzer.md

# Experts
~/.claude/agents/experts/gui-super-expert.md
~/.claude/agents/experts/integration_expert.md

# Docs
~/.claude/agents/docs/getting-started.md
~/.claude/agents/docs/quick-reference.md

# System
~/.claude/agents/system/AGENT_REGISTRY.md
~/.claude/agents/system/COMMUNICATION_HUB.md
~/.claude/agents/system/TASK_TRACKER.md
~/.claude/agents/system/PROTOCOL.md
```

---

## SUPPORTO

Per domande, consulta in ordine:

1. **docs/getting-started.md** - Guida base
2. **docs/quick-reference.md** - Lookup rapido
3. **system/PROTOCOL.md** - Standard output
4. **docs/README.md** - Overview completo
5. File specifico del tuo ruolo

---

**Status:** Production Ready
**Versione:** 7.0 SLIM - Anti-Direct Enforcement + Maximum Parallelism
**Data:** 8 Febbraio 2026
**Qualità:** 100% organizzato - Gerarchia 3 livelli completa (L0/L1/L2)
**Ultimo aggiornamento:** Aggiunto MQL Decompilation Expert (39 agent totali)

Buon lavoro!

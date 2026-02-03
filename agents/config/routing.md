---
name: Agent Routing Configuration
description: Routing configuration for agent selection including keyword mapping, model selection rules, and agent fallback patterns
version: 6.0
---

# 🎯 ROUTING TABLE V6.0

> **Ultima modifica:** 2 Febbraio 2026
> **Versione:** 6.0 ULTRA

---

## KEYWORD → AGENT MAPPING

### L1 Expert Agents

| Keyword | Agent | Model | Level |
|---------|-------|-------|-------|
| GUI, PyQt5, Qt, widget, dialog, layout, UI | gui-super-expert.md | sonnet | L1 |
| database, SQL, SQLite, PostgreSQL, schema, migration | database_expert.md | sonnet | L1 |
| security, encryption, auth, JWT, OWASP, hash | security_unified_expert.md | sonnet | L1 |
| API, REST, webhook, integration, client, server | integration_expert.md | sonnet | L1 |
| test, debug, QA, performance, profiling | tester_expert.md | sonnet | L1 |
| MQL, MQL5, EA, MetaTrader, OnTimer, OnTick | mql_expert.md | sonnet | L1 |
| trading, risk, position, TP, SL, strategy | trading_strategy_expert.md | sonnet | L1 |
| architettura, design, pattern, microservizi | architect_expert.md | opus | L1 |
| DevOps, deploy, CI/CD, Docker, build | devops_expert.md | haiku | L1 |
| Python, JavaScript, C#, coding, refactor | languages_expert.md | sonnet | L1 |
| AI, LLM, GPT, embedding, model | ai_integration_expert.md | sonnet | L1 |
| Claude, Haiku, Sonnet, Opus, token | claude_systems_expert.md | sonnet | L1 |
| mobile, iOS, Android, Swift, Kotlin, Flutter | mobile_expert.md | sonnet | L1 |
| n8n, automation, workflow, trigger | n8n_expert.md | sonnet | L1 |
| OAuth, OIDC, social login, Google, Facebook | social_identity_expert.md | sonnet | L1 |

### L2 Sub-Agent Mapping

| L2 Agent | Parent L1 | Keyword Trigger |
|----------|-----------|-----------------|
| gui-layout-specialist | gui-super-expert | layout, sizing, splitter |
| db-query-optimizer | database_expert | query, index, optimize |
| security-auth-specialist | security_unified_expert | auth, JWT, session |
| api-endpoint-builder | integration_expert | endpoint, route |
| test-unit-specialist | tester_expert | unit test, mock, pytest |
| mql-optimization | mql_expert | optimize EA, memory |
| trading-risk-calculator | trading_strategy_expert | risk, position size |
| mobile-ui-specialist | mobile_expert | mobile UI, responsive |
| n8n-workflow-builder | n8n_expert | workflow builder |
| claude-prompt-optimizer | claude_systems_expert | prompt optimize |
| architect-design-specialist | architect_expert | system design, patterns |
| devops-pipeline-specialist | devops_expert | pipeline, CI/CD |
| languages-refactor-specialist | languages_expert | refactor, clean code |
| ai-model-specialist | ai_integration_expert | LLM integration, RAG |
| social-oauth-specialist | social_identity_expert | OAuth flow, social login |

### L0 Core Agents

| Keyword | Agent | Model | Use Case |
|---------|-------|-------|----------|
| cerca, trova, esplora | core/analyzer.md | haiku | File search, exploration |
| implementa, fix, codifica | core/coder.md | sonnet | Coding, implementation |
| review, valida, quality | core/reviewer.md | sonnet | Code review |
| documenta, scrivi, README | core/documenter.md | haiku | Documentation |
| coordina, resource, token | core/system_coordinator.md | haiku | Resource management |

---

## DOMAIN PATTERN FALLBACK

| Pattern | Fallback Agent |
|---------|----------------|
| gui-* / ui-* / widget-* | gui-super-expert |
| db-* / data-* / sql-* | database_expert |
| security-* / auth-* / jwt-* | security_unified_expert |
| api-* / rest-* / integration-* | integration_expert |
| test-* / qa-* / debug-* | tester_expert |
| mql-* / ea-* / mt5-* | mql_expert |
| trading-* / risk-* | trading_strategy_expert |
| mobile-* / ios-* / android-* | mobile_expert |
| n8n-* / workflow-* / automation-* | n8n_expert |
| claude-* / prompt-* / ai-* | claude_systems_expert |
| arch-* / design-* | architect_expert |
| devops-* / deploy-* / ci-* | devops_expert |

---

## MODEL SELECTION RULES

```
┌─────────────────────────────────────────────────────────────┐
│  HAIKU: Task meccanici senza ragionamento                  │
│  → Lettura file, search, documentazione routine            │
│  → DevOps, build, deploy                                   │
│                                                             │
│  SONNET: Task con problem solving                          │
│  → Coding, fix bug, refactoring                            │
│  → API integration, database, security                     │
│  → Testing con logica                                      │
│                                                             │
│  OPUS: Task creativi/architetturali                        │
│  → System design, architettura                             │
│  → Decisioni strategiche                                   │
│  → Problemi complessi multi-dominio                        │
└─────────────────────────────────────────────────────────────┘
```

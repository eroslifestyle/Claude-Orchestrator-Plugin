---
name: Agents Index
description: Complete navigation index for the multi-agent system with all 43 agents
---

# AGENTS INDEX

> **Version:** 12.0 DEEP AUDIT
> **Total Agents:** 43 (6 Core + 22 L1 Experts + 15 L2 Specialists)
> **Last Updated:** 26 Febbraio 2026

---

## CORE AGENTS (6)

| Agent | Role | Model | Description |
|-------|------|-------|-------------|
| **orchestrator.md** | Central Coordinator | opus | Delegates ALL work to subagents, never executes directly |
| **analyzer.md** | Code Analysis | haiku | Structure exploration, dependency mapping, issue detection |
| **coder.md** | Implementation | sonnet | Writes and modifies code with tests |
| **reviewer.md** | Quality Validation | sonnet | Code review, best practices, security checks |
| **documenter.md** | Documentation | haiku | Manages project docs, todolist, worklog |
| **system_coordinator.md** | Resource Manager | haiku | Token tracking, metrics, file maintenance, cleanup |

---

## L1 EXPERTS (22)

| Agent | Role | Keywords |
|-------|------|----------|
| **ai_integration_expert.md** | AI Integration Specialist | LLM, GPT, AI model integration, RAG |
| **architect_expert.md** | Software Architecture Principal | distributed systems, blueprints, trade-offs |
| **browser_automation_expert.md** | Playwright/E2E Specialist | e2e testing, web scraping, browser automation |
| **claude_systems_expert.md** | Claude Ecosystem Optimizer | Haiku/Sonnet/Opus, cost efficiency, API patterns |
| **database_expert.md** | Database Architect | SQL, NoSQL, schema design, performance |
| **devops_expert.md** | DevOps & SRE Architect | CI/CD, IaC, Kubernetes, monitoring |
| **gui-super-expert.md** | GUI/UX Expert | PyQt5, design systems, accessibility |
| **integration_expert.md** | API Integration Master | Telegram, WhatsApp, MetaTrader, TradingView |
| **languages_expert.md** | Multi-Language Expert | Python, JavaScript, C#, idioms, best practices |
| **mcp_integration_expert.md** | MCP Protocol Specialist | tool discovery, resource handling, deferred loading |
| **mobile_expert.md** | Mobile Architect | iOS, Android, Flutter, cross-platform |
| **mql_decompilation_expert.md** | MQL Decompilation Expert | .ex4/.ex5 reverse engineering, EA analysis |
| **mql_expert.md** | MetaTrader Specialist | MQL4/MQL5, EA architecture, CPU optimization |
| **n8n_expert.md** | N8N Automation Architect | workflow design, low-code, integration |
| **notification_expert.md** | Messaging Platforms Expert | Slack, Discord, push notifications, alerts |
| **offensive_security_expert.md** | Penetration Testing Specialist | pentest, red team, exploit development, OWASP |
| **payment_integration_expert.md** | Payment Gateway Specialist | Stripe, PayPal, checkout, subscriptions |
| **reverse_engineering_expert.md** | Binary Analysis Expert | IDA Pro, Ghidra, malware, firmware |
| **security_unified_expert.md** | Security Architect | AppSec, IAM, encryption, cyber defense |
| **social_identity_expert.md** | OAuth/OIDC Specialist | Google, Facebook, Apple, social login |
| **tester_expert.md** | QA Architect | test architecture, debugging, rapid testing |
| **trading_strategy_expert.md** | Trading Strategy Expert | risk management, position sizing, prop firm |

---

## L2 SPECIALISTS (15)

| Agent | Parent Expert | Specialty |
|-------|---------------|-----------|
| **ai-model-specialist.md** | ai_integration_expert | Model selection, RAG, embeddings |
| **api-endpoint-builder.md** | integration_expert | REST endpoints, CRUD, versioning |
| **architect-design-specialist.md** | architect_expert | Design patterns, SOLID, DDD |
| **claude-prompt-optimizer.md** | claude_systems_expert | Prompt engineering, token optimization |
| **db-query-optimizer.md** | database_expert | Query optimization, indexing, N+1 fixes |
| **devops-pipeline-specialist.md** | devops_expert | CI/CD pipelines, GitHub Actions |
| **gui-layout-specialist.md** | gui-super-expert | Qt layouts, sidebars, dashboards |
| **languages-refactor-specialist.md** | languages_expert | Refactoring patterns, clean code |
| **mobile-ui-specialist.md** | mobile_expert | Flutter/React Native layouts |
| **mql-optimization.md** | mql_expert | EA performance, memory, tick processing |
| **n8n-workflow-builder.md** | n8n_expert | Workflow design, error handling |
| **security-auth-specialist.md** | security_unified_expert | JWT, MFA, session security |
| **social-oauth-specialist.md** | social_identity_expert | OAuth2 flows, provider integration |
| **test-unit-specialist.md** | tester_expert | pytest, mocking, fixtures, TDD |
| **trading-risk-calculator.md** | trading_strategy_expert | Position sizing, Kelly criterion |

---

## L1 EXPERTS - RECENT ADDITIONS (4)

> Added in V11.3 - Fully integrated with routing and circuit-breaker

| Agent | Keywords |
|-------|----------|
| **browser_automation_expert.md** | Playwright, e2e, web scraping |
| **mcp_integration_expert.md** | MCP tools, deferred loading |
| **notification_expert.md** | Slack, Discord, messaging |
| **payment_integration_expert.md** | Stripe, PayPal, checkout |

---

## HIERARCHY OVERVIEW

```
ORCHESTRATOR (opus)
    |
    +-- CORE AGENTS (6)
    |   +-- analyzer (haiku)
    |   +-- coder (sonnet)
    |   +-- reviewer (sonnet)
    |   +-- documenter (haiku)
    |   +-- system_coordinator (haiku)
    |
    +-- L1 EXPERTS (22)
    |   +-- ai_integration_expert
    |   +-- architect_expert
    |   +-- browser_automation_expert
    |   +-- claude_systems_expert
    |   +-- database_expert
    |   +-- devops_expert
    |   +-- gui-super-expert
    |   +-- integration_expert
    |   +-- languages_expert
    |   +-- mcp_integration_expert
    |   +-- mobile_expert
    |   +-- mql_decompilation_expert
    |   +-- mql_expert
    |   +-- n8n_expert
    |   +-- notification_expert
    |   +-- offensive_security_expert
    |   +-- payment_integration_expert
    |   +-- reverse_engineering_expert
    |   +-- security_unified_expert
    |   +-- social_identity_expert
    |   +-- tester_expert
    |   +-- trading_strategy_expert
    |
    +-- L2 SPECIALISTS (15) - Sub-agents of L1
        +-- ai-model-specialist (parent: ai_integration)
        +-- api-endpoint-builder (parent: integration)
        +-- architect-design-specialist (parent: architect)
        +-- claude-prompt-optimizer (parent: claude_systems)
        +-- db-query-optimizer (parent: database)
        +-- devops-pipeline-specialist (parent: devops)
        +-- gui-layout-specialist (parent: gui-super)
        +-- languages-refactor-specialist (parent: languages)
        +-- mobile-ui-specialist (parent: mobile)
        +-- mql-optimization (parent: mql)
        +-- n8n-workflow-builder (parent: n8n)
        +-- security-auth-specialist (parent: security_unified)
        +-- social-oauth-specialist (parent: social_identity)
        +-- test-unit-specialist (parent: tester)
        +-- trading-risk-calculator (parent: trading_strategy)
```

---

## QUICK ROUTING TABLE

| Task Keyword | Route To |
|--------------|----------|
| GUI, PyQt5, Qt, widget | gui-super-expert |
| layout, sizing, splitter | gui-layout-specialist |
| database, SQL, schema | database_expert |
| query, index, optimize DB | db-query-optimizer |
| security, encryption | security_unified_expert |
| auth, JWT, session | security-auth-specialist |
| offensive, pentest, exploit | offensive_security_expert |
| reverse, binary, decompile | reverse_engineering_expert |
| API, REST, webhook | integration_expert |
| endpoint, route | api-endpoint-builder |
| test, debug, QA | tester_expert |
| unit test, mock, pytest | test-unit-specialist |
| MQL, EA, MetaTrader | mql_expert |
| optimize EA, memory | mql-optimization |
| trading, strategy | trading_strategy_expert |
| risk, position size | trading-risk-calculator |
| mobile, iOS, Android | mobile_expert |
| mobile UI, responsive | mobile-ui-specialist |
| n8n, workflow, automation | n8n_expert |
| workflow builder | n8n-workflow-builder |
| Claude, prompt, token | claude_systems_expert |
| prompt optimize | claude-prompt-optimizer |
| architecture, design | architect_expert |
| DevOps, deploy, CI/CD | devops_expert |
| Python, JS, C#, coding | languages_expert |
| refactor, clean code | languages-refactor-specialist |
| AI, LLM, GPT | ai_integration_expert |
| OAuth, social login | social_identity_expert |
| browser, e2e, playwright | browser_automation_expert |
| MCP, tool discovery | mcp_integration_expert |
| Slack, Discord, notification | notification_expert |
| Stripe, PayPal, payment | payment_integration_expert |
| analyze, explore, search | analyzer |
| implement, fix, code | coder |
| review, quality check | reviewer |
| document, changelog | documenter |

---

## FILE STRUCTURE

```
agents/
  core/
    orchestrator.md
    analyzer.md
    coder.md
    reviewer.md
    documenter.md
    system_coordinator.md
  experts/
    ai_integration_expert.md
    architect_expert.md
    browser_automation_expert.md
    claude_systems_expert.md
    database_expert.md
    devops_expert.md
    gui-super-expert.md
    integration_expert.md
    languages_expert.md
    mcp_integration_expert.md
    mobile_expert.md
    mql_decompilation_expert.md
    mql_expert.md
    n8n_expert.md
    notification_expert.md
    offensive_security_expert.md
    payment_integration_expert.md
    reverse_engineering_expert.md
    security_unified_expert.md
    social_identity_expert.md
    tester_expert.md
    trading_strategy_expert.md
    L2/
      ai-model-specialist.md
      api-endpoint-builder.md
      architect-design-specialist.md
      claude-prompt-optimizer.md
      db-query-optimizer.md
      devops-pipeline-specialist.md
      gui-layout-specialist.md
      languages-refactor-specialist.md
      mobile-ui-specialist.md
      mql-optimization.md
      n8n-workflow-builder.md
      security-auth-specialist.md
      social-oauth-specialist.md
      test-unit-specialist.md
      trading-risk-calculator.md
  docs/
    README.md
    getting-started.md
    quickstart.md
    quick-reference.md
    orchestrator-examples.md
    orchestrator-advanced.md
    SYSTEM_ARCHITECTURE.md
    implementation-details.md
    prompt-library.md
    deploy-checklist.md
  config/
    routing.md
    standards.md
  workflows/
    bugfix.md
    feature.md
    refactoring.md
    OPTIMIZED.md
  templates/
    task.md
    review.md
    integration.md
```

---

## METRICS

| Category | Count |
|----------|-------|
| **Total Agents** | 43 |
| Core Agents (L0) | 6 |
| L1 Experts | 22 |
| L2 Specialists | 15 |
| L1 Recent Additions | 4 |
| Workflows | 4 |
| Templates | 3 |
| Docs | 10+ |

---

## RELATED FILES

- `system/PROTOCOL.md` - Communication protocol (MANDATORY)
- `system/AGENT_REGISTRY.md` - Routing configuration
- `system/COMMUNICATION_HUB.md` - Message format
- `docs/README.md` - System overview
- `docs/getting-started.md` - Quick start guide

---

**Status:** Production Ready
**Version:** 12.0 DEEP AUDIT
**Quality:** 100% organized - 43 agents verified

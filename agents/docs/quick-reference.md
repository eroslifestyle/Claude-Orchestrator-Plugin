---
name: Quick Reference
description: Quick reference guide for common commands
---

# QUICK REFERENCE - SISTEMA AGENTI V2.1

## FILE STRUTTURA

```
~/.claude/agents/
├── orchestrator.md              ← ENTRY POINT - Coordinatore centrale
├── analyzer.md                  ← Analisi rapida codice
├── PROTOCOL.md                  ← Standardizzazione output (OBBLIGATORIO)
├── documenter.md                ← Aggiornamento documentazione
├── coder.md                     ← Implementazione generica
├── reviewer.md                  ← Code review
├── experts/
│   ├── gui-super-expert.md      ← GUI/UX Expert
│   ├── api_expert.md            ← API/Integrazione Expert
│   ├── database_expert.md       ← Database Expert
│   ├── mql5_expert.md           ← MQL5 Expert
│   ├── pyqt5_expert.md          ← PyQt5 Expert
│   ├── python_expert.md         ← Python Expert
│   ├── iam_expert.md            ← IAM/Security Expert (OAuth, MFA, RBAC/ABAC, GDPR)
│   ├── security_expert.md       ← Security Expert
│   ├── architect_expert.md      ← Architecture Expert (System Design, API, Trade-offs)
│   ├── devops_expert.md         ← DevOps/SRE Expert (IaC, CI/CD, K8s, Monitoring)
│   ├── n8n_expert.md            ← N8N Expert (Workflow Automation, Low-Code, DevOps)
│   └── ai_integration_expert.md ← AI Expert (LLM APIs, Prompt Engineering, RAG)
└── AGGIORNAMENTI_V2.1.md        ← Changelog
```

## REGOLE CRITICHE

### 1. PROTOCOLLO OBBLIGATORIO
**TUTTI gli output devono seguire PROTOCOL.md:**

```
## HEADER
Agent: [nome]
Task ID: [UUID]
Status: [SUCCESS|PARTIAL|FAILED|BLOCKED]
Model Used: [haiku|sonnet|opus]
Timestamp: [ISO8601]

## SUMMARY
[1-3 righe]

## DETAILS
[JSON/strutturato]

## FILES MODIFIED
- [path]: [desc]

## ISSUES FOUND
- [issue]: severity [CRITICAL|HIGH|MEDIUM|LOW]

## NEXT ACTIONS
- [azione]

## HANDOFF
To: orchestrator
Context: [info]
```

### 2. INTERFACCIA UNICA
- ✅ Orchestrator ↔ Analyzer
- ✅ Orchestrator ↔ Expert
- ✅ Orchestrator ↔ Coder
- ❌ Analyzer ↔ Coder (VIETATO)
- ❌ Expert ↔ Expert (VIETATO)

### 3. MODELLO AI
- **HAIKU**: Task ripetitivi, fix minori, doc
- **SONNET**: Analisi, coding moderato, review
- **OPUS**: Architettura, decisioni critiche, bug complessi

### 4. NESSUN TASK DIRETTO AI DEVELOPER AGENT
- Tutti i task vanno tramite orchestrator
- orchestrator decide quale expert/coder lanciare
- Output standardizzato in PROTOCOL.md

---

## QUANDO USARE QUALE EXPERT

| Situazione | Expert | File |
|-----------|--------|------|
| Progettazione UI, componenti GUI, design system | gui-super-expert | experts/gui-super-expert.md |
| REST API, WebSocket, resilience patterns, async | api-expert | experts/api_expert.md |
| Schema database, query optimization, migration | database-expert | experts/database_expert.md |
| MQL5 Expert Advisor, parsing CSV | mql5-expert | experts/mql5_expert.md |
| PyQt5 GUI, widget, style sheets | pyqt5-expert | experts/pyqt5_expert.md |
| Python generico, refactoring, best practices | python-expert | experts/python_expert.md |
| Identity & Access Management, OAuth, MFA, RBAC/ABAC, GDPR | iam-expert | experts/iam_expert.md |
| Sicurezza, encryption, auth, permission | security-expert | experts/security_expert.md |
| System design, pattern architetturali, API spec, ADR | architect-expert | experts/architect_expert.md |
| IaC, CI/CD, Kubernetes, Docker, monitoring, SRE | devops-expert | experts/devops_expert.md |
| Automazioni n8n, workflow design, custom nodes, deployment | n8n-expert | experts/n8n_expert.md |
| Integrazione AI/LLM, prompt engineering, RAG, monitoring AI | ai-integration-expert | experts/ai_integration_expert.md |

---

## SELEZIONE MODELLO AI PER TASK

### Task HAIKU (costo minimo)
- Rinominare file/variabili
- Fix typo/import
- Aggiornare traduzioni
- Documentazione semplice
- Task ripetitivi identici

### Task SONNET (costo medio) 
- Analisi codebase con Analyzer
- Implementazione feature standard
- Bug fix moderati (1-2 file)
- Code review
- Integrazione moduli

### Task OPUS (costo alto)
- Decisioni architettura
- Bug complessi (3+ file)
- Refactoring major
- Problemi creativeità/ragionamento

---

## FLOW DI UNA RICHIESTA

```
User Request
    ↓
orchestrator.md analizza
    ↓
Sceglie Expert/Analyzer
    ↓
Lancia con PROTOCOL.md requirement
    ↓
Expert restituisce output PROTOCOL.md
    ↓
orchestrator riceve, verifica format
    ↓
Lancia successivo Expert o Coder se necessario
    ↓
Output finale a user
```

---

## CHECKLIST IMPLEMENTAZIONE TASK

- [ ] Requirement chiaro?
- [ ] Model AI scelto? (haiku/sonnet/opus)
- [ ] Expert/Agent selezionato?
- [ ] Prompt file letto?
- [ ] PROTOCOL.md integrato nel prompt?
- [ ] Task lanciato via orchestrator?
- [ ] Output conforme PROTOCOL.md?
- [ ] Handoff verso orchestrator include?
- [ ] Nessun direct agent-to-agent contact?

---

## COMANDI FRECCIA

### Per Analyzer
```
RUOLO: ANALYZER AGENT
Modulo: [TELEGRAM|CTRADER|METATRADER|APP_CORE|GUI|LICENSE]
Path: [percorso]
Focus: [struttura|bug|dipendenze|security|performance|tutto]
Profondità: [rapida|media|profonda]
Leggi: ~/.claude/agents/analyzer.md
Output: PROTOCOL.md format
```

### Per GUI Expert
```
RUOLO: GUI SUPER EXPERT AGENT
Task: [descrizione componente/redesign/optimization/fix]
Platform: [PyQt5|React|Vue|etc]
Context: [descrizione]
Requirements: [lista]
Accessibility: [WCAG AA|AAA]
Leggi: ~/.claude/agents/experts/gui-super-expert.md
Output: PROTOCOL.md format
```

### Per API Expert
```
RUOLO: API EXPERT AGENT
Task: [descrizione API/integrazione]
Protocol: [REST|GraphQL|gRPC|WebSocket]
Requirements: [lista]
SLA: [latency ms, uptime %, throughput]
Security: [public|internal|sensitive|critical]
Leggi: ~/.claude/agents/experts/api_expert.md
Output: PROTOCOL.md format
```

---

## SEVERITY LEVELS

- **CRITICAL**: Blocca completamente funzionalità
- **HIGH**: Degrada significantly performance/UX
- **MEDIUM**: Impatto moderato, rimandabile
- **LOW**: Nice-to-have, cosmetic

---

## STATUS ENUM

- **SUCCESS**: Task completato, output pronto
- **PARTIAL**: Completato con limitazioni/warning
- **FAILED**: Fallito, output non usabile
- **BLOCKED**: Bloccato da dipendenza esterna

---

## LINK DOCUMENTI

- **PROTOCOL.md**: `~/.claude/agents/PROTOCOL.md`
- **Orchestrator**: `~/.claude/agents/orchestrator.md`
- **Analyzer**: `~/.claude/agents/analyzer.md`
- **GUI Expert**: `~/.claude/agents/experts/gui-super-expert.md`
- **API Expert**: `~/.claude/agents/experts/api_expert.md`

---

Versione: 2.1
Data: 25 Gennaio 2026
Status: Production Ready

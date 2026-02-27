---
name: Getting Started
description: Getting started guide for new users
---

# START HERE - SISTEMA AGENTI V2.1

**Benvenuto nel Sistema Agenti Claude V2.1**

Sei qui perché devi iniziare a lavorare con il sistema multi-agent.
Segui questi step nell'ordine.

---

## STEP 1: LEGGERE QUESTI FILE (5 MINUTI)

1. **Questo file** (lo stai leggendo adesso)
2. **README.md** - Overview completo del sistema (root)
3. **docs/quick-reference.md** - Lookup rapido per comandi comuni

---

## STEP 2: LEGGERE IL FILE CRITICO (10 MINUTI)

**OBBLIGATORIO - Devi leggere questo:**

📌 **PROTOCOL.md** ← Questo definisce come scrivere output
- Come strutturare HEADER, SUMMARY, DETAILS, HANDOFF
- Status enum (SUCCESS, PARTIAL, FAILED, BLOCKED)
- Severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- Regole critiche

---

## STEP 3: IDENTIFICARE IL TUO RUOLO

Quale agente sei?

### Se sei ORCHESTRATOR
→ Leggi: **core/orchestrator.md**
- Come coordinare task
- Quando lanciare quale expert
- Model AI selection

### Se sei ANALYZER
→ Leggi: **core/analyzer.md**
- Come analizzare rapidamente
- Come scrivere report PROTOCOL.md
- Come handoff a orchestrator

### Se sei GUI/UX SPECIALIST
→ Leggi: **experts/gui-super-expert.md**
- Design Systems
- Accessibility
- Performance
- PyQt5 specialization

### Se sei API SPECIALIST
→ Leggi: **experts/api_expert.md**
- REST, GraphQL, WebSocket
- Resilience patterns
- Security
- Python asyncio focus

### Se sei IDENTITY & ACCESS MANAGEMENT SPECIALIST
→ Leggi: **experts/iam_expert.md**
- OAuth 2.0, OpenID Connect
- Multi-Factor Authentication (MFA)
- RBAC/ABAC authorization
- Privacy & GDPR compliance
- Security auditing

### Se sei ARCHITECT SPECIALIST
→ Leggi: **experts/architect_expert.md**
- System design e pattern architetturali
- API design (REST, gRPC, GraphQL)
- Trade-off analysis e ADR
- Performance e scaling
- Diagrammi C4

### Se sei DEVOPS/SRE SPECIALIST
→ Leggi: **experts/devops_expert.md**
- Infrastructure as Code (Terraform)
- CI/CD pipelines
- Kubernetes e containerization
- Monitoring e observability
- SLO/SLI e incident response

### Se sei N8N/AUTOMATION SPECIALIST
→ Leggi: **experts/n8n_expert.md**
- Workflow automation con n8n
- Custom node development (TypeScript)
- Deployment e DevOps per n8n
- Monitoring e observability
- Enterprise integration patterns

### Se sei AI INTEGRATION SPECIALIST
→ Leggi: **experts/ai_integration_expert.md**
- Integrazione LLM APIs (OpenAI, Anthropic, Claude)
- Prompt engineering e template management
- RAG (Retrieval Augmented Generation)
- Cost optimization e monitoring AI
- Modelli locali (Ollama, vLLM)

### Se sei altro
→ Consulta: **docs/quick-reference.md** (tabella expert mapping)

---

## STEP 4: CAPIRE IL FLUSSO

Il sistema funziona così:

```
User richiesta
    ↓
core/orchestrator.md (coordinatore)
    ├─ Analizza richiesta
    ├─ Sceglie expert/analyzer
    └─ Invia via prompt
        ↓
    Expert/Analyzer (core/ o experts/)
    ├─ Legge il proprio file
    ├─ Legge PROTOCOL.md
    └─ Produce output standardizzato
        ↓
    Ritorna a core/orchestrator.md
    (SEMPRE handoff verso orchestrator)
        ↓
    core/orchestrator.md
    ├─ Riceve output
    ├─ Valida format PROTOCOL.md
    └─ Decidi prossimo step
        ↓
    Output finale a user
```

**REGOLA CRITICA:** Non c'è comunicazione diretta tra agenti
(es: Analyzer → Coder). Tutto passa per orchestrator.

---

## STEP 5: CHECKLIST PRIMA DI LAVORARE

- [ ] Ho letto PROTOCOL.md?
- [ ] Conosco il mio ruolo (analyzer, expert, etc)?
- [ ] Ho letto il mio file (core/orchestrator.md, core/analyzer.md, experts/*, etc)?
- [ ] Capisco il flow orchestrator → agent → output?
- [ ] So che output deve essere PROTOCOL.md format?
- [ ] So che handoff è sempre "To: orchestrator"?
- [ ] Capisco che NO direct agent-to-agent communication?

Se tutte le risposte sono SI, sei pronto!

---

## STEP 6: GUIDA RAPIDA PER TASK TIPICI

### Task: Analyzer "Analizza il modulo TELEGRAM"

1. Leggi: core/analyzer.md
2. Leggi: PROTOCOL.md (come scrivere output)
3. Produce: OUTPUT strutturato PROTOCOL.md format
4. Handoff: "To: orchestrator"
5. Done!

### Task: GUI Expert "Crea button component PyQt5"

1. Leggi: experts/gui-super-expert.md
2. Leggi: PROTOCOL.md (come scrivere output)
3. Analizza: requirements, accessibility level, target latency
4. Produce: OUTPUT strutturato PROTOCOL.md format
5. Include: design tokens, responsive breakpoints, a11y checklist
6. Handoff: "To: orchestrator"
7. Done!

### Task: API Expert "Design REST API per cTrader orders"

1. Leggi: experts/api_expert.md
2. Leggi: PROTOCOL.md (come scrivere output)
3. Analizza: endpoint, resilience patterns, security, performance targets
4. Produce: OUTPUT strutturato PROTOCOL.md format
5. Include: circuit breaker config, retry policy, monitoring
6. Handoff: "To: orchestrator"
7. Done!

---

## DOCUMENTAZIONE COMPLETA

Per riferimento completo, consulta:

| Documento | Scopo |
|-----------|-------|
| PROTOCOL.md | Come scrivere output (OBBLIGATORIO) |
| core/orchestrator.md | Coordinamento flow |
| core/analyzer.md | Analisi codice |
| experts/gui-super-expert.md | GUI/UX tasks |
| experts/api_expert.md | API/integrazione tasks |
| experts/iam_expert.md | Identity & Access Management tasks |
| experts/architect_expert.md | Architecture design tasks |
| experts/devops_expert.md | DevOps/SRE tasks |
| experts/n8n_expert.md | N8N automation tasks |
| experts/ai_integration_expert.md | AI integration tasks |
| docs/quick-reference.md | Lookup rapido |
| docs/implementation-details.md | Dettagli tecnici |
| docs/deploy-checklist.md | Deployment procedure |
| README.md | Overview completo |

---

## REGOLE CRITICHE (ASSOLUTAMENTE OBBLIGATORIO)

1. **PROTOCOL.md format**
   - Tutti gli output DEVONO seguire
   - No eccezioni o semplificazioni
   - Output non conforme = RIFIUTATO

2. **Handoff a orchestrator SEMPRE**
   - Nessuno comunica direttamente con altri agenti
   - orchestrator è il coordinatore unico
   - "To: orchestrator" SEMPRE

3. **No hard coding o deviazioni**
   - Segui ESATTAMENTE il tuo file (core/*, experts/*)
   - Leggi PROTOCOL.md
   - Non improvvisare format

---

## QUICK HELP

### Domanda: "Come scrivo l'output?"
→ Leggi PROTOCOL.md, sezione "FORMATO STANDARDIZZATO"

### Domanda: "A chi restituisco l'output?"
→ SEMPRE a orchestrator.md (vedi "HANDOFF" in PROTOCOL.md)

### Domanda: "Quale expert devo lanciare?"
→ Consulta docs/quick-reference.md, tabella "QUANDO USARE QUALE EXPERT"

### Domanda: "Quale model AI devo usare?"
→ Consulta docs/quick-reference.md, sezione "SELEZIONE MODELLO AI"

### Domanda: "Posso comunicare direttamente con un altro agent?"
→ NO! VIETATO. Tutto passa per core/orchestrator.md

---

## SUPPORT

Se hai domande:

1. Leggi README.md (overview completo)
2. Leggi docs/quick-reference.md (lookup rapido)
3. Leggi il tuo file specifico (core/analyzer.md, experts/gui-super-expert.md, etc)
4. Leggi PROTOCOL.md (for output format)
5. Consulta docs/implementation-details.md (technical details)

---

## PROSSIMO PASSO

**Leggi ora:** README.md

Poi scegli il tuo path:
- Se sei ORCHESTRATOR → core/orchestrator.md
- Se sei ANALYZER → core/analyzer.md
- Se sei GUI EXPERT → experts/gui-super-expert.md
- Se sei API EXPERT → experts/api_expert.md
- Se sei IAM EXPERT → experts/iam_expert.md
- Se sei ARCHITECT EXPERT → experts/architect_expert.md
- Se sei DEVOPS/SRE EXPERT → experts/devops_expert.md
- Se sei N8N/AUTOMATION EXPERT → experts/n8n_expert.md
- Se sei AI INTEGRATION EXPERT → experts/ai_integration_expert.md

---

**Status:** Production Ready V2.1
**Data:** 25 Gennaio 2026
**Quality:** 100% compliant with PROTOCOL.md

Buon lavoro!

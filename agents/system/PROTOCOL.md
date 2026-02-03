---
name: Agent Response Protocol
description: Standard communication protocol for all agents
---

# 📋 AGENT RESPONSE PROTOCOL V1.0

> **Versione:** 6.0
> **Data:** 25 Gennaio 2026
> **Status:** OBBLIGATORIO per TUTTI gli agent
> **Scopo:** Standardizzare comunicazione tra agent e orchestrator

---

## 🏆 STANDARD QUALITÀ UNIVERSALI

**TUTTI gli agent DEVONO produrre output che sia:**

```
┌─────────────────────────────────────────────────────────────────┐
│  PERFORMANTE  │ Ottimizzato, zero sprechi                      │
│  SICURO       │ OWASP compliant, no vulnerabilità              │
│  COMMENTATO   │ Docstring, commenti logica                     │
│  BEST PRACTICE│ Pattern moderni, clean code                    │
│  MAX 1000 RIG │ Split file per funzionalità                    │
└─────────────────────────────────────────────────────────────────┘

        🚫 MAI COMPROMESSI SULLA QUALITÀ 🚫
        ✅ SEMPRE IL MIGLIOR OUTPUT POSSIBILE ✅
```

---

## 💰 OTTIMIZZAZIONE TOKEN

| Regola | Azione |
|--------|--------|
| Model default | HAIKU (costo minimo) |
| Parallelismo | ILLIMITATO (massima velocità) |
| Output | Conciso ma completo |

---

## REGOLA FONDAMENTALE

Tutti gli agent (Analyzer, Expert, Coder, Reviewer, etc) DEVONO restituire output in QUESTO FORMATO ESATTO.
Non ci sono eccezioni, variazioni o abbreviazioni.

---

## FORMATO STANDARDIZZATO

Ogni agent DEVE strutturare il suo response ESATTAMENTE così:

### HEADER (Obbligatorio)
```
Agent: [NOME_AGENT]
Task ID: [UUID]
Status: [SUCCESS|PARTIAL|FAILED|BLOCKED]
Model Used: [haiku|sonnet|opus]
Timestamp: [ISO 8601]
```

### SUMMARY (Obbligatorio)
1-3 righe massimo. Riassumere RISULTATO, non il processo.

### DETAILS (Obbligatorio)
Formato JSON strutturato quando possibile.
Include metriche, misure quantitative, traccia completamento %.

### FILES MODIFIED (Obbligatorio)
- [path]: [descrizione modifica in 1 riga]
Se nessun file: "(nessun file modificato)"

### ISSUES FOUND (Se applicabile)
- [nome issue]: severity [CRITICAL|HIGH|MEDIUM|LOW]
Se nessuno: "(nessun issue)"

### NEXT ACTIONS (Se applicabile)
Suggerimenti per orchestrator, non istruzioni.

### HANDOFF (Obbligatorio)
To: orchestrator
Context: Info essenziale per orchestrator

---

## SEVERITY LEVELS

- **CRITICAL**: Blocca completamente funzionalità core
- **HIGH**: Degrada significantly esperienza utente o performance
- **MEDIUM**: Impatto moderato, può essere rimandato
- **LOW**: Nice-to-have fix, cosmetic

---

## STATUS ENUM

- **SUCCESS**: Task completato con successo, output pronto
- **PARTIAL**: Task completato ma con limitazioni/warning
- **FAILED**: Task fallito, output non utilizzabile
- **BLOCKED**: Task bloccato da dipendenza esterna

---

## REGOLE CRITICHE

1. NESSUN AGENT COMUNICA CON ALTRI AGENTI
   - Agent A → Orchestrator (solo)
   - NON Agent A → Agent B

2. OUTPUT DEVE ESSERE PARSEABLE
   - JSON valido (no multi-line unstructured)
   - Struttura rigida, no variazioni

3. TIMESTAMPS ISO 8601
   - Formato: 2026-01-25T14:30:45Z

4. HANDOFF DEVE INCLUDERE CONTEXT
   - Orchestrator non deve indovinare cosa fare dopo

---

Versione 6.0 - 25 Gennaio 2026

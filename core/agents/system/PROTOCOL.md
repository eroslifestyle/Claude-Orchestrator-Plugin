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

## SEARCH PARALLELISM RULE

When performing searches with Glob or Grep, ALWAYS parallelize independent queries in ONE message:

```
CORRECT (3 independent searches):
[Glob("src/**/*.ts") + Glob("lib/**/*.py") + Grep("TODO", path="src/")] → ONE message

WRONG (sequential searches):
Message 1: Glob("src/**/*.ts") → wait for result
Message 2: Glob("lib/**/*.py") → wait for result
Message 3: Grep("TODO", path="src/") → wait for result
```

Speed tips for all agents:
- Use specific paths: `Grep(pattern, path="src/auth/")` not `Grep(pattern, path="/")`
- Use type filters: `Grep(pattern, type="py")` to skip non-Python files
- Use head_limit: `Grep(pattern, head_limit=20)` to cap results
- Glob first, Grep second: find files, then search within them

---

## READ/WRITE PARALLELISM RULE

When reading or writing multiple independent files, ALWAYS parallelize in ONE message:

```
CORRECT (3 independent reads):
[Read(file1) + Read(file2) + Read(file3)] → ONE message, 3 results back

WRONG (sequential reads):
Message 1: Read(file1) → wait for result
Message 2: Read(file2) → wait for result
Message 3: Read(file3) → wait for result
```

```
CORRECT (3 independent writes):
[Edit(file1) + Edit(file2) + Write(file3)] → ONE message

WRONG (sequential writes):
Message 1: Edit(file1) → wait
Message 2: Edit(file2) → wait
Message 3: Write(file3) → wait
```

When to parallelize:
- Reading multiple files to understand context → ALL reads in ONE message
- Editing multiple independent files → ALL edits in ONE message
- Mixed operations on different files → combine in ONE message

When NOT to parallelize:
- Read file1 THEN edit file1 (edit depends on read result)
- Edit file1 THEN read file1 to verify (verify depends on edit)

---

Versione 6.0 - 25 Gennaio 2026

---
name: Orchestrator Advanced
description: Advanced orchestration features including escalation, error handling, and optimization
version: 6.2
---

# ORCHESTRATOR - FEATURES AVANZATE V6.2

> **Versione:** 6.0
> **Data:** 2 Febbraio 2026
> **Riferimento:** core/orchestrator.md

---

## MODEL ESCALATION AUTOMATICA

### Principio

Quando un agent con modello inferiore FALLISCE, escala automaticamente al modello superiore.

### Livelli Escalation

```
haiku (fallisce) -> sonnet (fallisce) -> opus -> utente
```

| Livello | Default Per | Se Fallisce | Trigger |
|---------|-------------|-------------|---------|
| haiku | Task meccanici | -> sonnet | 3 tentativi, errore critico |
| sonnet | Problem solving | -> opus | Errore non risolvibile |
| opus | Architettura | -> utente | Intervento manuale |

### Trigger Escalation

- Agent non completa task entro 3 tentativi
- Errore critico non risolvibile al livello corrente
- Complessita sottovalutata
- Output non soddisfacente/incompleto
- Timeout ripetuto

### Comunicazione Escalation

```
"⚠️ Task T[N] escalato da [model1] a [model2]
 Motivo: [descrizione causa fallimento]
 Rilancio con model [model2]..."
```

### Esempio Pratico

```markdown
TENTATIVO 1:
| T1 | Crea sidebar | experts/gui-super-expert.md | haiku | ❌ FAILED |

⚠️ ESCALATION: haiku -> sonnet
Motivo: Layout conflict non risolto

TENTATIVO 2:
| T1 | Crea sidebar | experts/gui-super-expert.md | sonnet | ✅ DONE |
```

### Metriche Escalation (Riepilogo Finale)

```markdown
📊 METRICHE ESCALATION:
• Totale task: 4
• Task escalati: 2 (50%)
• Escalation haiku->sonnet: 1
• Escalation sonnet->opus: 1
• Successo dopo escalation: 2/2 (100%)
```

---

## ERROR HANDLING

### Gestione Errori e Recovery

| Errore | Causa | Recovery | Prevenzione |
|--------|-------|----------|-------------|
| Expert file non trovato | Path errato | Fallback a core/coder.md | Validare path |
| Agent timeout (>180s) | Task complesso | Split + retry | Stimare complessita |
| Output vuoto | Prompt ambiguo | Riformula + retry | Prompt specifici |
| Conflitto dipendenze | T2 dipende da T1 fallito | Abort chain | Verificare dipendenze |
| Rate limit API | Troppi agent paralleli | Ridurre a 10 | Max 20 paralleli |
| Context overflow | Troppo contenuto | File path invece di contenuto | Riferimenti |

### Flow di Recovery

```
1. DETECT: Errore rilevato
      |
2. LOG: Registra errore + context
      |
3. CLASSIFY: Recoverable o Fatal?
      |
   Recoverable -> RETRY (max 3)
   Fatal -> ABORT + REPORT
      |
4. RETRY:
   - Tentativo 1: Stesso model, prompt migliorato
   - Tentativo 2: Model escalation
   - Tentativo 3: Split task
      |
5. REPORT: Comunica all'utente
```

### Codici Errore Standard

| Codice | Tipo | Recoverable |
|--------|------|-------------|
| E001 | TIMEOUT | Si |
| E002 | PARSE | Si |
| E003 | EMPTY | Si |
| E004 | DEPENDENCY | No |
| E005 | FILE_NOT_FOUND | Si (fallback) |
| E006 | RATE_LIMIT | Si (attendi) |
| E007 | CONTEXT_OVERFLOW | Si (split) |
| E008 | AUTH | No |

---

## CONTEXT OPTIMIZATION

### Strategie Token Reduction

1. **FILE REFERENCE vs INLINE CONTENT**
   - ❌ "Ecco il contenuto del file: [500 righe]..."
   - ✅ "Modifica il file C:\path\file.py, linea 45"

2. **TASK ID REFERENCE**
   - ❌ Ripetere output di task precedenti
   - ✅ "Come output di T1, procedi con..."

3. **PRUNE TABELLE** (sessioni >20 task)
   - Mantieni ultime 5 righe attive
   - Archivia completati

4. **SUMMARIZE OUTPUT**
   - ❌ "File creato con 500 righe di codice [dump]"
   - ✅ "File creato: utils.py (500 righe, 12 funzioni)"

5. **PROMPT COMPRESSION**
   - Keyword + context minimo

### Soglie Context

| Context Size | Azione |
|--------------|--------|
| < 20k token | Normale |
| 20-40k | Inizia pruning |
| 40-60k | Summarize aggressivo |
| > 60k | Split sessione |

### Template Prompt Compatto

```markdown
Task: [VERBO] [OGGETTO] in [FILE]
Expert: [expert_file.md]
Context: [1-2 righe max]
Output: [formato atteso]
```

---

## RALPH LOOP INTEGRATION

> **Riferimento completo:** Plugin Ralph Loop documentation

### Quando Usare

| Scenario | Usa Ralph Loop? |
|----------|-----------------|
| Task con criteri di successo chiari | ✅ SI |
| Feature greenfield con test automatici | ✅ SI |
| TDD (Test-Driven Development) | ✅ SI |
| Bug fixing con reproduction test | ✅ SI |
| Task che richiedono giudizio umano | ❌ NO |
| One-shot operations | ❌ NO |

### Comandi

```bash
/ralph-loop "<prompt>" --max-iterations <N> --completion-promise "<TESTO>"
/cancel-ralph
```

### Pattern: Feature Development

```bash
/ralph-loop "Implementa feature X seguendo TDD:
STEP 1: Analyzer su moduli
STEP 2: Test first (red)
STEP 3: Coder implementa
STEP 4: Verifica test
STEP 5: Reviewer check
Output <promise>FEATURE_COMPLETE</promise>"
--max-iterations 30 --completion-promise "FEATURE_COMPLETE"
```

### Best Practices

- Criteri completamento CHIARI (non "fai funzionare tutto")
- MAX iterations SEMPRE (safety net)
- Verifica automatica (test suite, linter)
- Prompt strutturato con step numerati
- Escape hatch nel prompt (dopo N iterazioni senza progresso)

---

## METRICHE E MONITORAGGIO

### Token Tracking V6.2

**Distribuzione Attesa:**
- Haiku: 15-20% (task meccanici)
- Sonnet: 70-80% (problem solving)
- Opus: 5-10% (architettura/creativita)

### Report Fine Sessione

```markdown
📊 METRICHE FINALE:
├─ Totale Agent: N
├─ Completati: X (Y%)
├─ Falliti: Z (W%)
├─ Tempo Totale: [HH:MM:SS]
└─ Token: [Tot] (Haiku: Xk, Sonnet: Yk, Opus: Zk)

🎯 DISTRIBUZIONE MODEL:
├─ Haiku: A agent (B%)
├─ Sonnet: C agent (D%)
├─ Opus: E agent (F%)
└─ Target: 20% haiku, 70% sonnet, 10% opus -> [STATO]
```

---

## RIEPILOGO FINALE TEMPLATE

### Template Completo

```markdown
═══════════════════════════════════════════════════════════════════
✅ SESSIONE COMPLETATA - RIEPILOGO FINALE
═══════════════════════════════════════════════════════════════════

📋 TABELLA FINALE
| # | Task | Agent Expert File | Model | Agent ID | Spec | Dipende | Status | Risultato |
|---|------|-------------------|-------|----------|------|---------|--------|-----------|
|T1 | [...] | experts/... | sonnet | A1a2.. | ... | - | ✅ | [OUTPUT] |

📊 METRICHE: [vedi sopra]

📁 FILE INTERESSATI:
├─ Creati: [N file + path]
├─ Modificati: [M file + path]
└─ Eliminati: [Z file + path]

✨ TASK COMPLETATI: [lista]
⚠️ TASK FALLITI: [lista se presenti]
🔑 DECISIONI ARCHITETTURALI: [lista]

📝 DOC AGGIORNATI:
• [x] CONTEXT_HISTORY.md
• [x] TODOLIST.md
• [x] CLAUDE.md (se architettura)

🚀 PROSSIMI STEP: [lista 3-5 step]

═══════════════════════════════════════════════════════════════════
```

---

## CHECKLIST PRE-CHIUSURA

```markdown
✅ PRE-CHIUSURA CHECKLIST:

[ ] REGOLA #5: Documenter lanciato come ULTIMO step?
[ ] Tabella finale mostra TUTTI i task?
[ ] Metriche calcolate (agent, tempo, token)?
[ ] Parallelismo documentato?
[ ] File interessati con path assoluti?
[ ] CONTEXT_HISTORY.md aggiornato?
[ ] TODOLIST.md task chiusi?
[ ] Task falliti gestiti con root cause?
[ ] Prossimi step comunicati (3-5)?

⛔ Se ANCHE UN SOLO punto e ☐, NON chiudere!
```

---

**Versione:** 6.0 - 2 Febbraio 2026

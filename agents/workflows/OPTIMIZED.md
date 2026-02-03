---
name: Optimized Workflow
description: Optimized workflow patterns for fast (<1h), standard (1-8h), and full (>1 day) tasks with parallelization
---

# ⚡ WORKFLOW OTTIMIZZATO

---

## PRINCIPI

```
1. CONTEXT MINIMO   → Solo essenziale
2. PARALLELISMO MAX → Task indipendenti insieme
3. FAIL FAST        → Errori subito
4. REVIEW CONTINUA  → Non alla fine
```

---

## DECISION MATRIX

```
TASK → Tempo?
         │
    ┌────┴────┬─────────────┐
   <1h      1-8h          >1g
    │         │             │
 🟢 FAST  🟡 STANDARD   🔴 FULL
```

---

## 🟢 FAST (<1h)

### Quando
- Bug fix isolato
- Modifiche <50 righe
- Singolo file

### Flusso
```
[Task] → [Coder] → [Quick Review] → [Done]
          20min        10min
```

---

## 🟡 STANDARD (1-8h)

### Quando
- Feature semplice
- 2-5 file
- Test necessari

### Flusso
```
[Plan 15min]
     │
     ├── [Coder A] Backend ──┐
     │                       ├── [Integration] → [Review] → [Done]
     └── [Coder B] UI ───────┘
```

**Tempo: 4-8h** (vs 8-16h sequenziale)

---

## 🔴 FULL (>1 giorno)

### Quando
- Feature complessa
- Multi-sprint
- Production release

### Flusso
```
[Deep Plan 2-4h]
        │
[Sprint 1: Track A + B] → [Review]
        │
[Sprint 2: Track C + D] → [Review]
        │
[Integration] → [Multi-Review] → [Release]
```

---

## OTTIMIZZAZIONI

### Context Minimo
```
✅ Task ID + stato
✅ Dipendenze attive
✅ File paths

❌ Codice sorgente
❌ Task chiusi
❌ Storico >3 cicli
```

### Review Continua
```
VECCHIO: Code → Code → Code → MEGA REVIEW
NUOVO:   Code → Review → Code → Review → Quick Check
```

### Parallelismo
```
VECCHIO: API → UI (8h)
NUOVO:   API ─┬─► Integrate (5h)
         UI ──┘
```

---

## METRICHE

| Metrica | Target |
|---------|--------|
| Cicli Review | ≤2 |
| Parallelismo | ≥60% |
| Context | ≤2000 tok |
| Rework | ≤10% |

---

## CHECKLIST

### Prima
```
□ Task chiaro?
□ Dipendenze mappate?
□ Criteri definiti?
```

### Durante
```
□ Parallelismo sfruttato?
□ Review ogni 2h?
□ Context pulito?
```

### Fine
```
□ Criteri OK?
□ Test passano?
□ Review OK?
```

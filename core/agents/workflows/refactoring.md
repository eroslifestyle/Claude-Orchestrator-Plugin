---
name: Refactoring Workflow
description: Workflow for code refactoring with assessment, safety net testing, incremental steps, and validation
---

# 🔄 REFACTORING WORKFLOW

## Livello: 🔴 PRODUCTION

---

## PRINCIPI

```
1. Comportamento INVARIATO
2. INCREMENTALE
3. TEST DRIVEN
```

---

## FLUSSO

```
[Assessment] → [Safety Net] → [Refactor Steps] → [Validate]
    1h            1h             per step           1h
```

---

## FASE 1: Assessment

```
## Analisi

FILE: [path]
PROBLEMA: [code smell]
TARGET: [pattern]

METRICHE ATTUALI:
- Complessità: X
- Coverage: Y%
- Duplicazione: Z%
```

---

## FASE 2: Safety Net

```
## Test Coverage

PRIMA:
- [ ] Coverage ≥85%
- [ ] Edge cases coperti
- [ ] Baseline salvata
```

---

## FASE 3: Refactor

Per ogni step:
```
## Step N: [Nome]

TECNICA: Extract Method / Class / etc.

CHECKLIST:
- [ ] Refactor applicato
- [ ] Test passano
- [ ] Review OK
- [ ] Commit (rollback point)
```

---

## FASE 4: Validate

```
## Final Check

- [ ] Comportamento invariato
- [ ] Test passano
- [ ] Coverage ≥ baseline
- [ ] Performance OK
```

---

## TECNICHE

### Extract Method
```python
# PRIMA: funzione lunga
# DOPO: funzioni piccole
```

### Extract Class
```python
# PRIMA: God class
# DOPO: Single Responsibility
```

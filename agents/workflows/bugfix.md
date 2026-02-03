---
name: Bugfix Workflow
description: Workflow for bug fixing process with analysis, coding, review, and commit stages
---

# 🐛 BUGFIX WORKFLOW

## Livello: 🟢 FAST

---

## FLUSSO

```
[Analisi] → [Coder] → [Review] → [Done]
   5min      20min      10min
```

---

## STEP

### 1. Analisi
```
BUG: [descrizione]
FILE: [path]
SEVERITY: Critical/High/Medium/Low
```

### 2. Coder
```
@Coder fixa:
- Bug: [descrizione]
- File: [path]
- Problema: [tecnico]
```

### 3. Review
```
@Reviewer check:
- [ ] Bug risolto?
- [ ] Regression?
- [ ] Security OK?
- [ ] Test OK?
```

---

## COMMIT

```
fix: [descrizione breve]

Problema: [cosa non funzionava]
Soluzione: [come risolto]
```

---

## TEMPO: 30-45 min

---
name: Prompt Library
description: Library of useful prompts and templates
---

# 📚 PROMPT LIBRARY

> Copia, sostituisci [placeholder], usa

---

## 🎯 COORDINATOR

### Analisi Requisiti
```
Analizza requisiti e crea piano:

REQUISITI:
[incolla]

OUTPUT:
1. Task atomici (max 4h)
2. Dipendenze
3. Tracks paralleli
4. Ordine esecuzione
```

### Task Breakdown
```
Scomponi in task paralleli:

FEATURE: [nome]
DESCRIZIONE: [1-2 righe]

OUTPUT:
| Task | Descrizione | Dipende Da | Parallelo | Stima |
```

---

## 🛠️ CODER

### Implementa Feature
```
Implementa:

TASK: [nome]
FILE: [path]

SPECIFICHE:
- [spec 1]
- [spec 2]

CRITERI:
- [ ] [criterio]
- [ ] Test ≥85%

OUTPUT: Codice + test
```

### Bug Fix
```
Fixa:

BUG: [descrizione]
FILE: [path:linea]
ATTUALE: [cosa fa]
ATTESO: [cosa dovrebbe fare]

OUTPUT:
1. Root cause
2. Fix
3. Test regression
```

### Refactoring
```
Refactora:

FILE: [path]
PROBLEMA: [issue]
TARGET: [pattern]

VINCOLI:
- Comportamento invariato
- Test passano

OUTPUT: Codice + spiegazione
```

### API Endpoint
```
Crea endpoint:

ENDPOINT: [METHOD] /api/[path]
REQUEST: { field: type }
RESPONSE: { result: type }
ERRORS: 400, 401, 404

REQUIREMENTS:
- Input validation
- Auth: [yes/no]

OUTPUT: Codice + test
```

---

## 🔍 CODE-REVIEWER

### Review Standard
```
Revisiona:

FILE: [path]

FOCUS:
- [ ] Security
- [ ] Performance
- [ ] Clean Code
- [ ] Test coverage

OUTPUT:
## Summary
Issues: X (critical: N, high: N)
Decision: APPROVED / CHANGES

## Issues
### 🔴 CRITICAL
### 🟠 HIGH
### 🟡 MEDIUM
```

### Security Review
```
Audit sicurezza:

FILE: [path]

CHECKLIST:
- [ ] Input validation
- [ ] SQL injection
- [ ] XSS
- [ ] Auth
- [ ] Secrets

OUTPUT: Vulnerabilità + fix
```

### Performance Review
```
Analisi performance:

FILE: [path]

TARGET:
- Response: <[X]ms
- Memory: <[Y]MB

CHECKLIST:
- [ ] N+1 queries
- [ ] Caching
- [ ] Memory leaks

OUTPUT: Bottleneck + ottimizzazioni
```

---

## 🎨 UI/UX

### Componente
```
Implementa componente:

COMPONENT: [nome]
DESIGN: [Neo-Brutalism/Material/Custom]

SPECS:
- Props: [lista]
- States: normal, hover, active, disabled
- Responsive: mobile, tablet, desktop

ACCESSIBILITY:
- [ ] Keyboard nav
- [ ] ARIA labels
- [ ] Contrast ≥4.5:1

OUTPUT: Codice + test
```

### UI Review
```
Revisiona UI:

PAGE: [nome]

CHECKLIST:
- [ ] Design system
- [ ] Spacing (8px grid)
- [ ] Responsive
- [ ] Accessibility

OUTPUT: Issues + fix
```

---

## 🔄 WORKFLOW

### Fast Track (<1h)
```
FAST TRACK

Task: [descrizione]
File: [path]
Tipo: Bug Fix / Change

OUTPUT:
1. Fix
2. Test
3. Conferma OK
```

### Standard Track (1-8h)
```
STANDARD TRACK - [Feature]

Requisito: [1-2 righe]

Step 1: Scomponi in 3 task
Step 2: Implementa con test
Step 3: Integra e verifica

Checklist:
- [ ] Funziona
- [ ] Test OK
- [ ] Security OK
```

### Full Track (>1g)
```
FULL TRACK - [Progetto]

Phase 1: Planning
- Architecture
- Task breakdown

Phase 2: Development
- Tracks paralleli
- Review incrementale

Phase 3: Integration
- Merge + multi-review

Phase 4: Release
```

---

## 🚨 EMERGENCY

### Hotfix
```
🚨 HOTFIX

BUG: [descrizione]
IMPATTO: [severity]

AZIONE:
1. Root cause (10 min)
2. Fix minimale
3. Test critico
4. Deploy

Post-fix: Ticket per fix completo
```

### Rollback
```
🔙 ROLLBACK

DA: [version]
A: [version]
MOTIVO: [descrizione]

CHECKLIST:
- [ ] Backup
- [ ] Rollback
- [ ] Verifica
- [ ] Comunica
```

---
name: Feature Workflow
description: Workflow for feature development including planning, parallel development, integration, and review phases
---

# ✨ FEATURE WORKFLOW

## Livello: 🟡 STANDARD

---

## FLUSSO

```
[Plan] → [Dev Parallelo] → [Integration] → [Review] → [Done]
 15min      2-4h              1h            1h
```

---

## FASE 1: Planning

```
## Task Breakdown

### Track A: Backend
| Task | Descrizione | Dipende |
|------|-------------|---------|
| A1 | API | - |
| A2 | Logic | A1 |

### Track B: Frontend
| Task | Descrizione | Dipende |
|------|-------------|---------|
| B1 | Component | - |
| B2 | Integration | A1, B1 |
```

---

## FASE 2: Development

```
PARALLELO:
├── Track A → @Coder1
└── Track B → @Coder2

Per task:
Coder → Test → Mini-review → Next
```

---

## FASE 3: Integration

```
## Checklist
- [ ] Merge tracks
- [ ] Test passano
- [ ] UI review (se serve)
- [ ] Final approval
```

---

## COMMIT

```
feat: [descrizione]

Cambiamenti:
- Aggiunto [cosa]
- Creato [cosa]
```

---

## TEMPO: 4-8h

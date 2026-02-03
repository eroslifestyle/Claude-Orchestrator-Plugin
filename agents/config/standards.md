---
name: Quality Standards
description: Code quality metrics and standards including coverage targets and complexity limits
version: 6.0
---

# 📏 QUALITY STANDARDS V6.0

> **Versione:** 6.0
> **Data:** 2 Febbraio 2026
> **Scope:** Standard obbligatori per tutto il codice prodotto dagli agent

---

## CODE METRICS

### Coverage
| Livello | Target |
|---------|--------|
| Fast | ≥70% |
| Standard | ≥80% |
| Production | ≥85% |

### Limits
| Metrica | Max |
|---------|-----|
| Complessità | 10 |
| Nesting | 4 |
| Parametri | 5 |
| Righe/funzione | 30 |
| Righe/file | 300 |

---

## NAMING

### Python
```python
class UserService:      # PascalCase
def get_user():         # snake_case
MAX_RETRY = 3           # SCREAMING_SNAKE
```

### JavaScript
```javascript
class UserService {}    // PascalCase
function getUser() {}   // camelCase
const MAX_RETRY = 3     // SCREAMING_SNAKE
```

---

## SECURITY

### Checklist
```
□ Input validation
□ No SQL injection
□ No XSS
□ No hardcoded secrets
□ Auth/AuthZ OK
```

### Pattern
```python
# ❌ BAD
f"SELECT * FROM users WHERE id = {id}"

# ✅ GOOD
"SELECT * FROM users WHERE id = ?"
```

---

## PERFORMANCE

### Targets
| Operation | Target |
|-----------|--------|
| API Read | <100ms |
| API Write | <200ms |
| Page Load | <1s |

### Avoid
```
❌ N+1 queries
❌ No caching
❌ Memory leaks
```

---

## GIT

### Commit
```
<type>: <subject>

Types: feat, fix, docs, refactor, test
```

### Branch
```
feature/[ticket]-description
bugfix/[ticket]-description
```

---

## REVIEW CHECKLIST

```
□ Funzionalità OK
□ Security OK
□ Performance OK
□ Clean Code OK
□ Test OK
□ Docs OK
```

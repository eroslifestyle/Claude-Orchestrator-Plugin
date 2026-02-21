---
name: Orchestrator Examples
description: Practical examples for multi-agent orchestration V6.2
version: 6.2
---

# ORCHESTRATOR - ESEMPI PRATICI V6.2

> **Versione:** 6.0
> **Data:** 2 Febbraio 2026
> **Riferimento:** core/orchestrator.md

---

## ESEMPIO 1: Crea Tab Settings GUI

**Richiesta:** "Crea tab Settings con form per configurazione database"

**Analisi:**
- Domini: GUI + Database
- File coinvolti: 2 (tab_settings.py + db_config.py)
- Complessità: Media
- Dipendenze: GUI e DB config indipendenti -> Documenter dipende da entrambi (REGOLA #5)

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Crea UI tab Settings | experts/gui-super-expert.md | sonnet | PyQt5/Qt | - |
| T2 | Schema DB config | experts/database_expert.md | sonnet | SQLite/Schema | - |
| T3 | Documenta cambiamenti | core/documenter.md | haiku | Documentation | T1, T2 |

**Esecuzione:** T1 e T2 in PARALLELO, T3 SEQUENZIALE finale

---

## ESEMPIO 2: Ottimizza EA MetaTrader 5

**Richiesta:** "Ottimizza EA MT5 per ridurre uso CPU del 50%"

**Analisi:**
- Dominio: MQL5 + Performance Testing
- File coinvolti: 1 (EA principale)
- Complessità: Alta (ottimizzazione critica)
- Dipendenze: test dipende da ottimizzazione

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Analizza + ottimizza EA | experts/mql_expert.md | sonnet | MQL5/Optimization | - |
| T2 | Test performance | experts/tester_expert.md | sonnet | Performance/CPU | T1 |
| T3 | Documenta ottimizzazione | core/documenter.md | haiku | Documentation | T2 |

**Esecuzione:** SEQUENZIALE (T1 -> T2 -> T3)

---

## ESEMPIO 3: Trova + Fix Bug Security

**Richiesta:** "Trova e correggi vulnerabilita security nel modulo auth"

**Analisi:**
- Dominio: Analisi + Security
- File coinvolti: Sconosciuto (da trovare)
- Complessità: Alta (security critica)
- Dipendenze: Sequential chain

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Trova file auth | core/analyzer.md | haiku | Esplorazione | - |
| T2 | Analizza security | experts/security_unified_expert.md | sonnet | Security/OWASP | T1 |
| T3 | Fix vulnerabilita | experts/security_unified_expert.md | sonnet | Security/Fix | T2 |
| T4 | Test security | experts/tester_expert.md | sonnet | Security Testing | T3 |
| T5 | Documenta security fix | core/documenter.md | haiku | Documentation | T4 |

**Esecuzione:** SEQUENZIALE completa

---

## ESEMPIO 4: Design Sistema Multi-Modulo

**Richiesta:** "Progetta architettura sistema modulare per trading bot con plugin"

**Analisi:**
- Dominio: Architettura
- File coinvolti: 0 (solo design)
- Complessità: Alta (design critico)

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Design architettura | experts/architect_expert.md | opus | Architecture/Plugin | - |
| T2 | Documenta architettura | core/documenter.md | haiku | Documentation | T1 |

**Esecuzione:** SEQUENZIALE (T1 -> T2)

---

## ESEMPIO 5: Batch Update 15 File

**Richiesta:** "Aggiungi header copyright a tutti i 15 file Python nel modulo TELEGRAM"

**Analisi:**
- Dominio: Code editing (ripetitivo)
- File coinvolti: 15 (indipendenti)
- Complessità: Bassa (task meccanico)

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Trova file Python | core/analyzer.md | haiku | Esplorazione | - |
| T2-T16 | Aggiungi header (15x) | core/coder.md | haiku | Code editing | T1 |
| T17 | Documenta aggiornamenti | core/documenter.md | haiku | Documentation | T2-T16 |

**Esecuzione:** T1 -> T2-T16 in PARALLELO -> T17

---

## ESEMPIO 6: Integrazione API cTrader + Trading Strategy

**Richiesta:** "Implementa client cTrader API con risk management per trading forex"

**Analisi:**
- Domini: API Integration + Trading Strategy
- File coinvolti: 3 (client.py, risk_manager.py, strategy.py)
- Complessità: Alta

**Routing:**

| # | Task | Agent Expert File | Model | Specializzazione | Dipende Da |
|---|------|-------------------|-------|------------------|------------|
| T1 | Client cTrader API | experts/integration_expert.md | sonnet | API/cTrader | - |
| T2 | Risk manager | experts/trading_strategy_expert.md | sonnet | Risk/Position | - |
| T3 | Trading strategy | experts/trading_strategy_expert.md | sonnet | Strategy/TP/SL | - |
| T4 | Test integrazione | experts/tester_expert.md | sonnet | Integration Test | T1,T2,T3 |
| T5 | Documenta implementazione | core/documenter.md | haiku | Documentation | T4 |

**Esecuzione:** T1, T2, T3 in PARALLELO -> T4 -> T5

---

## TEMPLATE PROMPT SPECIALIZZATI

### GUI/PyQt5
```
"Sei un esperto sviluppatore PyQt5/Qt. [Task specifico].
Usa best practices Qt: signals/slots, layout manager,
stile coerente, validazione input, error handling."
```

### Database
```
"Sei un esperto database SQLite/PostgreSQL. [Task specifico].
Usa prepared statements, indexing appropriato, transazioni,
error handling, migration sicure."
```

### Security
```
"Sei un esperto sicurezza/OWASP. [Task specifico].
Previeni: SQL injection, XSS, CSRF, token hijacking.
Usa: encryption AES-256, hashing bcrypt, input validation."
```

### Trading
```
"Sei un esperto trading strategies. [Task specifico].
Implementa: risk management, position sizing, stop loss,
take profit, drawdown limits, money management."
```

### MQL5
```
"Sei un esperto MQL5/MetaTrader. [Task specifico].
Ottimizza: CPU usage, memoria, timer efficiency.
Usa: cache simboli, array pre-allocati, OnTimer."
```

### Testing
```
"Sei un esperto testing/debugging. [Task specifico].
Verifica: funzionalita, edge cases, performance,
memory leaks. Report dettagliato con metriche."
```

---

## BEST PRACTICES

### Quando Usare Explore
- "Trova tutti i file che contengono [keyword]"
- "Esplora struttura modulo [nome]"
- "Cerca file di configurazione"
- "Lista file modificati recentemente"

### Quando Usare Plan
- "Progetta architettura per [sistema]"
- "Design pattern per [problema]"
- "Pianifica implementazione [feature]"
- "Analizza refactoring [modulo]"

### Quando Usare Bash
- "Esegui git status"
- "Build progetto con npm"
- "Deploy su server"
- "Compila binario"

---

**Versione:** 6.0 - 2 Febbraio 2026

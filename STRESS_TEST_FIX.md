# STRESS TEST FIX - Da Applicare

> Data: 4 Febbraio 2026
> Sessione: Stress Test 30 Agent

---

## PROBLEMA CRITICO #1: Model "sonnet" Non Funziona

### Sintomo
```
API Error: 404
{"type":"error","error":{"type":"not_found_error",
"message":"model: claude-3-5-sonnet-20241022"}}
```

### Causa
Il Task tool quando riceve `model: "sonnet"` cerca il model deprecato `claude-3-5-sonnet-20241022` che non esiste piu'.

### FIX da Applicare
Quando lanci agent con Task tool, usa SOLO questi model:
- `model: "haiku"` -> FUNZIONA
- `model: "opus"` -> FUNZIONA
- `model: "sonnet"` -> NON USARE (broken)

### Workaround Temporaneo
Per task che richiederebbero sonnet, usa:
1. `haiku` per task semplici
2. `opus` per task complessi
3. Ometti il parametro `model` (usa default)

---

## PROBLEMA #2: Documenter Sotto Capacita'

### Sintomo
Documenter fallisce al 30% su task >100 documenti

### Causa
Token budget insufficiente: 200K disponibili vs 522K richiesti

### FIX
1. Limitare task a <100 documenti per sessione
2. Splittare task grandi in batch da 50-80 docs
3. Per task grossi, usare Opus invece di Haiku

---

## PROBLEMA #3: ASCII Art Illeggibile (GIA' FIXATO)

### Sintomo
I caratteri Unicode box-drawing (╔═╗║╚╝┏━┓┃) apparivano come blocchi grigi

### FIX Applicato
File `commands/orchestrator.md` riscritto con caratteri ASCII standard:
- `+` `-` `|` invece di box-drawing
- `*` invece di bullet points Unicode
- `->` invece di frecce Unicode

---

## AGENT FUNZIONANTI (Testati)

| Agent | Model | Status | Note |
|-------|-------|--------|------|
| Architect Expert | opus | OK | 34s, 23K tokens |
| DevOps Expert | haiku | OK | 54s, 31K tokens |
| Core Analyzer | haiku | OK | 25s, 20K tokens |
| Core Documenter | haiku | OK | 48s, 25K tokens (limite 100 docs) |

---

## AGENT DA NON USARE (Fino a Fix Model)

Tutti gli agent configurati con `model: "sonnet"`:
- GUI Super Expert
- Database Expert
- Security Expert
- MQL Expert
- Trading Expert
- Integration Expert
- Languages Expert
- AI Integration Expert
- Claude Systems Expert
- Mobile Expert
- N8N Expert
- Social Identity Expert
- Tester Expert
- Core Coder
- Core Reviewer
- Tutti i L2 Specialists

---

## COMANDI PER VERIFICARE

### Test Agent con Haiku
```
/orchestrator analizza struttura progetto
```
Dovrebbe usare Analyzer (haiku) -> FUNZIONA

### Test Agent con Opus
```
/orchestrator progetta architettura microservizi
```
Dovrebbe usare Architect (opus) -> FUNZIONA

### Test Agent con Sonnet (FALLIRA')
```
/orchestrator implementa feature login
```
Userebbe Coder (sonnet) -> FALLISCE

---

## AZIONI DA FARE

1. [ ] Modificare tabella routing in `orchestrator.md` per usare haiku/opus
2. [ ] Oppure attendere fix del Task tool per model sonnet
3. [ ] Testare nuovamente dopo fix

---

## ROUTING ALTERNATIVO SUGGERITO

Modifica temporanea alla tabella routing:

| Keyword | Agent | Model ATTUALE | Model SUGGERITO |
|---------|-------|---------------|-----------------|
| GUI, PyQt5 | gui-super-expert | sonnet | haiku |
| database, SQL | database_expert | sonnet | haiku |
| security | security_expert | sonnet | opus |
| implementa, fix | core/coder | sonnet | opus |
| review | core/reviewer | sonnet | opus |
| test, debug | tester_expert | sonnet | haiku |

---

## FILE MODIFICATI IN QUESTA SESSIONE

1. `c:\Users\LeoDg\.claude\commands\orchestrator.md`
   - Riscritto completamente con ASCII standard
   - Rimossi tutti i caratteri Unicode box-drawing
   - Aggiornata data a 4 Febbraio 2026

---

## METRICHE STRESS TEST

```
+---------------------------+--------+
| Metrica                   | Valore |
+---------------------------+--------+
| Agent lanciati            | 30     |
| Agent SUCCESS             | 4      |
| Agent FAILED              | 26     |
| Success Rate              | 13%    |
| Token consumati           | 100K   |
| Parallelismo              | OK     |
+---------------------------+--------+
```

---

## CONCLUSIONE

Il sistema di parallelismo FUNZIONA (30 agent lanciati simultaneamente).
Il problema e' SOLO il model "sonnet" che non viene trovato dall'API.

**Soluzione rapida**: Usa solo haiku/opus fino al fix.
**Soluzione definitiva**: Attendere aggiornamento Task tool.

---

*Fine documento - Creato automaticamente dopo stress test*

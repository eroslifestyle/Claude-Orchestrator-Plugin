# METRICS TRACKER SYSTEM V7.0

## Overview

Il Metric Tracker System e un sistema automatico di tracciamento delle metriche per il Multi-Agent System Claude Code. Monitora l'utilizzo degli agenti, il consumo di token, e le statistiche di performance nel tempo.

### Caratteristiche

- **Task Tracking**: Registra ogni task eseguita da ogni agente
- **Token Usage**: Traccia i token consumati per model (haiku, sonnet, opus)
- **Performance Metrics**: Durata media, successi, fallimenti
- **History Log**: Storico completo delle operazioni con retention configurabile
- **Health Monitoring**: Circuit breaker integrato per gestire agenti problematici
- **Automatic Backups**: Backup automatici prima delle modifiche

---

## Data Structure

### circuit-breaker.json

File di configurazione principale: `~/.claude/agents/config/circuit-breaker.json`

```json
{
  "version": "7.0",
  "updated": "2026-02-15T22:00:00Z",
  "config": {
    "failure_threshold": 5,
    "cooldown_minutes": 10,
    "timeout_seconds": 180,
    "retry_attempts": 3,
    "history_max_entries": 1000,
    "history_retention_days": 30
  },
  "agents": {
    "core/coder.md": {
      "status": "healthy",
      "failures": 0,
      "last_failure": null,
      "blacklisted_until": null,
      "metrics": {
        "tasks_total": 150,
        "tasks_successful": 142,
        "tasks_failed": 5,
        "tasks_cancelled": 3,
        "avg_duration_seconds": 45.2,
        "total_duration_seconds": 6780.0,
        "last_task_timestamp": "2026-02-15T21:30:00Z",
        "first_task_timestamp": "2026-02-01T09:00:00Z"
      },
      "token_usage": {
        "haiku": {"total": 0, "last": null, "count": 0},
        "sonnet": {"total": 245000, "last": 1500, "count": 142},
        "opus": {"total": 45000, "last": 3000, "count": 8}
      }
    }
  },
  "metrics": {
    "total_agents": 43,
    "total_requests": 1250,
    "successful": 1180,
    "failed": 45,
    "fallback_used": 25,
    "circuit_breaks": 0
  },
  "history": [
    {
      "timestamp": "2026-02-15T21:30:00Z",
      "agent": "core/coder.md",
      "action": "task_completed",
      "model": "sonnet",
      "task_id": "task-abc123",
      "tokens_used": 1500,
      "duration_seconds": 42.5
    }
  ]
}
```

### Campi Metrics per Agente

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `tasks_total` | int | Numero totale di task eseguite |
| `tasks_successful` | int | Task completate con successo |
| `tasks_failed` | int | Task fallite |
| `tasks_cancelled` | int | Task cancellate |
| `avg_duration_seconds` | float | Durata media task in secondi |
| `total_duration_seconds` | float | Tempo totale speso in task |
| `last_task_timestamp` | string ISO | Timestamp ultima task |
| `first_task_timestamp` | string ISO | Timestamp prima task |

### Campi Token Usage per Model

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `total` | int | Token totali consumati |
| `last` | int | Token usati nell'ultima task |
| `count` | int | Numero di task con questo model |

---

## API Reference

### Classe MetricTracker

```python
from agents.scripts.metric_tracker import MetricTracker, TaskTracker

# Inizializza
tracker = MetricTracker()
```

#### Metodi Principali

##### `register_agent(agent_name: str, agent_file: str)`

Registra un nuovo agente nel sistema.

```python
tracker.register_agent("Coder", "core/coder.md")
```

##### `record_task_start(agent_file: str, task_id: str = None, model: str = "sonnet") -> str`

Registra l'inizio di una task. Restituisce il timestamp ISO per usarlo in `record_task_complete`.

```python
start_ts = tracker.record_task_start(
    "core/coder.md",
    task_id="task-123",
    model="sonnet"
)
```

##### `record_task_complete(agent_file: str, start_timestamp: str, tokens_used: int = 0, model: str = "sonnet", task_id: str = None) -> float`

Registra il completamento di una task. Restituisce la durata in secondi.

```python
duration = tracker.record_task_complete(
    "core/coder.md",
    start_ts,
    tokens_used=1500,
    model="sonnet",
    task_id="task-123"
)
print(f"Task completata in {duration} secondi")
```

##### `record_task_failure(agent_file: str, start_timestamp: str, error_message: str = None, model: str = "sonnet", task_id: str = None) -> float`

Registra il fallimento di una task.

```python
duration = tracker.record_task_failure(
    "core/coder.md",
    start_ts,
    error_message="SyntaxError in generated code",
    model="sonnet",
    task_id="task-123"
)
```

##### `record_task_cancelled(agent_file: str, start_timestamp: str, reason: str = None, task_id: str = None) -> float`

Registra una task cancellata.

```python
duration = tracker.record_task_cancelled(
    "core/coder.md",
    start_ts,
    reason="User cancelled",
    task_id="task-123"
)
```

##### `get_agent_metrics(agent_file: str) -> Dict`

Recupera le metriche di un agente.

```python
metrics = tracker.get_agent_metrics("core/coder.md")
print(f"Task totali: {metrics['metrics']['tasks_total']}")
print(f"Success rate: {metrics['metrics']['tasks_successful'] / metrics['metrics']['tasks_total'] * 100:.1f}%")
```

##### `get_system_metrics() -> Dict`

Recupera le metriche di sistema.

```python
sys_metrics = tracker.get_system_metrics()
print(f"Total requests: {sys_metrics['total_requests']}")
print(f"Success rate: {sys_metrics['successful'] / sys_metrics['total_requests'] * 100:.1f}%")
```

##### `get_leaderboard(metric: str = "tasks_total", top_n: int = 10) -> List[Dict]`

Recupera la classifica degli agenti per metrica.

```python
# Top 10 agenti per numero di task
leaderboard = tracker.get_leaderboard("tasks_total", top_n=10)

# Top 5 agenti per durata media
fastest = tracker.get_leaderboard("avg_duration_seconds", top_n=5)
```

##### `get_token_summary() -> Dict`

Recupera il riepilogo token usage per model.

```python
summary = tracker.get_token_summary()
for model, data in summary.items():
    print(f"{model}: {data['total']:,} tokens ({data['count']} tasks)")
```

##### `get_history(agent_file: str = None, limit: int = 100) -> List[Dict]`

Recupera la history delle task.

```python
# Ultimi 100 task di tutti gli agenti
all_history = tracker.get_history(limit=100)

# Ultimi 50 task di un agente specifico
coder_history = tracker.get_history("core/coder.md", limit=50)
```

##### `generate_report(output_file: Path = None) -> str`

Genera un report in formato markdown.

```python
report = tracker.generate_report()
print(report)

# Salva su file
report = tracker.generate_report(Path("metrics_report.md"))
```

##### `save(backup: bool = True)`

Salva il file di configurazione con backup opzionale.

```python
tracker.save(backup=True)
```

---

### Context Manager TaskTracker

Per tracking automatico con context manager:

```python
from agents.scripts.metric_tracker import TaskTracker

# Uso base
with TaskTracker("core/coder.md", model="sonnet") as task:
    # ... esegui la task ...
    task.set_tokens_used(1500)
# Task completata automaticamente all'uscita

# Gestione errori automatica
try:
    with TaskTracker("core/coder.md", model="sonnet", task_id="task-123") as task:
        result = execute_work()
        task.set_tokens_used(result.tokens)
except Exception as e:
    # Task marcata come fallita automaticamente
    pass
```

---

## Usage Examples

### Esempio 1: Tracking Manuale

```python
from pathlib import Path
import sys

# Add agents directory to path
agents_dir = Path.home() / ".claude" / "agents"
sys.path.insert(0, str(agents_dir / "scripts"))

from metric_tracker import MetricTracker

tracker = MetricTracker()

# Registra inizio task
start = tracker.record_task_start("core/coder.md", model="sonnet")

# ... esegui lavoro ...

# Registra completamento con token usage
tracker.record_task_complete("core/coder.md", start, tokens_used=1500, model="sonnet")

# Mostra metriche
metrics = tracker.get_agent_metrics("core/coder.md")
print(f"Tasks: {metrics['metrics']['tasks_total']}")
print(f"Avg duration: {metrics['metrics']['avg_duration_seconds']:.1f}s")
```

### Esempio 2: Tracking con Context Manager

```python
from metric_tracker import TaskTracker

# Tracking automatico con gestione errori
with TaskTracker("core/coder.md", model="sonnet", task_id="fix-bug-123") as task:
    # Esegui lavoro
    result = implement_fix()

    # Imposta token usati
    task.set_tokens_used(result.token_count)

# Al termine del blocco, la task e registrata come completata
# Se si verifica un'eccezione, viene registrata come fallita
```

### Esempio 3: Report Completivo

```python
from metric_tracker import MetricTracker
from pathlib import Path

tracker = MetricTracker()

# Genera report
report = tracker.generate_report(Path("metrics_report.md"))

# Mostra statistiche
print("\n=== SYSTEM METRICS ===")
sys = tracker.get_system_metrics()
print(f"Total Requests: {sys['total_requests']}")
print(f"Success Rate: {sys['successful']/sys['total_requests']*100:.1f}%")

print("\n=== TOP AGENTS ===")
leaderboard = tracker.get_leaderboard("tasks_total", top_n=5)
for i, entry in enumerate(leaderboard, 1):
    print(f"{i}. {entry['agent_name']}: {entry['tasks_total']} tasks")

print("\n=== TOKEN USAGE ===")
tokens = tracker.get_token_summary()
for model, data in tokens.items():
    print(f"{model}: {data['total']:,} tokens")
```

### Esempio 4: Health Check

```python
from metric_tracker import MetricTracker

tracker = MetricTracker()

# Verifica salute agente
if tracker.check_agent_health("core/coder.md"):
    print("Coder e healthy")
else:
    print("Coder e unhealthy, resetting failures")
    tracker.reset_agent_failures("core/coder.md")
```

---

## CLI Interface

Lo script include anche una CLI per operazioni rapide:

```bash
# Genera report
python ~/.claude/agents/scripts/metric_tracker.py report

# Report in formato JSON
python ~/.claude/agents/scripts/metric_tracker.py report --format json

# Salva report su file
python ~/.claude/agents/scripts/metric_tracker.py report -o report.md

# Mostra leaderboard
python ~/.claude/agents/scripts/metric_tracker.py leaderboard -m tasks_total -n 10

# Mostra metriche agente specifico
python ~/.claude/agents/scripts/metric_tracker.py agent core/coder.md

# Mostra riepilogo token
python ~/.claude/agents/scripts/metric_tracker.py tokens

# Health check
python ~/.claude/agents/scripts/metric_tracker.py health core/coder.md

# Reset failures
python ~/.claude/agents/scripts/metric_tracker.py reset core/coder.md
```

---

## Integration with Orchestrator

Per integrare il Metric Tracker nell'Orchestrator, aggiungere all'inizio di ogni skill:

```python
# In ogni skill file
from pathlib import Path
import sys

agents_dir = Path.home() / ".claude" / "agents"
sys.path.insert(0, str(agents_dir / "scripts"))

from metric_tracker import TaskTracker

# Prima di eseguire il lavoro
with TaskTracker("core/coder.md", model="sonnet") as task:
    # ... codice della skill ...
    # Calcola token usati se possibile
    task.set_tokens_used(estimate_tokens())
```

### Auto-Integration Pattern

Per integrazione automatica, creare un decorator:

```python
# metrics_decorator.py
from functools import wraps
from metric_tracker import TaskTracker

def track_agent(agent_file: str, default_model: str = "sonnet"):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            with TaskTracker(agent_file, model=default_model) as task:
                result = func(*args, **kwargs)
                # Se result ha token count, usalo
                if hasattr(result, 'tokens_used'):
                    task.set_tokens_used(result.tokens_used)
                return result
        return wrapper
    return decorator

# Uso
@track_agent("core/coder.md", "sonnet")
def implement_feature(spec):
    # ... implementazione ...
    return ImplementationResult(tokens_used=1500)
```

---

## Troubleshooting

### Problema: Metrics rimangono a zero

**Causa:** Il sistema non e integrato nelle skill. Nessuno sta chiamando le funzioni di tracking.

**Soluzione:** Aggiungere chiamate a `TaskTracker` o `MetricTracker` nelle skill.

### Problema: File corrotto

**Causa:** JSON invalid o scrittura interrotta.

**Soluzione:**
1. I backup vengono creati automaticamente in `~/.claude/agents/backups/`
2. Ripristinare l'ultimo backup:
```bash
cp ~/.claude/agents/backups/circuit-breaker_YYYYMMDD_HHMMSS.json \
   ~/.claude/agents/config/circuit-breaker.json
```

### Problema: Performance lenta

**Causa:** Troppi entries in history.

**Soluzione:** Ridurre `history_max_entries` nel config o aumentare `history_retention_days`. Il cleanup avviene automaticamente a ogni `save()`.

### Problema: Token usage non accurato

**Causa:** I token non vengono passati al sistema di tracking.

**Soluzione:** Claude Code non espone il conteggio token direttamente. Usare stime basate sulla lunghezza del testo input/output.

---

## Configuration

### Config Parameters

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| `failure_threshold` | 5 | Fallimenti consecutivi prima di blacklist |
| `cooldown_minutes` | 10 | Minuti di cooldown dopo blacklist |
| `timeout_seconds` | 180 | Timeout per singola task |
| `retry_attempts` | 3 | Tentativi dopo fallimento |
| `history_max_entries` | 1000 | Massimo entries in history |
| `history_retention_days` | 30 | Giorni di retention history |

### File Locations

| File | Path |
|------|------|
| Config | `~/.claude/agents/config/circuit-breaker.json` |
| Script | `~/.claude/agents/scripts/metric_tracker.py` |
| Backups | `~/.claude/agents/backups/circuit-breaker_*.json` |

---

## Version History

| Versione | Data | Modifiche |
|----------|------|-----------|
| 7.0 | 2026-02-15 | Nuova struttura con metrics e token usage per agente |
| 6.2 | 2026-02-02 | Versione base con tracking requests/failures |

---

**Autore:** DevOps Expert / Claude Systems Expert
**Versione:** 7.0
**Ultimo Aggiornamento:** 15 Febbraio 2026

#!/usr/bin/env python3
"""
METRIC TRACKER V7.0
====================
Sistema di tracking automatico per agenti Claude Code.

Traccia:
- Task eseguiti per agente
- Successi/fallimenti
- Token usage per model (haiku, sonnet, opus)
- Timestamp delle attività
- History delle operazioni

Author: DevOps Expert / Claude Systems Expert
Version: 7.0
Date: 2026-02-15
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Any, List
from dataclasses import dataclass, asdict
from collections import defaultdict

# Paths
BASE_DIR = Path.home() / ".claude" / "agents"
CONFIG_DIR = BASE_DIR / "config"
CIRCUIT_BREAKER_FILE = CONFIG_DIR / "circuit-breaker.json"
BACKUP_DIR = BASE_DIR / "backups"


@dataclass
class TaskRecord:
    """Record di una task eseguita."""
    timestamp: str
    agent: str
    action: str  # task_started, task_completed, task_failed, task_cancelled
    model: str  # haiku, sonnet, opus
    tokens_used: int
    duration_seconds: float
    task_id: Optional[str] = None
    error_message: Optional[str] = None


class MetricTracker:
    """
    Gestore delle metriche per il circuit breaker.

    Fornisce API per registrare e recuperare statistiche di utilizzo degli agenti.
    """

    def __init__(self, config_file: Optional[Path] = None):
        """
        Inizializza il MetricTracker.

        Args:
            config_file: Path del file circuit-breaker.json (default: automatico)
        """
        self.config_file = config_file or CIRCUIT_BREAKER_FILE
        self._data: Dict[str, Any] = {}
        self._load()

    def _load(self) -> None:
        """Carica il file di configurazione."""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    self._data = json.load(f)
            except json.JSONDecodeError as e:
                print(f"[ERROR] Invalid JSON in {self.config_file}: {e}")
                self._init_default_structure()
        else:
            self._init_default_structure()

        # Assicura che la struttura v7.0 sia presente
        self._ensure_v7_structure()

    def _init_default_structure(self) -> None:
        """Inizializza la struttura predefinita."""
        self._data = {
            "version": "7.0",
            "updated": datetime.now().isoformat(),
            "config": {
                "failure_threshold": 5,
                "cooldown_minutes": 10,
                "timeout_seconds": 180,
                "retry_attempts": 3,
                "history_max_entries": 1000,
                "history_retention_days": 30
            },
            "agents": {},
            "fallback_chain": {
                "L2_to_L1": {},
                "ultimate_fallback": "core/coder.md"
            },
            "metrics": {
                "total_agents": 0,
                "total_requests": 0,
                "successful": 0,
                "failed": 0,
                "fallback_used": 0,
                "circuit_breaks": 0
            },
            "history": []
        }

    def _ensure_v7_structure(self) -> None:
        """Assicura che la struttura dati v7.0 sia completa."""
        # Aggiorna version se necessario
        if self._data.get("version", "6.2") != "7.0":
            self._data["version"] = "7.0"

        # Assicura config con nuovi parametri
        if "history_max_entries" not in self._data.get("config", {}):
            self._data.setdefault("config", {})["history_max_entries"] = 1000
        if "history_retention_days" not in self._data.get("config", {}):
            self._data.setdefault("config", {})["history_retention_days"] = 30

        # Aggiorna struttura agents con metrics e token_usage
        for agent_name, agent_data in self._data.get("agents", {}).items():
            if "metrics" not in agent_data:
                agent_data["metrics"] = {
                    "tasks_total": 0,
                    "tasks_successful": 0,
                    "tasks_failed": 0,
                    "tasks_cancelled": 0,
                    "avg_duration_seconds": 0.0,
                    "total_duration_seconds": 0.0,
                    "last_task_timestamp": None,
                    "first_task_timestamp": None
                }
            if "token_usage" not in agent_data:
                agent_data["token_usage"] = {
                    "haiku": {"total": 0, "last": None, "count": 0},
                    "sonnet": {"total": 0, "last": None, "count": 0},
                    "opus": {"total": 0, "last": None, "count": 0}
                }

        # Assicura che history esista
        if "history" not in self._data:
            self._data["history"] = []

        # Aggiorna metrics globali
        if "metrics" not in self._data:
            self._data["metrics"] = {
                "total_agents": len(self._data.get("agents", {})),
                "total_requests": 0,
                "successful": 0,
                "failed": 0,
                "fallback_used": 0,
                "circuit_breaks": 0
            }

    def save(self, backup: bool = True) -> None:
        """
        Salva il file di configurazione.

        Args:
            backup: Se True, crea un backup prima di salvare
        """
        # Aggiorna timestamp
        self._data["updated"] = datetime.now().isoformat()

        # Aggiorna total_agents
        self._data["metrics"]["total_agents"] = len(self._data.get("agents", {}))

        # Cleanup vecchia history se necessario
        self._cleanup_old_history()

        # Backup opzionale
        if backup and self.config_file.exists():
            self._create_backup()

        # Salva
        self.config_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_file, 'w', encoding='utf-8') as f:
            json.dump(self._data, f, indent=2, ensure_ascii=False)

    def _create_backup(self) -> None:
        """Crea un backup del file corrente."""
        BACKUP_DIR.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = BACKUP_DIR / f"circuit-breaker_{timestamp}.json"

        # Copia il file
        import shutil
        shutil.copy2(self.config_file, backup_file)

        # Mantiene solo gli ultimi 10 backup
        self._cleanup_old_backups()

    def _cleanup_old_backups(self) -> None:
        """Mantiene solo gli ultimi 10 backup."""
        backups = sorted(BACKUP_DIR.glob("circuit-breaker_*.json"), reverse=True)
        for old_backup in backups[10:]:
            old_backup.unlink()

    def _cleanup_old_history(self) -> None:
        """Rimuove voci history vecchie oltre il retention period."""
        config = self._data.get("config", {})
        retention_days = config.get("history_retention_days", 30)
        max_entries = config.get("history_max_entries", 1000)

        cutoff = datetime.now() - timedelta(days=retention_days)

        # Filtra per data
        history = self._data.get("history", [])
        filtered = []
        for entry in history:
            try:
                entry_time = datetime.fromisoformat(entry.get("timestamp", ""))
                if entry_time > cutoff:
                    filtered.append(entry)
            except (ValueError, TypeError):
                # Mantieni entry con timestamp invalid
                filtered.append(entry)

        # Limita numero di entries
        if len(filtered) > max_entries:
            filtered = filtered[-max_entries:]

        self._data["history"] = filtered

    # ============ AGENT MANAGEMENT ============

    def register_agent(self, agent_name: str, agent_file: str) -> None:
        """
        Registra un nuovo agente nel sistema.

        Args:
            agent_name: Nome dell'agente (es: "Analyzer", "Coder")
            agent_file: Path del file dell'agente (es: "core/analyzer.md")
        """
        agents = self._data.setdefault("agents", {})

        if agent_file not in agents:
            agents[agent_file] = {
                "status": "healthy",
                "failures": 0,
                "last_failure": None,
                "blacklisted_until": None,
                "metrics": {
                    "tasks_total": 0,
                    "tasks_successful": 0,
                    "tasks_failed": 0,
                    "tasks_cancelled": 0,
                    "avg_duration_seconds": 0.0,
                    "total_duration_seconds": 0.0,
                    "last_task_timestamp": None,
                    "first_task_timestamp": None
                },
                "token_usage": {
                    "haiku": {"total": 0, "last": None, "count": 0},
                    "sonnet": {"total": 0, "last": None, "count": 0},
                    "opus": {"total": 0, "last": None, "count": 0}
                }
            }

            self.save(backup=False)

    def get_agent(self, agent_file: str) -> Optional[Dict[str, Any]]:
        """
        Recupera i dati di un agente.

        Args:
            agent_file: Path del file dell'agente

        Returns:
            Dict con i dati dell'agente o None se non trovato
        """
        return self._data.get("agents", {}).get(agent_file)

    # ============ TASK TRACKING ============

    def record_task_start(
        self,
        agent_file: str,
        task_id: Optional[str] = None,
        model: str = "sonnet"
    ) -> str:
        """
        Registra l'inizio di una task.

        Args:
            agent_file: Path dell'agente
            task_id: ID univoco della task (opzionale)
            model: Modello usato (haiku, sonnet, opus)

        Returns:
            Timestamp ISO dell'inizio task
        """
        timestamp = datetime.now().isoformat()

        # Aggiorna agent metrics
        agent = self._data.setdefault("agents", {}).setdefault(agent_file, {})
        agent.setdefault("metrics", {
            "tasks_total": 0,
            "tasks_successful": 0,
            "tasks_failed": 0,
            "tasks_cancelled": 0,
            "avg_duration_seconds": 0.0,
            "total_duration_seconds": 0.0,
            "last_task_timestamp": None,
            "first_task_timestamp": None
        })

        metrics = agent["metrics"]
        metrics["last_task_timestamp"] = timestamp
        if metrics["first_task_timestamp"] is None:
            metrics["first_task_timestamp"] = timestamp

        # Aggiorna global metrics
        global_metrics = self._data.setdefault("metrics", {})
        global_metrics["total_requests"] = global_metrics.get("total_requests", 0) + 1

        # Aggiorna token usage count
        agent.setdefault("token_usage", {
            "haiku": {"total": 0, "last": None, "count": 0},
            "sonnet": {"total": 0, "last": None, "count": 0},
            "opus": {"total": 0, "last": None, "count": 0}
        })
        if model in agent["token_usage"]:
            agent["token_usage"][model]["count"] = \
                agent["token_usage"][model].get("count", 0) + 1

        # Aggiungi history
        self._add_history({
            "timestamp": timestamp,
            "agent": agent_file,
            "action": "task_started",
            "model": model,
            "task_id": task_id,
            "tokens_used": 0,
            "duration_seconds": 0
        })

        self.save(backup=False)
        return timestamp

    def record_task_complete(
        self,
        agent_file: str,
        start_timestamp: str,
        tokens_used: int = 0,
        model: str = "sonnet",
        task_id: Optional[str] = None
    ) -> float:
        """
        Registra il completamento di una task.

        Args:
            agent_file: Path dell'agente
            start_timestamp: Timestamp di inizio (da record_task_start)
            tokens_used: Token consumati
            model: Modello usato
            task_id: ID della task

        Returns:
            Durata in secondi
        """
        end_timestamp = datetime.now()
        try:
            start = datetime.fromisoformat(start_timestamp)
            duration = (end_timestamp - start).total_seconds()
        except (ValueError, TypeError):
            duration = 0

        # Aggiorna agent metrics
        agent = self._data.get("agents", {}).get(agent_file, {})
        if agent:
            metrics = agent.get("metrics", {})
            metrics["tasks_total"] = metrics.get("tasks_total", 0) + 1
            metrics["tasks_successful"] = metrics.get("tasks_successful", 0) + 1

            # Aggiorna durata media
            total_dur = metrics.get("total_duration_seconds", 0) + duration
            metrics["total_duration_seconds"] = total_dur
            metrics["avg_duration_seconds"] = \
                total_dur / metrics["tasks_total"]

            # Aggiorna token usage
            if model in agent.get("token_usage", {}):
                agent["token_usage"][model]["total"] = \
                    agent["token_usage"][model].get("total", 0) + tokens_used
                agent["token_usage"][model]["last"] = tokens_used

        # Aggiorna global metrics
        global_metrics = self._data.get("metrics", {})
        global_metrics["successful"] = global_metrics.get("successful", 0) + 1

        # Aggiungi history
        self._add_history({
            "timestamp": end_timestamp.isoformat(),
            "agent": agent_file,
            "action": "task_completed",
            "model": model,
            "task_id": task_id,
            "tokens_used": tokens_used,
            "duration_seconds": duration
        })

        self.save(backup=False)
        return duration

    def record_task_failure(
        self,
        agent_file: str,
        start_timestamp: str,
        error_message: Optional[str] = None,
        model: str = "sonnet",
        task_id: Optional[str] = None
    ) -> float:
        """
        Registra il fallimento di una task.

        Args:
            agent_file: Path dell'agente
            start_timestamp: Timestamp di inizio
            error_message: Messaggio di errore
            model: Modello usato
            task_id: ID della task

        Returns:
            Durata in secondi
        """
        end_timestamp = datetime.now()
        try:
            start = datetime.fromisoformat(start_timestamp)
            duration = (end_timestamp - start).total_seconds()
        except (ValueError, TypeError):
            duration = 0

        # Aggiorna agent
        agent = self._data.get("agents", {}).get(agent_file, {})
        if agent:
            # Incrementa failures
            agent["failures"] = agent.get("failures", 0) + 1
            agent["last_failure"] = end_timestamp.isoformat()

            # Aggiorna status se necessario
            if agent["failures"] >= self._data.get("config", {}).get("failure_threshold", 5):
                agent["status"] = "unhealthy"
                # Aggiorna circuit breaks global
                self._data["metrics"]["circuit_breaks"] = \
                    self._data["metrics"].get("circuit_breaks", 0) + 1

            # Aggiorna metrics
            metrics = agent.get("metrics", {})
            metrics["tasks_total"] = metrics.get("tasks_total", 0) + 1
            metrics["tasks_failed"] = metrics.get("tasks_failed", 0) + 1

        # Aggiorna global metrics
        global_metrics = self._data.get("metrics", {})
        global_metrics["failed"] = global_metrics.get("failed", 0) + 1

        # Aggiungi history
        self._add_history({
            "timestamp": end_timestamp.isoformat(),
            "agent": agent_file,
            "action": "task_failed",
            "model": model,
            "task_id": task_id,
            "tokens_used": 0,
            "duration_seconds": duration,
            "error_message": error_message
        })

        self.save(backup=False)
        return duration

    def record_task_cancelled(
        self,
        agent_file: str,
        start_timestamp: str,
        reason: Optional[str] = None,
        task_id: Optional[str] = None
    ) -> float:
        """
        Registra una task cancellata.

        Args:
            agent_file: Path dell'agente
            start_timestamp: Timestamp di inizio
            reason: Motivo della cancellazione
            task_id: ID della task

        Returns:
            Durata in secondi
        """
        end_timestamp = datetime.now()
        try:
            start = datetime.fromisoformat(start_timestamp)
            duration = (end_timestamp - start).total_seconds()
        except (ValueError, TypeError):
            duration = 0

        # Aggiorna agent metrics
        agent = self._data.get("agents", {}).get(agent_file, {})
        if agent:
            metrics = agent.get("metrics", {})
            metrics["tasks_total"] = metrics.get("tasks_total", 0) + 1
            metrics["tasks_cancelled"] = metrics.get("tasks_cancelled", 0) + 1

        # Aggiungi history
        self._add_history({
            "timestamp": end_timestamp.isoformat(),
            "agent": agent_file,
            "action": "task_cancelled",
            "model": "unknown",
            "task_id": task_id,
            "tokens_used": 0,
            "duration_seconds": duration,
            "error_message": reason
        })

        self.save(backup=False)
        return duration

    # ============ TOKEN TRACKING ============

    def update_token_usage(
        self,
        agent_file: str,
        model: str,
        tokens: int
    ) -> None:
        """
        Aggiorna il token usage per un agente.

        Args:
            agent_file: Path dell'agente
            model: Modello (haiku, sonnet, opus)
            tokens: Numero di token usati
        """
        agent = self._data.get("agents", {}).get(agent_file, {})
        if agent:
            token_usage = agent.setdefault("token_usage", {})
            if model not in token_usage:
                token_usage[model] = {"total": 0, "last": None, "count": 0}

            token_usage[model]["total"] = token_usage[model].get("total", 0) + tokens
            token_usage[model]["last"] = tokens

            self.save(backup=False)

    # ============ RETRIEVAL METHODS ============

    def get_agent_metrics(self, agent_file: str) -> Dict[str, Any]:
        """
        Recupera le metriche di un agente.

        Args:
            agent_file: Path dell'agente

        Returns:
            Dict con le metriche
        """
        agent = self._data.get("agents", {}).get(agent_file, {})
        return {
            "status": agent.get("status", "unknown"),
            "failures": agent.get("failures", 0),
            "metrics": agent.get("metrics", {}),
            "token_usage": agent.get("token_usage", {})
        }

    def get_system_metrics(self) -> Dict[str, Any]:
        """
        Recupera le metriche di sistema.

        Returns:
            Dict con le metriche globali
        """
        return {
            **self._data.get("metrics", {}),
            "updated": self._data.get("updated"),
            "version": self._data.get("version")
        }

    def get_leaderboard(self, metric: str = "tasks_total", top_n: int = 10) -> List[Dict]:
        """
        Recupera la classifica degli agenti per metrica.

        Args:
            metric: Metrica da ordinare (tasks_total, tasks_successful, avg_duration_seconds)
            top_n: Numero di agenti da restituire

        Returns:
            Lista di dict {agent_file, metric_value}
        """
        agents_data = []
        for agent_file, agent_data in self._data.get("agents", {}).items():
            value = agent_data.get("metrics", {}).get(metric, 0)
            agents_data.append({
                "agent_file": agent_file,
                "agent_name": self._extract_agent_name(agent_file),
                metric: value
            })

        # Ordina per valore decrescente
        agents_data.sort(key=lambda x: x.get(metric, 0), reverse=True)
        return agents_data[:top_n]

    def get_token_summary(self) -> Dict[str, Dict]:
        """
        Recupera il riepilogo token usage per model.

        Returns:
            Dict {model: {total, count, avg}}
        """
        summary = {
            "haiku": {"total": 0, "count": 0, "avg": 0},
            "sonnet": {"total": 0, "count": 0, "avg": 0},
            "opus": {"total": 0, "count": 0, "avg": 0}
        }

        for agent_data in self._data.get("agents", {}).values():
            token_usage = agent_data.get("token_usage", {})
            for model in summary:
                if model in token_usage:
                    summary[model]["total"] += token_usage[model].get("total", 0)
                    summary[model]["count"] += token_usage[model].get("count", 0)

        # Calcola media
        for model in summary:
            if summary[model]["count"] > 0:
                summary[model]["avg"] = summary[model]["total"] // summary[model]["count"]

        return summary

    def get_history(
        self,
        agent_file: Optional[str] = None,
        limit: int = 100
    ) -> List[Dict]:
        """
        Recupera la history delle task.

        Args:
            agent_file: Filtra per agente (opzionale)
            limit: Numero massimo di entries

        Returns:
            Lista di entries history
        """
        history = self._data.get("history", [])

        if agent_file:
            history = [h for h in history if h.get("agent") == agent_file]

        return history[-limit:]

    def _add_history(self, entry: Dict) -> None:
        """Aggiunge una entry alla history."""
        history = self._data.setdefault("history", [])
        history.append(entry)

        # Limita dimensione
        max_entries = self._data.get("config", {}).get("history_max_entries", 1000)
        if len(history) > max_entries:
            self._data["history"] = history[-max_entries:]

    @staticmethod
    def _extract_agent_name(agent_file: str) -> str:
        """Estrae il nome dell'agente dal path."""
        # core/analyzer.md -> Analyzer
        # experts/gui-super-expert.md -> GUI Super Expert
        parts = agent_file.replace(".md", "").split("/")
        name = parts[-1].replace("-", " ").replace("_", " ").title()
        return name

    # ============ REPORTING ============

    def generate_report(self, output_file: Optional[Path] = None) -> str:
        """
        Genera un report delle metriche.

        Args:
            output_file: Path del file di output (opzionale)

        Returns:
            Report in formato markdown
        """
        lines = [
            "# METRIC TRACKER REPORT",
            f"Generated: {datetime.now().isoformat()}",
            f"Version: {self._data.get('version', 'unknown')}",
            "",
            "## System Metrics",
            "",
        ]

        # System metrics
        sys_metrics = self.get_system_metrics()
        for key, value in sys_metrics.items():
            if key != "updated":
                lines.append(f"- **{key}**: {value}")

        lines.extend([
            "",
            "## Token Summary",
            "",
        ])

        # Token summary
        token_summary = self.get_token_summary()
        for model, data in token_summary.items():
            lines.append(f"### {model.title()}")
            lines.append(f"- Total Tokens: {data['total']:,}")
            lines.append(f"- Task Count: {data['count']:,}")
            lines.append(f"- Avg per Task: {data['avg']:,}")
            lines.append("")

        # Leaderboard
        lines.extend([
            "## Top Agents by Tasks",
            "",
            "| Rank | Agent | Tasks | Success | Failed | Avg Duration |",
            "|------|-------|-------|---------|--------|--------------|"
        ])

        leaderboard = self.get_leaderboard("tasks_total", top_n=20)
        for i, entry in enumerate(leaderboard, 1):
            agent_file = entry["agent_file"]
            metrics = self.get_agent_metrics(agent_file)["metrics"]
            lines.append(
                f"| {i} | {entry['agent_name']} | "
                f"{metrics.get('tasks_total', 0)} | "
                f"{metrics.get('tasks_successful', 0)} | "
                f"{metrics.get('tasks_failed', 0)} | "
                f"{metrics.get('avg_duration_seconds', 0):.2f}s |"
            )

        report = "\n".join(lines)

        if output_file:
            output_file.parent.mkdir(parents=True, exist_ok=True)
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(report)

        return report

    # ============ HEALTH CHECK ============

    def check_agent_health(self, agent_file: str) -> bool:
        """
        Verifica se un agente è healthy.

        Args:
            agent_file: Path dell'agente

        Returns:
            True se healthy, False altrimenti
        """
        agent = self._data.get("agents", {}).get(agent_file, {})
        if not agent:
            return False

        # Verifica se in blacklist
        if agent.get("blacklisted_until"):
            try:
                blacklist_end = datetime.fromisoformat(agent["blacklisted_until"])
                if datetime.now() < blacklist_end:
                    return False
            except (ValueError, TypeError):
                pass

        # Verifica status
        return agent.get("status", "unknown") == "healthy"

    def reset_agent_failures(self, agent_file: str) -> None:
        """
        Resetta i failures di un agente.

        Args:
            agent_file: Path dell'agente
        """
        agent = self._data.get("agents", {}).get(agent_file, {})
        if agent:
            agent["failures"] = 0
            agent["last_failure"] = None
            agent["blacklisted_until"] = None
            agent["status"] = "healthy"
            self.save(backup=False)


# ============ CONTEXT MANAGER FOR AUTOMATIC TRACKING ============

class TaskTracker:
    """
    Context manager per tracking automatico di task.

    Uso:
        with TaskTracker("core/analyzer.md", model="haiku") as tracker:
            # ... codice ...
            tracker.set_tokens_used(1000)
        # Task completata automaticamente
    """

    def __init__(
        self,
        agent_file: str,
        model: str = "sonnet",
        task_id: Optional[str] = None,
        tracker: Optional[MetricTracker] = None
    ):
        self.agent_file = agent_file
        self.model = model
        self.task_id = task_id
        self.tracker = tracker or MetricTracker()
        self.start_timestamp: Optional[str] = None
        self.tokens_used = 0
        self._failed = False
        self._error_message: Optional[str] = None

    def __enter__(self):
        self.start_timestamp = self.tracker.record_task_start(
            self.agent_file,
            self.task_id,
            self.model
        )
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is not None:
            self._failed = True
            self._error_message = str(exc_val)
            self.tracker.record_task_failure(
                self.agent_file,
                self.start_timestamp,
                self._error_message,
                self.model,
                self.task_id
            )
        else:
            self.tracker.record_task_complete(
                self.agent_file,
                self.start_timestamp,
                self.tokens_used,
                self.model,
                self.task_id
            )
        return False  # Non suppress exceptions

    def set_tokens_used(self, tokens: int) -> None:
        """Imposta i token usati per questa task."""
        self.tokens_used = tokens

    def set_failed(self, error_message: str) -> None:
        """Marca la task come fallita."""
        self._failed = True
        self._error_message = error_message


# ============ CLI INTERFACE ============

def main():
    """CLI interface per MetricTracker."""
    import argparse

    parser = argparse.ArgumentParser(description="Metric Tracker CLI")
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Report command
    report_parser = subparsers.add_parser("report", help="Generate report")
    report_parser.add_argument("-o", "--output", help="Output file")
    report_parser.add_argument("--format", choices=["markdown", "json"],
                              default="markdown", help="Output format")

    # Leaderboard command
    lb_parser = subparsers.add_parser("leaderboard", help="Show leaderboard")
    lb_parser.add_argument("-m", "--metric", default="tasks_total",
                          help="Metric to sort by")
    lb_parser.add_argument("-n", "--top", type=int, default=10,
                          help="Number of entries")

    # Agent metrics command
    agent_parser = subparsers.add_parser("agent", help="Show agent metrics")
    agent_parser.add_argument("agent_file", help="Agent file path")

    # Token summary command
    subparsers.add_parser("tokens", help="Show token summary")

    # Health check command
    health_parser = subparsers.add_parser("health", help="Check agent health")
    health_parser.add_argument("agent_file", help="Agent file path")

    # Reset command
    reset_parser = subparsers.add_parser("reset", help="Reset agent failures")
    reset_parser.add_argument("agent_file", help="Agent file path")

    args = parser.parse_args()
    tracker = MetricTracker()

    if args.command == "report":
        if args.format == "json":
            print(json.dumps(tracker._data, indent=2))
        else:
            output = Path(args.output) if args.output else None
            print(tracker.generate_report(output))

    elif args.command == "leaderboard":
        leaderboard = tracker.get_leaderboard(args.metric, args.top)
        print(f"\n# Leaderboard: {args.metric}\n")
        for i, entry in enumerate(leaderboard, 1):
            print(f"{i}. {entry['agent_name']}: {entry[args.metric]}")

    elif args.command == "agent":
        metrics = tracker.get_agent_metrics(args.agent_file)
        print(json.dumps(metrics, indent=2))

    elif args.command == "tokens":
        summary = tracker.get_token_summary()
        print("\n# Token Summary\n")
        for model, data in summary.items():
            print(f"{model.title()}: {data['total']:,} tokens "
                  f"({data['count']} tasks, avg {data['avg']:,}/task)")

    elif args.command == "health":
        is_healthy = tracker.check_agent_health(args.agent_file)
        status = "HEALTHY" if is_healthy else "UNHEALTHY"
        print(f"{args.agent_file}: {status}")

    elif args.command == "reset":
        tracker.reset_agent_failures(args.agent_file)
        print(f"Reset failures for {args.agent_file}")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()

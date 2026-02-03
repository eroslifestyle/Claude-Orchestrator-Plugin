#!/usr/bin/env python3
"""
Agent Router System
Sistema di routing automatico per Expert Agents con fallback intelligente
"""

import json
import os
import sys
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple
import subprocess
import re

class AgentRouter:
    """Router intelligente per Expert Agents con fallback strategies"""

    def __init__(self, config_path: str = None):
        """Inizializza il router con la configurazione"""
        if config_path is None:
            config_path = os.path.expanduser("~/.claude/config/agent-registry.json")

        self.config_path = config_path
        self.config = self._load_config()
        self.logger = self._setup_logging()

    def _load_config(self) -> Dict:
        """Carica la configurazione dell'agent registry"""
        try:
            with open(self.config_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except FileNotFoundError:
            raise FileNotFoundError(f"File di configurazione non trovato: {self.config_path}")
        except json.JSONDecodeError as e:
            raise ValueError(f"Errore nel parsing JSON: {e}")

    def _setup_logging(self) -> logging.Logger:
        """Setup del sistema di logging"""
        log_path = os.path.expanduser("~/.claude/config/agent-router.log")

        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_path),
                logging.StreamHandler()
            ]
        )

        return logging.getLogger(__name__)

    def route_request(self, keywords: List[str], priority: str = "normal") -> List[str]:
        """
        Router principale per determinare quale agent utilizzare

        Args:
            keywords: Lista di keywords per il routing
            priority: Livello di priorità della richiesta

        Returns:
            Lista ordinata di agent IDs da utilizzare
        """
        self.logger.info(f"Routing request con keywords: {keywords}, priority: {priority}")

        # 1. Trova agent basati su keyword matching
        matched_agents = self._match_keywords(keywords)

        # 2. Applica priority routing se necessario
        if priority in ["critical", "high"]:
            priority_agents = self._get_priority_agents(keywords)
            matched_agents = priority_agents + [a for a in matched_agents if a not in priority_agents]

        # 3. Verifica disponibilità e applica fallback se necessario
        available_agents = self._filter_available_agents(matched_agents)

        # 4. Ordina per priority level
        final_agents = self._sort_by_priority(available_agents)

        self.logger.info(f"Agenti selezionati: {final_agents}")
        return final_agents

    def _match_keywords(self, keywords: List[str]) -> List[str]:
        """Trova agent basati su keyword matching"""
        matched_agents = set()

        # Converti keywords in lowercase per matching case-insensitive
        keywords_lower = [k.lower() for k in keywords]

        for agent_id, agent_data in self.config["agents"].items():
            agent_keywords = [k.lower() for k in agent_data.get("keywords", [])]

            # Calcola score di matching
            score = 0
            for keyword in keywords_lower:
                for agent_keyword in agent_keywords:
                    if keyword in agent_keyword or agent_keyword in keyword:
                        score += 1
                    elif self._fuzzy_match(keyword, agent_keyword):
                        score += 0.5

            # Aggiungi agent se ha almeno un match
            if score > 0:
                matched_agents.add(agent_id)

        return list(matched_agents)

    def _fuzzy_match(self, word1: str, word2: str, threshold: float = 0.7) -> bool:
        """Fuzzy matching semplificato per keywords simili"""
        if len(word1) < 3 or len(word2) < 3:
            return False

        # Calcola similarità basata su substring comune
        common_chars = set(word1) & set(word2)
        similarity = len(common_chars) / max(len(set(word1)), len(set(word2)))

        return similarity >= threshold

    def _get_priority_agents(self, keywords: List[str]) -> List[str]:
        """Ottiene agent prioritari per richieste critiche"""
        priority_routing = self.config.get("routing", {}).get("priority_routing", {})

        for category, agent_list in priority_routing.items():
            for keyword in keywords:
                if keyword.lower() in category.lower() or category.lower() in keyword.lower():
                    return agent_list

        return []

    def _filter_available_agents(self, agent_ids: List[str]) -> List[str]:
        """Filtra agent disponibili e applica fallback se necessario"""
        available_agents = []

        for agent_id in agent_ids:
            if self._is_agent_available(agent_id):
                available_agents.append(agent_id)
            else:
                # Applica fallback strategy
                fallback_agents = self._get_fallback_agents(agent_id)
                for fallback in fallback_agents:
                    if self._is_agent_available(fallback) and fallback not in available_agents:
                        available_agents.append(fallback)
                        self.logger.warning(f"Utilizzando fallback {fallback} per {agent_id}")
                        break

        return available_agents

    def _is_agent_available(self, agent_id: str) -> bool:
        """Verifica se un agent è disponibile"""
        try:
            agent_data = self.config["agents"][agent_id]
            status = agent_data.get("availability", {}).get("status", "unknown")

            # Agent sempre disponibili
            if status in ["active", "always_available"]:
                # Verifica anche che il file esista
                file_path = os.path.expanduser(agent_data["file_path"])
                return os.path.exists(file_path)

            # Agent on-demand (solo per richieste specifiche)
            elif status == "on_demand":
                activation_condition = agent_data.get("availability", {}).get("activation_condition")
                # TODO: Implementare logica per condizioni di attivazione
                return True

            return False

        except KeyError:
            self.logger.error(f"Agent {agent_id} non trovato nella configurazione")
            return False

    def _get_fallback_agents(self, agent_id: str) -> List[str]:
        """Ottiene la lista di fallback per un agent"""
        fallback_rules = self.config.get("fallback_strategies", {}).get("cascading_rules", {})

        if agent_id not in fallback_rules:
            # Fallback di emergenza
            emergency = self.config.get("fallback_strategies", {}).get("emergency_fallback", {}).get("agent")
            return [emergency] if emergency else []

        fallbacks = []
        rule = fallback_rules[agent_id]

        primary = rule.get("primary_fallback")
        if primary:
            fallbacks.append(primary)

        secondary = rule.get("secondary_fallback")
        if secondary:
            fallbacks.append(secondary)

        return fallbacks

    def _sort_by_priority(self, agent_ids: List[str]) -> List[str]:
        """Ordina agent per priority level (più alto = più prioritario)"""
        def get_priority(agent_id: str) -> int:
            return self.config["agents"].get(agent_id, {}).get("priority_level", 0)

        return sorted(agent_ids, key=get_priority, reverse=True)

    def get_agent_capabilities(self, agent_id: str) -> List[str]:
        """Ottiene le capabilities di un agent specifico"""
        return self.config["agents"].get(agent_id, {}).get("capabilities", [])

    def find_agents_by_capability(self, capability: str) -> List[str]:
        """Trova agent che hanno una specifica capability"""
        matching_agents = []

        for agent_id, agent_data in self.config["agents"].items():
            capabilities = agent_data.get("capabilities", [])
            if capability.lower() in [c.lower() for c in capabilities]:
                matching_agents.append(agent_id)

        return self._sort_by_priority(matching_agents)

    def get_collaboration_pattern(self, pattern_name: str) -> List[str]:
        """Ottiene pattern di collaborazione predefiniti"""
        patterns = self.config.get("orchestration", {}).get("collaboration_patterns", {})
        return patterns.get(pattern_name, [])

    def run_health_check(self) -> Dict[str, str]:
        """Esegue health check di tutti gli agent"""
        results = {}

        for agent_id in self.config["agents"]:
            if self._is_agent_available(agent_id):
                results[agent_id] = "healthy"
            else:
                results[agent_id] = "unhealthy"

        self.logger.info(f"Health check completato: {results}")
        return results

    def get_routing_statistics(self) -> Dict:
        """Ottiene statistiche di routing"""
        total_agents = len(self.config["agents"])
        active_agents = sum(1 for agent in self.config["agents"].values()
                          if agent.get("status") == "active")

        return {
            "total_agents": total_agents,
            "active_agents": active_agents,
            "fallback_rules": len(self.config.get("fallback_strategies", {}).get("cascading_rules", {})),
            "collaboration_patterns": len(self.config.get("orchestration", {}).get("collaboration_patterns", {}))
        }


def main():
    """Funzione principale per utilizzo da command line"""
    import argparse

    parser = argparse.ArgumentParser(description="Agent Router System")
    parser.add_argument("action", choices=["route", "health", "stats", "capability", "pattern"],
                       help="Azione da eseguire")
    parser.add_argument("--keywords", "-k", nargs="+", help="Keywords per il routing")
    parser.add_argument("--priority", "-p", choices=["low", "normal", "high", "critical"],
                       default="normal", help="Priorità della richiesta")
    parser.add_argument("--capability", "-c", help="Capability da cercare")
    parser.add_argument("--pattern", help="Nome del pattern di collaborazione")
    parser.add_argument("--config", help="Path al file di configurazione")

    args = parser.parse_args()

    try:
        router = AgentRouter(args.config)

        if args.action == "route":
            if not args.keywords:
                print("Errore: Keywords richieste per il routing")
                sys.exit(1)

            agents = router.route_request(args.keywords, args.priority)
            print(f"Agenti consigliati: {', '.join(agents)}")

        elif args.action == "health":
            results = router.run_health_check()
            print("Stato health check:")
            for agent_id, status in results.items():
                status_symbol = "[OK]" if status == "healthy" else "[FAIL]"
                print(f"  {status_symbol} {agent_id}: {status}")

        elif args.action == "stats":
            stats = router.get_routing_statistics()
            print("Statistiche routing:")
            for key, value in stats.items():
                print(f"  {key}: {value}")

        elif args.action == "capability":
            if not args.capability:
                print("Errore: Capability richiesta")
                sys.exit(1)

            agents = router.find_agents_by_capability(args.capability)
            print(f"Agenti con capability '{args.capability}': {', '.join(agents)}")

        elif args.action == "pattern":
            if not args.pattern:
                print("Errore: Nome pattern richiesto")
                sys.exit(1)

            agents = router.get_collaboration_pattern(args.pattern)
            print(f"Pattern '{args.pattern}': {', '.join(agents)}")

    except Exception as e:
        print(f"Errore: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
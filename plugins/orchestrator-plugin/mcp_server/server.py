#!/usr/bin/env python3
"""
ORCHESTRATOR MCP SERVER v6.0
=============================

Model Context Protocol server for Claude Code Orchestrator Plugin.
Provides automatic orchestration capabilities - ALWAYS ON, like Serena.

This server exposes orchestrator tools that are automatically available
in every Claude Code session without requiring explicit activation.

Author: LeoDg
Version: 6.0.0
Total Agents: 36 (6 Core + 15 L1 Expert + 15 L2 Sub-Agent)
"""

import asyncio
import json
import logging
import os
import re
import sys
import uuid
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional, Sequence
from dataclasses import dataclass, asdict
from pathlib import Path

# ProcessManager import - Windows process lifecycle management
# Add lib directory to path for ProcessManager import
_LIB_DIR = Path(__file__).parent.parent.parent.parent / "lib"
if str(_LIB_DIR) not in sys.path:
    sys.path.insert(0, str(_LIB_DIR))

try:
    from process_manager import ProcessManager, ProcessManagerError, health_check as pm_health_check
    PROCESS_MANAGER_AVAILABLE = True
except ImportError:
    PROCESS_MANAGER_AVAILABLE = False
    ProcessManager = None  # type: ignore

# MCP imports
from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Tool,
    TextContent,
    ImageContent,
    EmbeddedResource,
    LoggingLevel
)

# =============================================================================
# CONFIGURATION
# =============================================================================

PLUGIN_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(PLUGIN_DIR, "config")
DATA_DIR = os.path.join(PLUGIN_DIR, "data")
AGENTS_REGISTRY = os.path.join(CONFIG_DIR, "agent-registry.json")
KEYWORD_MAPPINGS = os.path.join(CONFIG_DIR, "keyword-mappings.json")
SESSIONS_FILE = os.path.join(DATA_DIR, "sessions.json")

# Ensure data directory exists
os.makedirs(DATA_DIR, exist_ok=True)

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("orchestrator-mcp")

# =============================================================================
# FIX #4: CENTRALIZED KEYWORD LOADER - Load from JSON config
# =============================================================================

def load_keyword_mappings_from_json() -> Dict[str, Dict[str, Any]]:
    """
    FIX #4: Load keyword mappings from centralized JSON config file.
    Falls back to empty dict if file not found.
    """
    try:
        if os.path.exists(KEYWORD_MAPPINGS):
            with open(KEYWORD_MAPPINGS, 'r', encoding='utf-8') as f:
                data = json.load(f)
                logger.info(f"Loaded keyword mappings from {KEYWORD_MAPPINGS}")
                return data
        else:
            logger.warning(f"Keyword mappings file not found: {KEYWORD_MAPPINGS}")
    except Exception as e:
        logger.error(f"Error loading keyword mappings: {e}")
    return {}

def build_keyword_expert_map(mappings_data: Dict[str, Any]) -> Dict[str, str]:
    """
    FIX #4: Build keyword->expert_file mapping from JSON structure.
    Supports both domain_mappings and core_functions sections.
    """
    keyword_map = {}

    # Process domain_mappings
    domain_mappings = mappings_data.get('domain_mappings', {})
    for domain_name, domain_config in domain_mappings.items():
        expert_file = f"experts/{domain_config.get('primary_agent', 'coder')}.md"
        keywords = domain_config.get('keywords', [])
        for kw in keywords:
            keyword_map[kw.lower()] = expert_file

    # Process core_functions
    core_functions = mappings_data.get('core_functions', {})
    for func_name, func_config in core_functions.items():
        expert_file = f"core/{func_config.get('primary_agent', 'coder')}.md"
        keywords = func_config.get('keywords', [])
        for kw in keywords:
            keyword_map[kw.lower()] = expert_file

    return keyword_map

def build_expert_model_map(mappings_data: Dict[str, Any]) -> Dict[str, str]:
    """
    FIX #4: Build expert_file->model mapping from JSON structure.
    """
    model_map = {}

    for section in ['domain_mappings', 'core_functions']:
        section_data = mappings_data.get(section, {})
        for name, config in section_data.items():
            prefix = 'experts' if section == 'domain_mappings' else 'core'
            expert_file = f"{prefix}/{config.get('primary_agent', 'coder')}.md"
            model_map[expert_file] = config.get('model', 'sonnet')

    return model_map

def build_expert_priority_map(mappings_data: Dict[str, Any]) -> Dict[str, str]:
    """
    FIX #4: Build expert_file->priority mapping from JSON structure.
    """
    priority_map = {}

    for section in ['domain_mappings', 'core_functions']:
        section_data = mappings_data.get(section, {})
        for name, config in section_data.items():
            prefix = 'experts' if section == 'domain_mappings' else 'core'
            expert_file = f"{prefix}/{config.get('primary_agent', 'coder')}.md"
            priority_map[expert_file] = config.get('priority', 'MEDIA')

    return priority_map

# Load centralized mappings at startup
_LOADED_MAPPINGS = load_keyword_mappings_from_json()
_KEYWORD_MAP_FROM_JSON = build_keyword_expert_map(_LOADED_MAPPINGS)
_MODEL_MAP_FROM_JSON = build_expert_model_map(_LOADED_MAPPINGS)
_PRIORITY_MAP_FROM_JSON = build_expert_priority_map(_LOADED_MAPPINGS)

logger.info(f"Loaded {len(_KEYWORD_MAP_FROM_JSON)} keywords from centralized config")

# =============================================================================
# TYPES & ENUMS
# =============================================================================

class ModelType(str, Enum):
    HAIKU = "haiku"
    SONNET = "sonnet"
    OPUS = "opus"
    AUTO = "auto"

class TaskPriority(str, Enum):
    CRITICAL = "CRITICA"
    HIGH = "ALTA"
    MEDIUM = "MEDIA"
    LOW = "BASSA"

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class TaskDocumentation:
    """FIX #11: Documentation entry for each task - lean, essential, clear"""
    task_id: str
    what_done: str          # Cosa è stato fatto (1 riga)
    what_not_to_do: str     # Cosa NON fare (evita loop errori)
    files_changed: List[str] # File modificati
    status: str             # success/partial/failed

@dataclass
class AgentTask:
    """Single agent task definition"""
    id: str
    description: str
    agent_expert_file: str
    model: str
    specialization: str
    dependencies: List[str]
    priority: str
    level: int
    estimated_time: float
    estimated_cost: float
    requires_doc: bool = True      # FIX #11: Every task requires documentation
    requires_cleanup: bool = True  # FIX #12: Every task MUST cleanup temp files

@dataclass
class ExecutionPlan:
    """Complete execution plan for orchestration"""
    session_id: str
    tasks: List[AgentTask]
    parallel_batches: List[List[str]]
    total_agents: int
    estimated_time: float
    estimated_cost: float
    complexity: str
    domains: List[str]

@dataclass
class OrchestrationSession:
    """Active orchestration session"""
    session_id: str
    user_request: str
    status: TaskStatus
    plan: Optional[ExecutionPlan]
    started_at: datetime
    completed_at: Optional[datetime]
    results: List[Dict[str, Any]]
    task_docs: List[TaskDocumentation] = None  # FIX #11: Per-task documentation log

    def __post_init__(self):
        if self.task_docs is None:
            self.task_docs = []

# =============================================================================
# KEYWORD MAPPINGS (from orchestrator-core.ts)
# =============================================================================

KEYWORD_TO_EXPERT_MAPPING = {
    # ========== L0 CORE (6) ==========
    'cerca': 'core/analyzer.md',
    'trova': 'core/analyzer.md',
    'esplora': 'core/analyzer.md',
    'analizza': 'core/analyzer.md',
    'search': 'core/analyzer.md',

    'implementa': 'core/coder.md',
    'feature': 'core/coder.md',
    'codifica': 'core/coder.md',
    'develop': 'core/coder.md',

    'review': 'core/reviewer.md',
    'valida': 'core/reviewer.md',
    'quality': 'core/reviewer.md',

    'documenta': 'core/documenter.md',
    'docs': 'core/documenter.md',
    'readme': 'core/documenter.md',

    'token': 'core/system_coordinator.md',
    'resource': 'core/system_coordinator.md',
    'spawn': 'core/system_coordinator.md',

    # ========== L1 EXPERTS (15) ==========
    # GUI Domain
    'gui': 'experts/gui-super-expert.md',
    'pyqt5': 'experts/gui-super-expert.md',
    'qt': 'experts/gui-super-expert.md',
    'tab': 'experts/gui-super-expert.md',
    'widget': 'experts/gui-super-expert.md',
    'dialog': 'experts/gui-super-expert.md',
    'layout': 'experts/gui-super-expert.md',
    'ui': 'experts/gui-super-expert.md',
    'interface': 'experts/gui-super-expert.md',

    # Database Domain
    'database': 'experts/database_expert.md',
    'sql': 'experts/database_expert.md',
    'sqlite': 'experts/database_expert.md',
    'postgresql': 'experts/database_expert.md',
    'query': 'experts/database_expert.md',
    'schema': 'experts/database_expert.md',
    'migration': 'experts/database_expert.md',

    # Security Domain
    'security': 'experts/security_unified_expert.md',
    'auth': 'experts/security_unified_expert.md',
    'authentication': 'experts/security_unified_expert.md',
    'encryption': 'experts/security_unified_expert.md',
    'jwt': 'experts/security_unified_expert.md',
    'password': 'experts/security_unified_expert.md',
    'owasp': 'experts/security_unified_expert.md',

    # API Integration
    'api': 'experts/integration_expert.md',
    'telegram': 'experts/integration_expert.md',
    'ctrader': 'experts/integration_expert.md',
    'rest': 'experts/integration_expert.md',
    'webhook': 'experts/integration_expert.md',
    'integration': 'experts/integration_expert.md',

    # MQL Domain
    'mql': 'experts/mql_expert.md',
    'mql5': 'experts/mql_expert.md',
    'mql4': 'experts/mql_expert.md',
    'ea': 'experts/mql_expert.md',
    'metatrader': 'experts/mql_expert.md',
    'expert advisor': 'experts/mql_expert.md',

    # Trading Domain
    'trading': 'experts/trading_strategy_expert.md',
    'risk': 'experts/trading_strategy_expert.md',
    'position': 'experts/trading_strategy_expert.md',
    'tp': 'experts/trading_strategy_expert.md',
    'sl': 'experts/trading_strategy_expert.md',
    'drawdown': 'experts/trading_strategy_expert.md',

    # Architecture Domain
    'architettura': 'experts/architect_expert.md',
    'architecture': 'experts/architect_expert.md',
    'design pattern': 'experts/architect_expert.md',
    'refactor': 'experts/architect_expert.md',
    'microservizi': 'experts/architect_expert.md',

    # Testing & Debug
    'test': 'experts/tester_expert.md',
    'debug': 'experts/tester_expert.md',
    'bug': 'experts/tester_expert.md',
    'qa': 'experts/tester_expert.md',
    'performance': 'experts/tester_expert.md',

    # DevOps
    'devops': 'experts/devops_expert.md',
    'deploy': 'experts/devops_expert.md',
    'docker': 'experts/devops_expert.md',
    'ci/cd': 'experts/devops_expert.md',
    'kubernetes': 'experts/devops_expert.md',

    # Languages
    'python': 'experts/languages_expert.md',
    'javascript': 'experts/languages_expert.md',
    'c#': 'experts/languages_expert.md',
    'coding': 'experts/languages_expert.md',
    'typescript': 'experts/languages_expert.md',

    # AI Integration (NEW)
    'ai': 'experts/ai_integration_expert.md',
    'llm': 'experts/ai_integration_expert.md',
    'gpt': 'experts/ai_integration_expert.md',
    'openai': 'experts/ai_integration_expert.md',
    'model selection': 'experts/ai_integration_expert.md',
    'rag': 'experts/ai_integration_expert.md',

    # Claude Systems (NEW)
    'claude': 'experts/claude_systems_expert.md',
    'anthropic': 'experts/claude_systems_expert.md',
    'haiku': 'experts/claude_systems_expert.md',
    'sonnet': 'experts/claude_systems_expert.md',
    'opus': 'experts/claude_systems_expert.md',

    # Mobile (NEW)
    'mobile': 'experts/mobile_expert.md',
    'ios': 'experts/mobile_expert.md',
    'android': 'experts/mobile_expert.md',
    'swift': 'experts/mobile_expert.md',
    'kotlin': 'experts/mobile_expert.md',
    'flutter': 'experts/mobile_expert.md',
    'react native': 'experts/mobile_expert.md',

    # N8N Automation (NEW)
    'n8n': 'experts/n8n_expert.md',
    'automation': 'experts/n8n_expert.md',
    'workflow': 'experts/n8n_expert.md',
    'zapier': 'experts/n8n_expert.md',
    'make': 'experts/n8n_expert.md',

    # Social Identity (NEW)
    'oauth': 'experts/social_identity_expert.md',
    'oidc': 'experts/social_identity_expert.md',
    'social login': 'experts/social_identity_expert.md',
    'google login': 'experts/social_identity_expert.md',
    'facebook login': 'experts/social_identity_expert.md',
    'apple sign': 'experts/social_identity_expert.md',

    # ========== L2 SUB-AGENTS (15) ==========
    'gui layout': 'experts/L2/gui-layout-specialist.md',
    'sidebar': 'experts/L2/gui-layout-specialist.md',
    'form': 'experts/L2/gui-layout-specialist.md',
    'grid': 'experts/L2/gui-layout-specialist.md',
    'dashboard': 'experts/L2/gui-layout-specialist.md',

    'query optimization': 'experts/L2/db-query-optimizer.md',
    'index': 'experts/L2/db-query-optimizer.md',
    'n+1': 'experts/L2/db-query-optimizer.md',
    'pagination': 'experts/L2/db-query-optimizer.md',

    'endpoint': 'experts/L2/api-endpoint-builder.md',
    'crud': 'experts/L2/api-endpoint-builder.md',
    'rate limit': 'experts/L2/api-endpoint-builder.md',
    'versioning': 'experts/L2/api-endpoint-builder.md',

    'mfa': 'experts/L2/security-auth-specialist.md',
    'totp': 'experts/L2/security-auth-specialist.md',
    'rbac': 'experts/L2/security-auth-specialist.md',
    'brute force': 'experts/L2/security-auth-specialist.md',

    'position sizing': 'experts/L2/trading-risk-calculator.md',
    'kelly': 'experts/L2/trading-risk-calculator.md',
    'r:r': 'experts/L2/trading-risk-calculator.md',

    'ea optimization': 'experts/L2/mql-optimization.md',
    'tick processing': 'experts/L2/mql-optimization.md',
    'memory mql': 'experts/L2/mql-optimization.md',

    'pytest': 'experts/L2/test-unit-specialist.md',
    'mocking': 'experts/L2/test-unit-specialist.md',
    'fixtures': 'experts/L2/test-unit-specialist.md',
    'tdd': 'experts/L2/test-unit-specialist.md',
    'coverage': 'experts/L2/test-unit-specialist.md',

    'flutter layout': 'experts/L2/mobile-ui-specialist.md',
    'responsive': 'experts/L2/mobile-ui-specialist.md',
    'safearea': 'experts/L2/mobile-ui-specialist.md',

    'refactoring': 'experts/L2/languages-refactor-specialist.md',
    'code smell': 'experts/L2/languages-refactor-specialist.md',
    'clean code': 'experts/L2/languages-refactor-specialist.md',

    'solid': 'experts/L2/architect-design-specialist.md',
    'ddd': 'experts/L2/architect-design-specialist.md',
    'design patterns': 'experts/L2/architect-design-specialist.md',

    'pipeline': 'experts/L2/devops-pipeline-specialist.md',
    'github actions': 'experts/L2/devops-pipeline-specialist.md',
    'docker build': 'experts/L2/devops-pipeline-specialist.md',

    'workflow design': 'experts/L2/n8n-workflow-builder.md',
    'error handling n8n': 'experts/L2/n8n-workflow-builder.md',
    'batch processing': 'experts/L2/n8n-workflow-builder.md',

    'fine-tuning': 'experts/L2/ai-model-specialist.md',
    'rag optimization': 'experts/L2/ai-model-specialist.md',
    'embeddings': 'experts/L2/ai-model-specialist.md',

    'prompt engineering': 'experts/L2/claude-prompt-optimizer.md',
    'token optimization': 'experts/L2/claude-prompt-optimizer.md',
    'few-shot': 'experts/L2/claude-prompt-optimizer.md',

    'oauth2 flow': 'experts/L2/social-oauth-specialist.md',
    'pkce': 'experts/L2/social-oauth-specialist.md',
    'provider integration': 'experts/L2/social-oauth-specialist.md',
}

EXPERT_TO_MODEL_MAPPING = {
    # L0 Core (6)
    'core/orchestrator.md': 'opus',
    'core/analyzer.md': 'haiku',
    'core/coder.md': 'sonnet',
    'core/reviewer.md': 'sonnet',
    'core/documenter.md': 'haiku',
    'core/system_coordinator.md': 'haiku',
    # L1 Experts (15)
    'experts/gui-super-expert.md': 'sonnet',
    'experts/database_expert.md': 'sonnet',
    'experts/security_unified_expert.md': 'sonnet',
    'experts/integration_expert.md': 'sonnet',
    'experts/mql_expert.md': 'sonnet',
    'experts/trading_strategy_expert.md': 'sonnet',
    'experts/architect_expert.md': 'opus',
    'experts/tester_expert.md': 'sonnet',
    'experts/devops_expert.md': 'haiku',
    'experts/languages_expert.md': 'sonnet',
    'experts/ai_integration_expert.md': 'sonnet',
    'experts/claude_systems_expert.md': 'sonnet',
    'experts/mobile_expert.md': 'sonnet',
    'experts/n8n_expert.md': 'sonnet',
    'experts/social_identity_expert.md': 'sonnet',
    # L2 Sub-Agents (15)
    'experts/L2/gui-layout-specialist.md': 'sonnet',
    'experts/L2/db-query-optimizer.md': 'sonnet',
    'experts/L2/api-endpoint-builder.md': 'sonnet',
    'experts/L2/security-auth-specialist.md': 'sonnet',
    'experts/L2/trading-risk-calculator.md': 'sonnet',
    'experts/L2/mql-optimization.md': 'sonnet',
    'experts/L2/test-unit-specialist.md': 'sonnet',
    'experts/L2/mobile-ui-specialist.md': 'sonnet',
    'experts/L2/languages-refactor-specialist.md': 'sonnet',
    'experts/L2/architect-design-specialist.md': 'sonnet',
    'experts/L2/devops-pipeline-specialist.md': 'sonnet',
    'experts/L2/n8n-workflow-builder.md': 'sonnet',
    'experts/L2/ai-model-specialist.md': 'sonnet',
    'experts/L2/claude-prompt-optimizer.md': 'sonnet',
    'experts/L2/social-oauth-specialist.md': 'sonnet',
}

EXPERT_TO_PRIORITY_MAPPING = {
    # CRITICA
    'experts/security_unified_expert.md': 'CRITICA',
    'core/documenter.md': 'CRITICA',
    'core/orchestrator.md': 'CRITICA',
    # ALTA - L0/L1
    'experts/gui-super-expert.md': 'ALTA',
    'experts/database_expert.md': 'ALTA',
    'experts/integration_expert.md': 'ALTA',
    'experts/mql_expert.md': 'ALTA',
    'experts/architect_expert.md': 'ALTA',
    'experts/tester_expert.md': 'ALTA',
    'experts/trading_strategy_expert.md': 'ALTA',
    'experts/ai_integration_expert.md': 'ALTA',
    'experts/claude_systems_expert.md': 'ALTA',
    'experts/mobile_expert.md': 'ALTA',
    'experts/n8n_expert.md': 'ALTA',
    'experts/social_identity_expert.md': 'ALTA',
    'core/analyzer.md': 'ALTA',
    # MEDIA
    'core/coder.md': 'MEDIA',
    'core/reviewer.md': 'MEDIA',
    'core/system_coordinator.md': 'MEDIA',
    'experts/devops_expert.md': 'MEDIA',
    'experts/languages_expert.md': 'MEDIA',
    # L2 Sub-Agents (all MEDIA)
    'experts/L2/gui-layout-specialist.md': 'MEDIA',
    'experts/L2/db-query-optimizer.md': 'MEDIA',
    'experts/L2/api-endpoint-builder.md': 'MEDIA',
    'experts/L2/security-auth-specialist.md': 'ALTA',
    'experts/L2/trading-risk-calculator.md': 'MEDIA',
    'experts/L2/mql-optimization.md': 'MEDIA',
    'experts/L2/test-unit-specialist.md': 'MEDIA',
    'experts/L2/mobile-ui-specialist.md': 'MEDIA',
    'experts/L2/languages-refactor-specialist.md': 'MEDIA',
    'experts/L2/architect-design-specialist.md': 'MEDIA',
    'experts/L2/devops-pipeline-specialist.md': 'MEDIA',
    'experts/L2/n8n-workflow-builder.md': 'MEDIA',
    'experts/L2/ai-model-specialist.md': 'MEDIA',
    'experts/L2/claude-prompt-optimizer.md': 'MEDIA',
    'experts/L2/social-oauth-specialist.md': 'MEDIA',
}

# =============================================================================
# FIX #4: MERGE JSON MAPPINGS - JSON takes precedence over hardcoded
# =============================================================================

# Merge JSON-loaded mappings into hardcoded ones (JSON wins on conflicts)
if _KEYWORD_MAP_FROM_JSON:
    KEYWORD_TO_EXPERT_MAPPING.update(_KEYWORD_MAP_FROM_JSON)
    logger.info(f"Merged {len(_KEYWORD_MAP_FROM_JSON)} keywords from JSON config")

if _MODEL_MAP_FROM_JSON:
    EXPERT_TO_MODEL_MAPPING.update(_MODEL_MAP_FROM_JSON)
    logger.info(f"Merged {len(_MODEL_MAP_FROM_JSON)} model mappings from JSON config")

if _PRIORITY_MAP_FROM_JSON:
    EXPERT_TO_PRIORITY_MAPPING.update(_PRIORITY_MAP_FROM_JSON)
    logger.info(f"Merged {len(_PRIORITY_MAP_FROM_JSON)} priority mappings from JSON config")

# =============================================================================

SPECIALIZATION_DESCRIPTIONS = {
    # L0 Core (6)
    'core/orchestrator.md': 'Central coordinator, multi-agent orchestration',
    'core/analyzer.md': 'Analisi codice, ricerca, esplorazione',
    'core/coder.md': 'Coding generale, implementazione feature',
    'core/reviewer.md': 'Code review, validazione, quality check',
    'core/documenter.md': 'Documentation, technical writing, README',
    'core/system_coordinator.md': 'Token tracking, resource management',
    # L1 Experts (15)
    'experts/gui-super-expert.md': 'PyQt5, Qt, UI, Widget, Tab, Dialog, Layout',
    'experts/database_expert.md': 'SQLite, PostgreSQL, Schema, Query, Migration',
    'experts/security_unified_expert.md': 'Security, Encryption, Auth, JWT, OWASP',
    'experts/integration_expert.md': 'API, Telegram, cTrader, REST, Webhook',
    'experts/mql_expert.md': 'MQL5, MQL4, MetaTrader, EA, OnTimer',
    'experts/trading_strategy_expert.md': 'Trading, Risk Management, Position Sizing, TP/SL',
    'experts/architect_expert.md': 'Architettura, Design Pattern, Microservizi, C4',
    'experts/tester_expert.md': 'Testing, QA, Debug, Performance, Memory',
    'experts/devops_expert.md': 'DevOps, CI/CD, Deploy, Docker, Kubernetes',
    'experts/languages_expert.md': 'Python, JavaScript, C#, TypeScript, Multi-language',
    'experts/ai_integration_expert.md': 'AI Integration, LLM APIs, RAG, Model Selection',
    'experts/claude_systems_expert.md': 'Claude Ecosystem, Haiku/Sonnet/Opus, Cost Optimization',
    'experts/mobile_expert.md': 'iOS, Android, Swift, Kotlin, Flutter, React Native',
    'experts/n8n_expert.md': 'N8N, Workflow Automation, Zapier, Make, Process Integration',
    'experts/social_identity_expert.md': 'OAuth2, OIDC, Social Login, Google, Facebook, Apple',
    # L2 Sub-Agents (15)
    'experts/L2/gui-layout-specialist.md': 'Qt Layout, Sidebar, Form, Grid, Dashboard',
    'experts/L2/db-query-optimizer.md': 'Query Optimization, Index, N+1, Pagination',
    'experts/L2/api-endpoint-builder.md': 'REST Endpoints, CRUD, Rate Limiting, Versioning',
    'experts/L2/security-auth-specialist.md': 'JWT, MFA, TOTP, RBAC, Brute Force Protection',
    'experts/L2/trading-risk-calculator.md': 'Position Sizing, Kelly Criterion, Drawdown, R:R',
    'experts/L2/mql-optimization.md': 'EA Performance, Memory, Tick Processing, Cache',
    'experts/L2/test-unit-specialist.md': 'pytest, Mocking, Fixtures, Coverage, TDD',
    'experts/L2/mobile-ui-specialist.md': 'Flutter Layout, React Native, Responsive, SafeArea',
    'experts/L2/languages-refactor-specialist.md': 'Refactoring Patterns, Code Smells, Clean Code',
    'experts/L2/architect-design-specialist.md': 'Design Patterns, SOLID, DDD, Microservices',
    'experts/L2/devops-pipeline-specialist.md': 'CI/CD Pipelines, GitHub Actions, Docker Builds',
    'experts/L2/n8n-workflow-builder.md': 'Workflow Design, Error Handling, Batch Processing',
    'experts/L2/ai-model-specialist.md': 'Model Selection, Fine-tuning, RAG Optimization',
    'experts/L2/claude-prompt-optimizer.md': 'Prompt Engineering, Token Optimization, Few-shot',
    'experts/L2/social-oauth-specialist.md': 'OAuth2 Flows, PKCE, Provider Integration',
}

# =============================================================================
# ORCHESTRATOR ENGINE
# =============================================================================

class OrchestratorEngine:
    """Core orchestration engine - ported from TypeScript"""

    def __init__(self):
        self.sessions: Dict[str, OrchestrationSession] = {}
        self._load_sessions()  # FIX #8: Load persisted sessions
        logger.info("Orchestrator Engine initialized")

    # =========================================================================
    # FIX #8: SESSION PERSISTENCE
    # =========================================================================

    def _load_sessions(self) -> None:
        """Load sessions from persistent storage"""
        try:
            if os.path.exists(SESSIONS_FILE):
                with open(SESSIONS_FILE, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    logger.info(f"Loaded {len(data)} sessions from {SESSIONS_FILE}")
                    # Sessions are stored as simplified dicts, not full objects
        except Exception as e:
            logger.warning(f"Could not load sessions: {e}")

    def _save_sessions(self) -> None:
        """Save sessions to persistent storage"""
        try:
            # Keep only last 50 sessions
            sessions_list = list(self.sessions.values())[-50:]
            data = [
                {
                    "session_id": s.session_id,
                    "user_request": s.user_request,
                    "status": s.status.value,
                    "started_at": s.started_at.isoformat(),
                    "completed_at": s.completed_at.isoformat() if s.completed_at else None,
                    "tasks_count": len(s.plan.tasks) if s.plan else 0
                }
                for s in sessions_list
            ]
            with open(SESSIONS_FILE, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            logger.debug(f"Saved {len(data)} sessions to {SESSIONS_FILE}")
        except Exception as e:
            logger.error(f"Could not save sessions: {e}")

    # =========================================================================
    # FIX #7: ESTIMATED TIME FORMULA - Improved with parallelism factor
    # =========================================================================

    def _calculate_estimated_time(self, tasks: List[AgentTask], max_parallel: int = 6) -> float:
        """
        Calculate estimated execution time considering parallelism.
        FIX #7: Better formula with parallel factor.
        """
        if not tasks:
            return 0.0

        work_tasks = [t for t in tasks if "documenter" not in t.agent_expert_file]
        if not work_tasks:
            return sum(t.estimated_time for t in tasks)

        base_time = sum(t.estimated_time for t in work_tasks)
        parallel_factor = 0.6  # 60% efficiency for parallel execution
        overhead = 1.0  # 1 minute orchestration overhead

        # Calculate batches
        batches = max(1, len(work_tasks) // max_parallel + (1 if len(work_tasks) % max_parallel else 0))
        parallel_time = (base_time / len(work_tasks)) * batches * parallel_factor + overhead

        return round(parallel_time, 1)

    # =========================================================================
    # FIX #10: CLEANUP PROCESSES - Terminate orphan processes
    # =========================================================================

    async def cleanup_orphan_processes(self) -> Dict[str, Any]:
        """
        FIX #10: Cleanup orphan Python/Node processes after orchestration.
        Returns dict with cleanup results.

        Uses ProcessManager if available for proper process lifecycle management.
        Falls back to subprocess-based cleanup on non-Windows or if ProcessManager unavailable.
        """
        import subprocess
        import platform

        results = {"cleaned": [], "errors": [], "method": "unknown"}
        is_windows = platform.system() == "Windows"

        # Try ProcessManager first (Windows only, with proper job object support)
        pm = get_process_manager()
        if pm is not None and is_windows:
            try:
                # Get metrics before cleanup
                metrics_before = pm.get_metrics()

                # Terminate all managed processes
                termination_results = pm.terminate_all(timeout=5.0)

                # Report results
                for pid, success in termination_results.items():
                    if success:
                        results["cleaned"].append(f"PID {pid}")
                    else:
                        results["errors"].append(f"PID {pid}: termination failed")

                # Get metrics after cleanup
                metrics_after = pm.get_metrics()
                results["metrics"] = {
                    "before": metrics_before,
                    "after": metrics_after
                }
                results["method"] = "ProcessManager"

                logger.info(f"ProcessManager cleanup completed: {len(results['cleaned'])} cleaned, {len(results['errors'])} errors")
                return results

            except ProcessManagerError as e:
                logger.warning(f"ProcessManager cleanup failed, falling back to subprocess: {e}")
                results["errors"].append(f"ProcessManager: {str(e)}")
            except Exception as e:
                logger.warning(f"Unexpected ProcessManager error, falling back to subprocess: {e}")
                results["errors"].append(f"ProcessManager unexpected: {str(e)}")

        # Fallback: subprocess-based cleanup (original implementation)
        results["method"] = "subprocess"

        if is_windows:
            commands = [
                ("python.exe", "taskkill /F /IM python.exe /FI \"MEMUSAGE gt 100000\" 2>NUL"),
                ("node.exe", "taskkill /F /IM node.exe /FI \"MEMUSAGE gt 100000\" 2>NUL"),
            ]
        else:
            commands = [
                ("python", "pkill -f 'python.*orchestrator' 2>/dev/null || true"),
                ("node", "pkill -f 'node.*orchestrator' 2>/dev/null || true"),
            ]

        for name, cmd in commands:
            try:
                subprocess.run(cmd, shell=True, capture_output=True, timeout=5)
                results["cleaned"].append(name)
            except Exception as e:
                results["errors"].append(f"{name}: {str(e)}")

        logger.info(f"Subprocess cleanup completed: {results}")
        return results

    # =========================================================================
    # FIX #12: CLEANUP TEMP FILES - Mandatory cleanup of *.tmp files
    # =========================================================================

    async def cleanup_temp_files(self, working_dir: str = None) -> Dict[str, Any]:
        """
        FIX #12: MANDATORY cleanup of temporary files after each task/orchestration.
        REGOLA OBBLIGATORIA: Chi crea file temp DEVE eliminarli.

        Patterns cleaned:
        - *.tmp, *.temp, *.bak, *.swp
        - *~, *.pyc, __pycache__
        - .pytest_cache, .mypy_cache
        - node_modules/.cache
        """
        import glob
        import shutil

        if working_dir is None:
            working_dir = os.getcwd()

        results = {
            "deleted_files": [],
            "deleted_dirs": [],
            "errors": [],
            "total_cleaned": 0
        }

        # Temp file patterns to clean
        TEMP_PATTERNS = [
            "**/*.tmp",
            "**/*.temp",
            "**/*.bak",
            "**/*.swp",
            "**/*~",
            "**/*.pyc",
            "**/__pycache__",
            "**/.pytest_cache",
            "**/.mypy_cache",
            "**/node_modules/.cache",
            "**/.DS_Store",
            "**/Thumbs.db"
        ]

        for pattern in TEMP_PATTERNS:
            try:
                full_pattern = os.path.join(working_dir, pattern)
                matches = glob.glob(full_pattern, recursive=True)

                for match in matches:
                    try:
                        if os.path.isfile(match):
                            os.remove(match)
                            results["deleted_files"].append(match)
                            results["total_cleaned"] += 1
                        elif os.path.isdir(match):
                            shutil.rmtree(match)
                            results["deleted_dirs"].append(match)
                            results["total_cleaned"] += 1
                    except Exception as e:
                        results["errors"].append(f"{match}: {str(e)}")
            except Exception as e:
                results["errors"].append(f"Pattern {pattern}: {str(e)}")

        if results["total_cleaned"] > 0:
            logger.info(f"FIX #12: Cleaned {results['total_cleaned']} temp files/dirs")

        return results

    def analyze_request(self, user_request: str) -> Dict[str, Any]:
        """Analyze user request and extract keywords/domains"""
        request_lower = user_request.lower()
        found_keywords = []
        found_domains = set()

        # Keywords that require exact word boundary matching (short/ambiguous keywords)
        # FIX #1: Added 'tab', 'db', 'fix', 'api', 'ci', 'cd' to prevent false positives
        # e.g., 'tab' should NOT match 'da-tab-ase', 'fix' should NOT match 'pre-fix'
        EXACT_MATCH_KEYWORDS = {'ea', 'ai', 'qt', 'ui', 'qa', 'tp', 'sl', 'c#', 'tab', 'db', 'fix', 'api', 'ci', 'cd', 'form'}

        for keyword, expert_file in KEYWORD_TO_EXPERT_MAPPING.items():
            matched = False
            # Use word boundary matching for short/ambiguous keywords
            if keyword in EXACT_MATCH_KEYWORDS:
                # Use regex with word boundaries for exact match
                pattern = r'\b' + re.escape(keyword) + r'\b'
                if re.search(pattern, request_lower):
                    found_keywords.append(keyword)
                    matched = True
            elif keyword in request_lower:
                found_keywords.append(keyword)
                matched = True

            # Add domain detection (FIX: was unreachable after continue)
            if matched:
                if 'gui' in expert_file:
                    found_domains.add('GUI')
                elif 'database' in expert_file:
                    found_domains.add('Database')
                elif 'security' in expert_file:
                    found_domains.add('Security')
                elif 'integration' in expert_file:
                    found_domains.add('API')
                elif 'mql' in expert_file:
                    found_domains.add('MQL')
                elif 'trading' in expert_file:
                    found_domains.add('Trading')
                elif 'architect' in expert_file:
                    found_domains.add('Architecture')
                elif 'tester' in expert_file:
                    found_domains.add('Testing')
                elif 'devops' in expert_file:
                    found_domains.add('DevOps')
                elif 'ai' in expert_file or 'claude' in expert_file:
                    found_domains.add('AI')
                elif 'mobile' in expert_file:
                    found_domains.add('Mobile')

        # FIX #6: Determine complexity with corrected thresholds
        task_count = len(set(KEYWORD_TO_EXPERT_MAPPING.get(k) for k in found_keywords if k in KEYWORD_TO_EXPERT_MAPPING))
        domain_count = len(found_domains)
        word_count = len(user_request.split())

        # FIX #6: 10+ agents = alta, 5+ = media
        if task_count >= 10 or domain_count >= 4:
            complexity = "alta"
        elif task_count >= 5 or domain_count >= 2:
            complexity = "media"
        else:
            complexity = "bassa"

        return {
            "keywords": found_keywords,
            "domains": list(found_domains),
            "complexity": complexity,
            "is_multi_domain": domain_count > 1,
            "word_count": word_count
        }

    def generate_execution_plan(self, user_request: str) -> ExecutionPlan:
        """Generate complete execution plan for orchestration"""
        session_id = str(uuid.uuid4())[:8]
        analysis = self.analyze_request(user_request)

        # Generate tasks from keywords
        tasks = []
        used_experts = set()
        task_counter = 1

        for keyword in analysis["keywords"]:
            expert_file = KEYWORD_TO_EXPERT_MAPPING.get(keyword)
            if expert_file and expert_file not in used_experts:
                used_experts.add(expert_file)

                model = EXPERT_TO_MODEL_MAPPING.get(expert_file, 'sonnet')
                priority = EXPERT_TO_PRIORITY_MAPPING.get(expert_file, 'MEDIA')
                specialization = SPECIALIZATION_DESCRIPTIONS.get(
                    expert_file, 'Specializzazione generale'
                )

                task = AgentTask(
                    id=f"T{task_counter}",
                    description=f"Work on {keyword} for: {user_request}",
                    agent_expert_file=expert_file,
                    model=model,
                    specialization=specialization,
                    dependencies=[],
                    priority=priority,
                    level=1,
                    estimated_time=2.5,
                    estimated_cost=0.25 if model == 'opus' else 0.08 if model == 'sonnet' else 0.02
                )
                tasks.append(task)
                task_counter += 1

        # Fallback if no tasks
        if not tasks:
            tasks.append(AgentTask(
                id="T1",
                description=f"Implement: {user_request}",
                agent_expert_file="core/coder.md",
                model="sonnet",
                specialization="Coding generale",
                dependencies=[],
                priority="MEDIA",
                level=1,
                estimated_time=2.5,
                estimated_cost=0.08
            ))
            task_counter = 2

        # FIX #2: Check if documenter already present before adding (RULE #5)
        documenter_already_present = any(
            'documenter' in t.agent_expert_file.lower() or
            'documentation' in t.agent_expert_file.lower()
            for t in tasks
        )

        if not documenter_already_present:
            # FIX #11: MANDATORY FINAL DOCUMENTATION (anti-loop, lean, clear)
            # Documenter MUST run at the end to:
            # 1. Consolidate all per-task docs
            # 2. Update ONLY necessary files
            # 3. Track what NOT to do (avoid error loops)
            documenter_deps = [t.id for t in tasks]
            tasks.append(AgentTask(
                id=f"T{task_counter}",
                description="[MANDATORY] Final documentation: consolidate task docs, update files, track anti-patterns",
                agent_expert_file="core/documenter.md",
                model="haiku",
                specialization="Documentation: lean, essential, clear - NO loops",
                dependencies=documenter_deps,
                priority="CRITICA",
                level=1,
                estimated_time=1.0,
                estimated_cost=0.02,
                requires_doc=False  # Documenter doesn't doc itself
            ))

        # Calculate parallel batches
        work_tasks = [t for t in tasks if "documenter" not in t.agent_expert_file]
        parallel_batches = [[t.id for t in work_tasks]] if work_tasks else [[]]

        # FIX #7: Use improved estimated time formula
        total_time = self._calculate_estimated_time(tasks)
        total_cost = sum(t.estimated_cost for t in tasks)

        plan = ExecutionPlan(
            session_id=session_id,
            tasks=tasks,
            parallel_batches=parallel_batches,
            total_agents=len(tasks),
            estimated_time=total_time,
            estimated_cost=total_cost,
            complexity=analysis["complexity"],
            domains=analysis["domains"]
        )

        # Create session
        self.sessions[session_id] = OrchestrationSession(
            session_id=session_id,
            user_request=user_request,
            status=TaskStatus.PENDING,
            plan=plan,
            started_at=datetime.now(),
            completed_at=None,
            results=[]
        )

        # FIX #8: Persist sessions to file
        self._save_sessions()

        return plan

    def format_plan_table(self, plan: ExecutionPlan) -> str:
        """Format execution plan as table"""
        lines = [
            "🎯 ORCHESTRATOR v6.0 - MCP MODE (36 AGENTS)",
            "",
            "📋 EXECUTION PLAN",
            f"├─ Session ID: {plan.session_id}",
            f"├─ Domains: {', '.join(plan.domains) if plan.domains else 'General'}",
            f"├─ Complexity: {plan.complexity}",
            f"├─ Total Agents: {plan.total_agents}",
            f"├─ Est. Time: {plan.estimated_time:.1f} min",
            f"├─ Est. Cost: ${plan.estimated_cost:.2f}",
            "",
            "🤖 AGENT TABLE",
            "| # | Task | Expert File | Model | Priority | Status |",
            "|---|------|-------------|-------|----------|--------|"
        ]

        for task in plan.tasks:
            deps = ", ".join(task.dependencies) if task.dependencies else "-"
            status = "⏳ PENDING"
            lines.append(
                f"| {task.id} | {task.description[:30]} | {task.agent_expert_file} | "
                f"{task.model} | {task.priority} | {status} |"
            )

        lines.append("")
        lines.append("⚡ EXECUTION STRATEGY:")
        lines.append(f"├─ Parallel execution: {len(plan.parallel_batches)} batch(es)")
        lines.append(f"├─ Max concurrent agents: {max(len(b) for b in plan.parallel_batches)}")
        lines.append(f"└─ Documenter task: T{len(plan.tasks)} (always last - RULE #5)")

        # FIX #11: Documentation requirements
        lines.append("")
        lines.append("📝 DOCUMENTATION REQUIREMENTS (FIX #11):")
        lines.append("├─ Per-task doc: MANDATORY after each task completion")
        lines.append("├─ Format: {task_id}: {what_done} | NOT: {what_not_to_do}")
        lines.append("├─ Final doc: Consolidate all + update files")
        lines.append("└─ Goal: Lean, essential, clear - NO error loops")

        # FIX #12: Temp files cleanup rule
        lines.append("")
        lines.append("🧹 CLEANUP OBBLIGATORIO (FIX #12):")
        lines.append("├─ REGOLA: Chi crea file temp DEVE eliminarli")
        lines.append("├─ Pattern: *.tmp, *.temp, *.bak, *.swp, *~, *.pyc")
        lines.append("├─ Dirs: __pycache__, .pytest_cache, .mypy_cache")
        lines.append("├─ Quando: DOPO ogni task + FINE orchestrazione")
        lines.append("└─ Violazione: BLOCCA completamento task")

        return "\n".join(lines)

    def generate_task_doc_template(self, task: AgentTask) -> str:
        """FIX #11: Generate documentation template for a task"""
        return f"""
## Task {task.id}: {task.description[:50]}

### What was done:
- [DESCRIBE CHANGES IN 1-2 LINES]

### What NOT to do (anti-patterns):
- [LIST APPROACHES THAT FAILED OR SHOULD BE AVOIDED]

### Files changed:
- [LIST FILES]

### Status: [success/partial/failed]
"""

    def get_session(self, session_id: str) -> Optional[OrchestrationSession]:
        """Get session by ID"""
        return self.sessions.get(session_id)

    def list_sessions(self, limit: int = 10) -> List[Dict[str, Any]]:
        """List recent sessions"""
        sessions = list(self.sessions.values())
        sessions.sort(key=lambda s: s.started_at, reverse=True)
        return [
            {
                "session_id": s.session_id,
                "user_request": s.user_request,
                "status": s.status.value,
                "started_at": s.started_at.isoformat(),
                "tasks_count": len(s.plan.tasks) if s.plan else 0
            }
            for s in sessions[:limit]
        ]

    def get_available_agents(self) -> List[Dict[str, Any]]:
        """Get list of all available expert agents"""
        agents = []
        seen_experts = set()

        for keyword, expert_file in KEYWORD_TO_EXPERT_MAPPING.items():
            if expert_file not in seen_experts:
                seen_experts.add(expert_file)
                agents.append({
                    "keyword": keyword,
                    "expert_file": expert_file,
                    "model": EXPERT_TO_MODEL_MAPPING.get(expert_file, "sonnet"),
                    "priority": EXPERT_TO_PRIORITY_MAPPING.get(expert_file, "MEDIA"),
                    "specialization": SPECIALIZATION_DESCRIPTIONS.get(
                        expert_file, "General"
                    )
                })

        return agents


# Global engine instance
engine = OrchestratorEngine()

# Global ProcessManager instance (if available)
# Initialized lazily on first use to avoid issues during import
_process_manager: Optional[Any] = None

def get_process_manager() -> Optional[Any]:
    """
    Get the global ProcessManager instance.
    Returns None if ProcessManager is not available (non-Windows or import error).
    """
    global _process_manager
    if PROCESS_MANAGER_AVAILABLE and _process_manager is None:
        try:
            _process_manager = ProcessManager()
            logger.info("ProcessManager initialized successfully")
        except Exception as e:
            logger.warning(f"Failed to initialize ProcessManager: {e}")
            _process_manager = None
    return _process_manager

# =============================================================================
# MCP SERVER SETUP
# =============================================================================

server = Server("orchestrator-mcp")

@server.list_resources()
async def handle_list_resources() -> list[str]:
    """List available resources"""
    return [
        "orchestrator://sessions",
        "orchestrator://agents",
        "orchestrator://config"
    ]

@server.read_resource()
async def handle_read_resource(uri: str) -> str:
    """Read a resource"""
    if uri == "orchestrator://sessions":
        sessions = engine.list_sessions()
        return json.dumps(sessions, indent=2)
    elif uri == "orchestrator://agents":
        agents = engine.get_available_agents()
        return json.dumps(agents, indent=2)
    elif uri == "orchestrator://config":
        return json.dumps({
            "version": "6.0.0-MCP",
            "total_agents": 36,
            "max_parallel_agents": 64,
            "default_model": "auto",
            "auto_orchestrate": True
        }, indent=2)
    else:
        raise ValueError(f"Unknown resource: {uri}")

@server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """List available MCP tools"""
    return [
        Tool(
            name="orchestrator_analyze",
            description="Analyze a request and generate execution plan without executing",
            inputSchema={
                "type": "object",
                "properties": {
                    "request": {
                        "type": "string",
                        "description": "The user request to analyze"
                    },
                    "show_table": {
                        "type": "boolean",
                        "description": "Show execution plan table",
                        "default": True
                    }
                },
                "required": ["request"]
            }
        ),
        Tool(
            name="orchestrator_execute",
            description="Execute orchestration plan (generates plan for Task tool execution)",
            inputSchema={
                "type": "object",
                "properties": {
                    "request": {
                        "type": "string",
                        "description": "The user request to orchestrate"
                    },
                    "parallel": {
                        "type": "number",
                        "description": "Max parallel agents (1-64)",
                        "default": 6,
                        "minimum": 1,
                        "maximum": 64
                    },
                    "model": {
                        "type": "string",
                        "description": "Force specific model",
                        "enum": ["auto", "haiku", "sonnet", "opus"],
                        "default": "auto"
                    }
                },
                "required": ["request"]
            }
        ),
        Tool(
            name="orchestrator_status",
            description="Get status of an orchestration session",
            inputSchema={
                "type": "object",
                "properties": {
                    "session_id": {
                        "type": "string",
                        "description": "Session ID to check (leave empty for latest)"
                    }
                }
            }
        ),
        Tool(
            name="orchestrator_agents",
            description="List all available expert agents",
            inputSchema={
                "type": "object",
                "properties": {
                    "filter": {
                        "type": "string",
                        "description": "Filter by domain or keyword (optional)"
                    }
                }
            }
        ),
        Tool(
            name="orchestrator_list",
            description="List recent orchestration sessions",
            inputSchema={
                "type": "object",
                "properties": {
                    "limit": {
                        "type": "number",
                        "description": "Max sessions to return",
                        "default": 10,
                        "minimum": 1,
                        "maximum": 50
                    }
                }
            }
        ),
        Tool(
            name="orchestrator_preview",
            description="Preview orchestration with detailed task breakdown",
            inputSchema={
                "type": "object",
                "properties": {
                    "request": {
                        "type": "string",
                        "description": "Request to preview"
                    }
                },
                "required": ["request"]
            }
        ),
        Tool(
            name="orchestrator_cancel",
            description="Cancel an active orchestration session",
            inputSchema={
                "type": "object",
                "properties": {
                    "session_id": {
                        "type": "string",
                        "description": "Session ID to cancel"
                    }
                },
                "required": ["session_id"]
            }
        ),
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> List[TextContent | ImageContent | EmbeddedResource]:
    """Handle tool calls"""

    try:
        if name == "orchestrator_analyze":
            request = arguments.get("request", "")
            show_table = arguments.get("show_table", True)

            if not request:
                return [TextContent(
                    type="text",
                    text="❌ Error: 'request' parameter is required"
                )]

            plan = engine.generate_execution_plan(request)

            output = f"""🎯 ORCHESTRATOR ANALYSIS COMPLETE

📋 ANALYSIS SUMMARY
├─ Request: {request}
├─ Session ID: {plan.session_id}
├─ Domains: {', '.join(plan.domains) if plan.domains else 'General'}
├─ Complexity: {plan.complexity}
├─ Total Tasks: {plan.total_agents}
├─ Est. Time: {plan.estimated_time:.1f} min
├─ Est. Cost: ${plan.estimated_cost:.2f}
└─ Parallel Batches: {len(plan.parallel_batches)}
"""

            if show_table:
                output += "\n" + engine.format_plan_table(plan)

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_execute":
            request = arguments.get("request", "")
            parallel = arguments.get("parallel", 6)
            model = arguments.get("model", "auto")

            if not request:
                return [TextContent(
                    type="text",
                    text="❌ Error: 'request' parameter is required"
                )]

            plan = engine.generate_execution_plan(request)

            output = f"""🚀 ORCHESTRATOR v6.0 - EXECUTION MODE
⚡ ALWAYS ON - Like Serena MCP

📋 EXECUTION PREPARED
├─ Session ID: {plan.session_id}
├─ Parallelism: {parallel} agents max
├─ Model Override: {model}
├─ Total Tasks: {plan.total_agents}

{engine.format_plan_table(plan)}

📝 NEXT STEP: Use Task tool to launch agents with this plan:

The following agents should be launched in parallel:
"""

            for task in plan.tasks:
                if "documenter" not in task.agent_expert_file:
                    output += f"\n  [{task.id}] {task.description}\n"
                    output += f"      → Expert: {task.agent_expert_file}\n"
                    output += f"      → Model: {task.model}\n"

            output += f"""
╔══════════════════════════════════════════════════════════════════════════════╗
║  ⚠️  MANDATORY FINAL STEP - R5 - NESSUNA ECCEZIONE                          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  DOPO che TUTTI i task sopra sono completati, DEVI eseguire:                 ║
║                                                                              ║
"""
            doc_task = plan.tasks[-1]
            output += f"║  [{doc_task.id}] {doc_task.description[:60]}\n"
            output += f"║      → Expert: {doc_task.agent_expert_file}\n"
            output += f"║      → Model: {doc_task.model}\n"
            output += f"""║                                                                              ║
║  !!! SE NON ESEGUI IL DOCUMENTER, L'ORCHESTRAZIONE È FALLITA !!!            ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

📝 DOCUMENTER PROMPT DA USARE:
"Documenta le modifiche di questa sessione:
- Cosa è stato fatto (1-2 righe per task)
- Cosa NON fare (anti-patterns)
- File modificati
- Aggiorna documentazione se necessario"
"""

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_status":
            session_id = arguments.get("session_id", "")

            if session_id:
                session = engine.get_session(session_id)
                if not session:
                    return [TextContent(
                        type="text",
                        text=f"❌ Session '{session_id}' not found"
                    )]

                # Calculate values safely
                tasks_count = len(session.plan.tasks) if session.plan else 0
                est_cost = session.plan.estimated_cost if session.plan else 0.00
                est_time = session.plan.estimated_time if session.plan else 0.0
                complexity = session.plan.complexity if session.plan else "N/A"
                domains = ', '.join(session.plan.domains) if session.plan and session.plan.domains else "N/A"

                output = f"""📊 SESSION STATUS: {session.session_id}
├─ Request: {session.user_request}
├─ Status: {session.status.value}
├─ Started: {session.started_at.isoformat()}
├─ Domains: {domains}
├─ Complexity: {complexity}
├─ Tasks: {tasks_count}
├─ Est. Time: {est_time:.1f} min
└─ Est. Cost: ${est_cost:.2f}
"""
            else:
                sessions = engine.list_sessions(5)
                if not sessions:
                    return [TextContent(
                        type="text",
                        text="📊 No recent sessions found"
                    )]

                output = "📊 RECENT SESSIONS\n\n"
                for s in sessions:
                    output += f"├─ {s['session_id']}: {s['user_request'][:40]}...\n"
                    output += f"   │  Status: {s['status']} | Tasks: {s['tasks_count']}\n"

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_agents":
            filter_kw = arguments.get("filter", "").lower()
            agents = engine.get_available_agents()

            if filter_kw:
                agents = [
                    a for a in agents
                    if filter_kw in a["expert_file"].lower() or
                       filter_kw in a["keyword"].lower() or
                       filter_kw in a["specialization"].lower()
                ]

            output = f"🤖 AVAILABLE EXPERT AGENTS ({len(agents)} total)\n\n"
            output += "| Keyword | Expert File | Model | Priority | Specialization |\n"
            output += "|---------|-------------|-------|----------|----------------|\n"

            for agent in agents:
                output += f"| {agent['keyword']} | {agent['expert_file']} | {agent['model']} | {agent['priority']} | {agent['specialization'][:40]}... |\n"

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_list":
            limit = min(arguments.get("limit", 10), 50)
            sessions = engine.list_sessions(limit)

            output = f"📋 RECENT ORCHESTRATION SESSIONS (max {limit})\n\n"

            if not sessions:
                output += "No sessions found yet. Use orchestrator_analyze or orchestrator_execute first."
            else:
                for s in sessions:
                    output += f"├─ [{s['session_id']}] {s['user_request'][:50]}\n"
                    output += f"│  └─ Status: {s['status']} | Tasks: {s['tasks_count']} | {s['started_at']}\n"

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_preview":
            request = arguments.get("request", "")

            if not request:
                return [TextContent(
                    type="text",
                    text="❌ Error: 'request' parameter is required"
                )]

            plan = engine.generate_execution_plan(request)
            analysis = engine.analyze_request(request)

            output = f"""🔍 ORCHESTRATOR PREVIEW MODE
{'=' * 50}

📋 REQUEST ANALYSIS
├─ Input: "{request}"
├─ Keywords Found: {', '.join(analysis['keywords']) if analysis['keywords'] else 'None - will use fallback'}
├─ Domains: {', '.join(analysis['domains']) if analysis['domains'] else 'General'}
├─ Complexity: {analysis['complexity']}
├─ Multi-Domain: {'Yes' if analysis['is_multi_domain'] else 'No'}

🤖 TASK BREAKDOWN
{'=' * 50}

Work Tasks (Parallel):
"""

            work_tasks = [t for t in plan.tasks if "documenter" not in t.agent_expert_file]
            for i, task in enumerate(work_tasks, 1):
                output += f"""
  [{task.id}] {task.description}
  ├─ Expert: {task.agent_expert_file}
  ├─ Model: {task.model}
  ├─ Priority: {task.priority}
  ├─ Specialization: {task.specialization}
  └─ Est: {task.estimated_time}m / ${task.estimated_cost:.2f}
"""

            doc_task = plan.tasks[-1]
            output += f"""
Final Task (Sequential):
  [{doc_task.id}] {doc_task.description}
  ├─ Expert: {doc_task.agent_expert_file}
  ├─ Model: {doc_task.model}
  └─ Est: {doc_task.estimated_time}m / ${doc_task.estimated_cost:.2f}

📊 SUMMARY
├─ Total Agents: {plan.total_agents}
├─ Parallel Tasks: {len(work_tasks)}
├─ Est. Total Time: {plan.estimated_time:.1f} min
├─ Est. Total Cost: ${plan.estimated_cost:.2f}
└─ Session ID: {plan.session_id}
"""

            return [TextContent(type="text", text=output)]

        elif name == "orchestrator_cancel":
            session_id = arguments.get("session_id", "")

            if not session_id:
                return [TextContent(
                    type="text",
                    text="❌ Error: 'session_id' parameter is required"
                )]

            session = engine.get_session(session_id)
            if not session:
                return [TextContent(
                    type="text",
                    text=f"❌ Session '{session_id}' not found"
                )]

            session.status = TaskStatus.CANCELLED
            session.completed_at = datetime.now()

            return [TextContent(
                type="text",
                text=f"✅ Session {session_id} cancelled successfully"
            )]

        else:
            return [TextContent(
                type="text",
                text=f"❌ Unknown tool: {name}"
            )]

    except Exception as e:
        logger.exception(f"Error executing tool {name}")
        return [TextContent(
            type="text",
            text=f"❌ Error executing {name}: {str(e)}"
        )]

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

async def run_server():
    """Main entry point for MCP server with ProcessManager lifecycle."""
    # Initialize ProcessManager if available
    pm = get_process_manager()

    try:
        async with stdio_server() as (read_stream, write_stream):
            await server.run(
                read_stream,
                write_stream,
                InitializationOptions(
                    server_name="orchestrator-mcp",
                    server_version="6.0.0",
                    capabilities=server.get_capabilities(
                        notification_options=NotificationOptions(),
                        experimental_capabilities={}
                    )
                )
            )
    finally:
        # Ensure ProcessManager cleanup on server shutdown
        if pm is not None:
            try:
                logger.info("Performing ProcessManager cleanup on server shutdown")
                pm.terminate_all(timeout=5.0)
            except Exception as e:
                logger.warning(f"Error during ProcessManager cleanup: {e}")

def main():
    """Synchronous entry point for uvx"""
    asyncio.run(run_server())

if __name__ == "__main__":
    main()

---
name: Sistema Agent Claude Code
description: Main documentation overview for the agent system
---

# Sistema Agent Claude Code

## Struttura

```
agents/
├── core/                  # Agent principali
│   ├── orchestrator.md   # 🎯 Punto ingresso (V2.2)
│   ├── analyzer.md       # Analisi codebase
│   ├── coder.md          # Implementazione
│   ├── reviewer.md       # Code review
│   └── documenter.md     # Documentazione
│
├── experts/              # Expert specializzati (15+)
│   ├── gui-super-expert.md
│   ├── database_expert.md
│   ├── security_unified_expert.md
│   ├── trading_strategy_expert.md
│   ├── mql_expert.md
│   └── ... (altri)
│
├── config/               # Configurazioni
│   └── standards.md
│
├── templates/            # Template task
│   ├── task.md
│   ├── review.md
│   └── integration.md
│
└── workflows/            # Workflow predefiniti
    ├── feature.md
    ├── bugfix.md
    └── refactoring.md
```

## Uso Rapido

L'orchestrator si attiva automaticamente. Per ogni richiesta:

1. Claude legge `CLAUDE.md` globale
2. Legge `orchestrator.md`
3. Delega a agent multipli in parallelo
4. Riporta risultati

## Regole
- MAI codice diretto - sempre delegare
- SEMPRE multi-agent parallelo
- SEMPRE comunicare tabella agent

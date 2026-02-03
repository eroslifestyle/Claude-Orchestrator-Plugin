# Agent Registry & Routing System - Guida Utilizzo

## Panoramica

Il sistema Agent Registry è stato configurato per gestire automaticamente il routing degli Expert Agents con fallback intelligenti e availability checking.

## File di Configurazione

### Struttura Principale

```
~/.claude/config/
├── agent-registry.json      # Configurazione principale degli agent
├── agent-health-check.sh    # Script per health check
├── agent-router.py          # Sistema di routing automatico
└── AGENT_REGISTRY_USAGE.md  # Questa documentazione
```

## Expert Agents Configurati

### 🏗️ Architettura & Design
- **architect_expert** (Priority: 9) - Design di sistemi, architetture distribuite
- **devops_expert** (Priority: 8) - Infrastructure as Code, CI/CD, monitoring

### 🔐 Sicurezza & Compliance
- **security_unified_expert** (Priority: 10) - Security by Design, compliance

### 💾 Dati & Performance
- **database_expert** (Priority: 7) - Design DB, optimization, migrations
- **tester_expert** (Priority: 6) - QA, performance profiling, debugging

### 🔧 Implementazione & Integration
- **languages_expert** (Priority: 5) - Implementazioni idiomatiche multi-linguaggio
- **integration_expert** (Priority: 7) - API, Telegram, trading platforms

### 🤖 Specializzazioni
- **ai_integration_expert** (Priority: 6) - AI/ML implementation
- **mobile_expert** (Priority: 6) - iOS/Android, React Native, Flutter
- **gui_super_expert** (Priority: 5) - UI/UX, design systems

## Utilizzo del Sistema

### 1. Health Check degli Agent

```bash
# Health check completo
~/.claude/config/agent-health-check.sh check

# Visualizza stato corrente
~/.claude/config/agent-health-check.sh status

# Verifica fallback per agent specifico
~/.claude/config/agent-health-check.sh fallback architect_expert
```

### 2. Routing Automatico

```bash
# Routing basato su keywords
python3 ~/.claude/config/agent-router.py route -k "database" "performance" "optimization"

# Routing con priorità alta
python3 ~/.claude/config/agent-router.py route -k "security" "encryption" -p critical

# Trova agent per capability specifica
python3 ~/.claude/config/agent-router.py capability -c "api_integration"

# Pattern di collaborazione predefiniti
python3 ~/.claude/config/agent-router.py pattern --pattern "architecture_review"
```

### 3. Keyword Mappings

#### Architecture & Design
- **Keywords**: architettura, design, sistema, microservizi, distributed, scalability
- **Primary Agent**: architect_expert
- **Fallback**: languages_expert → integration_expert

#### Security & Compliance
- **Keywords**: security, encryption, auth, vulnerability, compliance, audit
- **Primary Agent**: security_unified_expert
- **Fallback**: devops_expert → integration_expert

#### Database & Performance
- **Keywords**: database, sql, nosql, query, optimization, performance
- **Primary Agent**: database_expert
- **Fallback**: languages_expert → devops_expert

#### Testing & QA
- **Keywords**: test, bug, quality, performance, profiling, debug
- **Primary Agent**: tester_expert
- **Fallback**: languages_expert → devops_expert

#### API & Integration
- **Keywords**: api, integration, telegram, webhook, rest, graphql
- **Primary Agent**: integration_expert
- **Fallback**: languages_expert → devops_expert

## Priority Levels & Fallback Strategies

### Priority Mapping
1. **security_unified_expert** (10) - Massima priorità per security
2. **architect_expert** (9) - Design decisions critiche
3. **devops_expert** (8) - Infrastructure & deployment
4. **database_expert** (7) - Performance & data integrity
5. **integration_expert** (7) - Communication protocols
6. **tester_expert** (6) - Quality assurance
7. **ai_integration_expert** (6) - AI/ML features
8. **mobile_expert** (6) - Mobile development
9. **languages_expert** (5) - Implementation support
10. **gui_super_expert** (5) - UI/UX design

### Cascading Fallback Rules

```json
{
  "architect_expert": {
    "primary_fallback": "languages_expert",
    "secondary_fallback": "integration_expert"
  },
  "security_unified_expert": {
    "primary_fallback": "devops_expert",
    "secondary_fallback": "integration_expert"
  },
  "database_expert": {
    "primary_fallback": "languages_expert",
    "secondary_fallback": "devops_expert"
  }
}
```

### Emergency Fallback
- **Agent**: languages_expert (competenze più ampie)

## Collaboration Patterns

### 1. Architecture Review
- Agenti: architect_expert + security_unified_expert + database_expert
- Uso: Revisioni architetturali, design decisions

### 2. Deployment Pipeline
- Agenti: devops_expert + security_unified_expert + tester_expert
- Uso: CI/CD, deployment production

### 3. Feature Implementation
- Agenti: languages_expert + tester_expert + gui_super_expert
- Uso: Sviluppo nuove feature

### 4. Integration Project
- Agenti: integration_expert + security_unified_expert + languages_expert
- Uso: Integrazioni API, external services

## Capability Matrix

### System Architecture
- **Primary**: architect_expert
- **Secondary**: devops_expert, security_unified_expert

### Security & Compliance
- **Primary**: security_unified_expert
- **Secondary**: architect_expert, devops_expert

### Database & Data
- **Primary**: database_expert
- **Secondary**: architect_expert, devops_expert

### Programming & Implementation
- **Primary**: languages_expert
- **Secondary**: architect_expert, tester_expert

### API & Integration
- **Primary**: integration_expert
- **Secondary**: security_unified_expert, languages_expert

## Monitoring & Alerting

### Health Check Automatico
- Intervallo: 300 secondi (5 minuti)
- Timeout: 30 secondi
- Retry: 3 tentativi

### Alert Thresholds
- High fallback rate: >30%
- Agent unavailable: >600 secondi (10 minuti)
- Low resolution success: <70%

### Metriche Monitorate
- Resolution time (tempo medio risoluzione)
- Fallback rate (percentuale uso fallback)
- Collaboration efficiency (successo multi-agent)

## Esempi di Utilizzo Pratico

### Scenario 1: Problema di Performance Database
```bash
# Keywords: database, performance, slow, query
# Routing: database_expert (primary) → languages_expert (fallback)
python3 ~/.claude/config/agent-router.py route -k "database" "performance" "query" "slow"
```

### Scenario 2: Security Audit
```bash
# Keywords: security, audit, vulnerability
# Routing: security_unified_expert (primary) → devops_expert (fallback)
python3 ~/.claude/config/agent-router.py route -k "security" "audit" "vulnerability" -p critical
```

### Scenario 3: API Integration
```bash
# Keywords: api, telegram, webhook, integration
# Routing: integration_expert (primary) → languages_expert (fallback)
python3 ~/.claude/config/agent-router.py route -k "api" "telegram" "webhook"
```

### Scenario 4: Architecture Review
```bash
# Pattern predefinito per architecture review
python3 ~/.claude/config/agent-router.py pattern --pattern "architecture_review"
# Risultato: architect_expert, security_unified_expert, database_expert
```

## Troubleshooting

### Agent Non Disponibile
1. Verificare che il file agent esista
2. Controllare health check logs
3. Utilizzare fallback automatico
4. Verificare emergency fallback (languages_expert)

### Performance Issues
1. Controllare success rate < 70%
2. Verificare fallback rate > 30%
3. Eseguire health check manuale
4. Controllare log di routing

### Configurazione Non Valida
1. Validare JSON syntax
2. Verificare path degli agent files
3. Controllare fallback dependencies
4. Testare con script di health check

## File di Log

- **Agent Health**: `~/.claude/config/agent-health.log`
- **Router Events**: `~/.claude/config/agent-router.log`

## Aggiornamenti Configurazione

Per modificare la configurazione:

1. Editare `agent-registry.json`
2. Validare sintassi JSON
3. Eseguire health check test
4. Verificare routing con keywords test

La configurazione viene ricaricata automaticamente ad ogni utilizzo del router.
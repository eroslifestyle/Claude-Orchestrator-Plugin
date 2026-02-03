#!/usr/bin/env node
/**
 * DASHBOARD ANALYTICS COMPLETAMENTO - Sistema Analytics Avanzato per Agent Completion Tracking
 *
 * Features:
 * - Performance metrics per agent (velocità, efficiency)
 * - Token/minute ratio tracking per agent type
 * - Success rate e error pattern analysis
 * - Task completion distribution
 * - Resource utilization tracking
 * - Report comparativo tra livelli
 * - Real-time visualization dei progressi
 * - Prediction ETA basata su analytics
 * - Alert system per anomalie
 */

const fs = require('fs');
const path = require('path');
const EventEmitter = require('events');

class DashboardAnalytics extends EventEmitter {
    constructor(options = {}) {
        super();

        this.options = {
            // Configurazioni generali
            enableRealTime: true,
            enablePredictions: true,
            enableAlerts: true,
            enableLogging: true,

            // Metriche e soglie
            alertThresholds: {
                successRateBelow: 70,
                avgResponseTimeAbove: 10000, // 10 secondi
                tokenRateBelow: 10, // token/minuto
                errorRateAbove: 25,
                resourceUtilizationAbove: 85
            },

            // Configurazioni storage
            dataRetentionDays: 30,
            maxDataPoints: 10000,
            saveInterval: 60000, // 1 minuto

            ...options
        };

        // Storage in-memory per metriche real-time
        this.metrics = {
            agents: new Map(),           // Metriche per agent
            sessions: new Map(),         // Sessioni attive
            completions: [],             // Storico completamenti
            performance: new Map(),      // Performance data
            errors: [],                  // Error tracking
            resources: new Map(),        // Resource utilization
            predictions: new Map()       // Prediction cache
        };

        // Contatori e accumulatori
        this.counters = {
            totalCompletions: 0,
            totalErrors: 0,
            totalTokensUsed: 0,
            totalTime: 0,
            sessionsActive: 0
        };

        // Alert system
        this.alerts = {
            active: new Map(),
            history: [],
            subscribers: []
        };

        // File paths
        this.dataPath = path.join(process.cwd(), 'agents', 'analytics', 'data');
        this.configPath = path.join(this.dataPath, 'config.json');
        this.metricsPath = path.join(this.dataPath, 'metrics.json');
        this.alertsPath = path.join(this.dataPath, 'alerts.json');

        this.initialize();
    }

    /**
     * Inizializzazione del sistema di analytics
     */
    async initialize() {
        console.log('📊 Inizializzazione Dashboard Analytics...');

        // Crea directory se necessarie
        await this.ensureDirectories();

        // Carica configurazioni e dati esistenti
        await this.loadExistingData();

        // Avvia collection automatica
        this.startDataCollection();

        // Avvia sistema di alert
        this.startAlertSystem();

        // Avvia salvataggio periodico
        this.startPeriodicSave();

        console.log('✅ Dashboard Analytics inizializzato');
        this.emit('analytics-ready');
    }

    /**
     * Assicura che le directory esistano
     */
    async ensureDirectories() {
        const dirs = [
            this.dataPath,
            path.join(this.dataPath, 'backups'),
            path.join(this.dataPath, 'reports'),
            path.join(this.dataPath, 'exports')
        ];

        for (const dir of dirs) {
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
        }
    }

    /**
     * Carica dati esistenti
     */
    async loadExistingData() {
        try {
            // Carica metriche precedenti se esistono
            if (fs.existsSync(this.metricsPath)) {
                const data = JSON.parse(fs.readFileSync(this.metricsPath, 'utf8'));
                this.hydrateMetrics(data);
                console.log('📈 Dati metriche precedenti caricati');
            }

            // Carica alert precedenti
            if (fs.existsSync(this.alertsPath)) {
                const alertData = JSON.parse(fs.readFileSync(this.alertsPath, 'utf8'));
                this.alerts.history = alertData.history || [];
                console.log('🚨 Alert history caricato');
            }
        } catch (error) {
            console.warn('⚠️  Errore nel caricamento dati precedenti:', error.message);
        }
    }

    /**
     * Reidrata le metriche da dati salvati
     */
    hydrateMetrics(data) {
        if (data.completions) {
            this.metrics.completions = data.completions;
        }

        if (data.counters) {
            this.counters = { ...this.counters, ...data.counters };
        }

        if (data.agents) {
            this.metrics.agents = new Map(Object.entries(data.agents));
        }

        if (data.performance) {
            this.metrics.performance = new Map(Object.entries(data.performance));
        }
    }

    /**
     * Registra l'inizio di una sessione agent
     */
    registerAgentSessionStart(agentId, agentType, sessionData) {
        const sessionId = sessionData.sessionId || this.generateSessionId();
        const timestamp = Date.now();

        const session = {
            sessionId,
            agentId,
            agentType,
            startTime: timestamp,
            status: 'active',
            data: sessionData,
            metrics: {
                tokensUsed: 0,
                tasksCompleted: 0,
                errorsOccurred: 0
            }
        };

        this.metrics.sessions.set(sessionId, session);
        this.counters.sessionsActive++;

        // Inizializza metriche agent se non esistono
        if (!this.metrics.agents.has(agentId)) {
            this.initializeAgentMetrics(agentId, agentType);
        }

        this.emit('session-started', { sessionId, agentId, agentType });

        if (this.options.enableLogging) {
            console.log(`🚀 Sessione ${sessionId} avviata - Agent: ${agentType}(${agentId})`);
        }

        return sessionId;
    }

    /**
     * Inizializza metriche per un nuovo agent
     */
    initializeAgentMetrics(agentId, agentType) {
        const metrics = {
            agentId,
            agentType,
            totalSessions: 0,
            totalCompletions: 0,
            totalErrors: 0,
            totalTokensUsed: 0,
            totalExecutionTime: 0,
            averageResponseTime: 0,
            successRate: 0,
            tokenPerMinuteRate: 0,
            errorPatterns: new Map(),
            performanceHistory: [],
            lastActivity: Date.now(),
            efficiency: 0
        };

        this.metrics.agents.set(agentId, metrics);
        return metrics;
    }

    /**
     * Aggiorna metriche durante l'esecuzione
     */
    updateSessionMetrics(sessionId, updateData) {
        const session = this.metrics.sessions.get(sessionId);
        if (!session) {
            console.warn(`⚠️  Sessione ${sessionId} non trovata per update metriche`);
            return;
        }

        const agentMetrics = this.metrics.agents.get(session.agentId);
        if (!agentMetrics) {
            console.warn(`⚠️  Metriche agent ${session.agentId} non trovate`);
            return;
        }

        // Aggiorna metriche sessione
        if (updateData.tokensUsed) {
            session.metrics.tokensUsed += updateData.tokensUsed;
            agentMetrics.totalTokensUsed += updateData.tokensUsed;
            this.counters.totalTokensUsed += updateData.tokensUsed;
        }

        if (updateData.tasksCompleted) {
            session.metrics.tasksCompleted += updateData.tasksCompleted;
            agentMetrics.totalCompletions += updateData.tasksCompleted;
            this.counters.totalCompletions += updateData.tasksCompleted;
        }

        if (updateData.errors) {
            session.metrics.errorsOccurred += updateData.errors.length;
            agentMetrics.totalErrors += updateData.errors.length;
            this.counters.totalErrors += updateData.errors.length;

            // Traccia pattern degli errori
            updateData.errors.forEach(error => {
                this.trackErrorPattern(session.agentId, error);
                this.metrics.errors.push({
                    timestamp: Date.now(),
                    sessionId,
                    agentId: session.agentId,
                    agentType: session.agentType,
                    error: error
                });
            });
        }

        // Calcola metriche derivate
        this.calculateDerivedMetrics(session.agentId);

        this.emit('metrics-updated', { sessionId, agentId: session.agentId, updateData });
    }

    /**
     * Registra il completamento di una sessione
     */
    registerAgentCompletion(sessionId, completionData) {
        const session = this.metrics.sessions.get(sessionId);
        if (!session) {
            console.warn(`⚠️  Sessione ${sessionId} non trovata per completamento`);
            return;
        }

        const endTime = Date.now();
        const executionTime = endTime - session.startTime;

        // Aggiorna sessione
        session.endTime = endTime;
        session.executionTime = executionTime;
        session.status = completionData.success ? 'completed' : 'failed';
        session.result = completionData;

        // Aggiorna contatori
        this.counters.sessionsActive--;
        this.counters.totalTime += executionTime;

        // Aggiorna metriche agent
        const agentMetrics = this.metrics.agents.get(session.agentId);
        if (agentMetrics) {
            agentMetrics.totalSessions++;
            agentMetrics.totalExecutionTime += executionTime;
            agentMetrics.lastActivity = endTime;

            // Aggiungi alla history
            agentMetrics.performanceHistory.push({
                timestamp: endTime,
                executionTime,
                success: completionData.success,
                tokensUsed: session.metrics.tokensUsed,
                tasksCompleted: session.metrics.tasksCompleted,
                quality: completionData.quality || 0
            });

            // Mantieni solo gli ultimi 100 record
            if (agentMetrics.performanceHistory.length > 100) {
                agentMetrics.performanceHistory = agentMetrics.performanceHistory.slice(-100);
            }

            this.calculateDerivedMetrics(session.agentId);
        }

        // Aggiungi al record completamenti
        const completion = {
            sessionId,
            agentId: session.agentId,
            agentType: session.agentType,
            timestamp: endTime,
            executionTime,
            success: completionData.success,
            tokensUsed: session.metrics.tokensUsed,
            tasksCompleted: session.metrics.tasksCompleted,
            quality: completionData.quality || 0,
            data: completionData
        };

        this.metrics.completions.push(completion);

        // Mantieni solo gli ultimi N completamenti
        if (this.metrics.completions.length > this.options.maxDataPoints) {
            this.metrics.completions = this.metrics.completions.slice(-this.options.maxDataPoints);
        }

        // Rimuovi sessione dalle attive
        this.metrics.sessions.delete(sessionId);

        // Aggiorna predictions
        this.updatePredictions(session.agentType);

        // Controlla per alert
        this.checkAlertConditions(session.agentId);

        this.emit('completion-registered', completion);

        if (this.options.enableLogging) {
            console.log(`✅ Completamento registrato - Sessione: ${sessionId}, Tempo: ${executionTime}ms`);
        }

        return completion;
    }

    /**
     * Calcola metriche derivate per un agent
     */
    calculateDerivedMetrics(agentId) {
        const metrics = this.metrics.agents.get(agentId);
        if (!metrics || metrics.totalSessions === 0) return;

        // Success rate
        metrics.successRate = metrics.totalSessions > 0
            ? ((metrics.totalSessions - metrics.totalErrors) / metrics.totalSessions) * 100
            : 0;

        // Average response time
        metrics.averageResponseTime = metrics.totalSessions > 0
            ? metrics.totalExecutionTime / metrics.totalSessions
            : 0;

        // Token per minute rate
        const totalMinutes = metrics.totalExecutionTime / (1000 * 60);
        metrics.tokenPerMinuteRate = totalMinutes > 0
            ? metrics.totalTokensUsed / totalMinutes
            : 0;

        // Efficiency (tasks completed per unit time)
        metrics.efficiency = totalMinutes > 0
            ? metrics.totalCompletions / totalMinutes
            : 0;
    }

    /**
     * Traccia pattern degli errori
     */
    trackErrorPattern(agentId, error) {
        const metrics = this.metrics.agents.get(agentId);
        if (!metrics) return;

        const errorType = error.type || error.name || 'UnknownError';

        if (!metrics.errorPatterns.has(errorType)) {
            metrics.errorPatterns.set(errorType, {
                count: 0,
                firstSeen: Date.now(),
                lastSeen: Date.now(),
                examples: []
            });
        }

        const pattern = metrics.errorPatterns.get(errorType);
        pattern.count++;
        pattern.lastSeen = Date.now();

        // Mantieni alcuni esempi
        if (pattern.examples.length < 5) {
            pattern.examples.push({
                timestamp: Date.now(),
                message: error.message || error.toString(),
                stack: error.stack
            });
        }
    }

    /**
     * Genera report comparativo tra agenti
     */
    generateComparativeReport(timeRange = '24h') {
        const now = Date.now();
        const timeRangeMs = this.parseTimeRange(timeRange);
        const cutoffTime = now - timeRangeMs;

        const report = {
            metadata: {
                generatedAt: new Date().toISOString(),
                timeRange,
                cutoffTime: new Date(cutoffTime).toISOString(),
                totalAgents: this.metrics.agents.size
            },
            summary: {
                totalCompletions: 0,
                totalErrors: 0,
                totalTokensUsed: 0,
                averageSuccessRate: 0,
                averageResponseTime: 0
            },
            agentComparisons: [],
            topPerformers: {
                bySuccessRate: [],
                bySpeed: [],
                byEfficiency: [],
                byTokenRate: []
            },
            trends: {
                completionTrend: [],
                errorTrend: [],
                performanceTrend: []
            }
        };

        // Filtra completamenti nel time range
        const recentCompletions = this.metrics.completions.filter(c => c.timestamp > cutoffTime);

        report.summary.totalCompletions = recentCompletions.length;
        report.summary.totalErrors = recentCompletions.filter(c => !c.success).length;
        report.summary.totalTokensUsed = recentCompletions.reduce((sum, c) => sum + c.tokensUsed, 0);

        // Analisi per agent
        const agentStats = new Map();

        recentCompletions.forEach(completion => {
            if (!agentStats.has(completion.agentId)) {
                agentStats.set(completion.agentId, {
                    agentId: completion.agentId,
                    agentType: completion.agentType,
                    completions: 0,
                    successes: 0,
                    totalTime: 0,
                    totalTokens: 0,
                    totalQuality: 0
                });
            }

            const stats = agentStats.get(completion.agentId);
            stats.completions++;
            if (completion.success) stats.successes++;
            stats.totalTime += completion.executionTime;
            stats.totalTokens += completion.tokensUsed;
            stats.totalQuality += completion.quality;
        });

        // Calcola metriche per ogni agent
        agentStats.forEach((stats, agentId) => {
            const metrics = this.metrics.agents.get(agentId);

            const comparison = {
                agentId: stats.agentId,
                agentType: stats.agentType,
                agentName: metrics?.agentType || 'Unknown',
                completions: stats.completions,
                successRate: stats.completions > 0 ? (stats.successes / stats.completions) * 100 : 0,
                averageTime: stats.completions > 0 ? stats.totalTime / stats.completions : 0,
                averageTokens: stats.completions > 0 ? stats.totalTokens / stats.completions : 0,
                averageQuality: stats.completions > 0 ? stats.totalQuality / stats.completions : 0,
                tokenPerMinute: (stats.totalTime / (1000 * 60)) > 0 ? stats.totalTokens / (stats.totalTime / (1000 * 60)) : 0,
                efficiency: (stats.totalTime / (1000 * 60)) > 0 ? stats.successes / (stats.totalTime / (1000 * 60)) : 0
            };

            report.agentComparisons.push(comparison);
        });

        // Ordina top performers
        report.topPerformers.bySuccessRate = [...report.agentComparisons]
            .sort((a, b) => b.successRate - a.successRate)
            .slice(0, 5);

        report.topPerformers.bySpeed = [...report.agentComparisons]
            .sort((a, b) => a.averageTime - b.averageTime)
            .slice(0, 5);

        report.topPerformers.byEfficiency = [...report.agentComparisons]
            .sort((a, b) => b.efficiency - a.efficiency)
            .slice(0, 5);

        report.topPerformers.byTokenRate = [...report.agentComparisons]
            .sort((a, b) => b.tokenPerMinute - a.tokenPerMinute)
            .slice(0, 5);

        // Calcola summary medie
        if (report.agentComparisons.length > 0) {
            report.summary.averageSuccessRate = report.agentComparisons
                .reduce((sum, a) => sum + a.successRate, 0) / report.agentComparisons.length;

            report.summary.averageResponseTime = report.agentComparisons
                .reduce((sum, a) => sum + a.averageTime, 0) / report.agentComparisons.length;
        }

        // Genera trends
        report.trends = this.generateTrendData(cutoffTime);

        return report;
    }

    /**
     * Genera dati di trend
     */
    generateTrendData(cutoffTime) {
        const recentCompletions = this.metrics.completions.filter(c => c.timestamp > cutoffTime);
        const hourlyBuckets = new Map();

        // Raggruppa per ora
        recentCompletions.forEach(completion => {
            const hour = Math.floor(completion.timestamp / (1000 * 60 * 60));

            if (!hourlyBuckets.has(hour)) {
                hourlyBuckets.set(hour, {
                    timestamp: hour * 1000 * 60 * 60,
                    completions: 0,
                    successes: 0,
                    errors: 0,
                    totalTime: 0,
                    totalTokens: 0
                });
            }

            const bucket = hourlyBuckets.get(hour);
            bucket.completions++;
            if (completion.success) bucket.successes++;
            else bucket.errors++;
            bucket.totalTime += completion.executionTime;
            bucket.totalTokens += completion.tokensUsed;
        });

        // Converti in arrays ordinati
        const sortedBuckets = Array.from(hourlyBuckets.values())
            .sort((a, b) => a.timestamp - b.timestamp);

        return {
            completionTrend: sortedBuckets.map(b => ({
                timestamp: b.timestamp,
                value: b.completions
            })),
            errorTrend: sortedBuckets.map(b => ({
                timestamp: b.timestamp,
                value: b.errors
            })),
            performanceTrend: sortedBuckets.map(b => ({
                timestamp: b.timestamp,
                value: b.completions > 0 ? b.totalTime / b.completions : 0
            }))
        };
    }

    /**
     * Genera prediction ETA basata su analytics
     */
    generateETA(agentType, taskComplexity = 'medium') {
        const agentMetrics = Array.from(this.metrics.agents.values())
            .filter(m => m.agentType === agentType);

        if (agentMetrics.length === 0) {
            return {
                estimated: null,
                confidence: 0,
                reason: 'Nessun dato storico disponibile per questo tipo di agent'
            };
        }

        // Calcola tempi medi per complessità
        const complexityMultiplier = {
            simple: 0.7,
            medium: 1.0,
            complex: 1.5,
            very_complex: 2.2
        };

        const multiplier = complexityMultiplier[taskComplexity] || 1.0;

        // Media ponderata dei tempi di esecuzione recenti
        const recentHistory = agentMetrics
            .flatMap(m => m.performanceHistory.slice(-20))
            .filter(h => h.success);

        if (recentHistory.length === 0) {
            return {
                estimated: null,
                confidence: 0,
                reason: 'Nessun completamento riuscito recente per questo agent type'
            };
        }

        // Calcola stima
        const avgTime = recentHistory.reduce((sum, h) => sum + h.executionTime, 0) / recentHistory.length;
        const stdDev = Math.sqrt(
            recentHistory.reduce((sum, h) => sum + Math.pow(h.executionTime - avgTime, 2), 0) / recentHistory.length
        );

        const estimatedTime = avgTime * multiplier;
        const confidence = Math.max(0, Math.min(100, 100 - (stdDev / avgTime) * 50));

        return {
            estimated: Math.round(estimatedTime),
            confidence: Math.round(confidence),
            range: {
                min: Math.round(estimatedTime - stdDev),
                max: Math.round(estimatedTime + stdDev)
            },
            basedOnSamples: recentHistory.length,
            reason: `Basato su ${recentHistory.length} completamenti recenti`
        };
    }

    /**
     * Sistema di alert per anomalie
     */
    checkAlertConditions(agentId) {
        if (!this.options.enableAlerts) return;

        const metrics = this.metrics.agents.get(agentId);
        if (!metrics) return;

        const alerts = [];
        const thresholds = this.options.alertThresholds;

        // Success rate troppo basso
        if (metrics.successRate < thresholds.successRateBelow && metrics.totalSessions >= 5) {
            alerts.push({
                type: 'LOW_SUCCESS_RATE',
                severity: 'warning',
                message: `Success rate basso per ${metrics.agentType}: ${metrics.successRate.toFixed(1)}%`,
                value: metrics.successRate,
                threshold: thresholds.successRateBelow,
                agentId
            });
        }

        // Tempo di risposta troppo alto
        if (metrics.averageResponseTime > thresholds.avgResponseTimeAbove && metrics.totalSessions >= 3) {
            alerts.push({
                type: 'HIGH_RESPONSE_TIME',
                severity: 'warning',
                message: `Tempo di risposta alto per ${metrics.agentType}: ${metrics.averageResponseTime}ms`,
                value: metrics.averageResponseTime,
                threshold: thresholds.avgResponseTimeAbove,
                agentId
            });
        }

        // Token rate troppo basso
        if (metrics.tokenPerMinuteRate < thresholds.tokenRateBelow && metrics.totalSessions >= 3) {
            alerts.push({
                type: 'LOW_TOKEN_RATE',
                severity: 'info',
                message: `Token rate basso per ${metrics.agentType}: ${metrics.tokenPerMinuteRate.toFixed(1)} token/min`,
                value: metrics.tokenPerMinuteRate,
                threshold: thresholds.tokenRateBelow,
                agentId
            });
        }

        // Error rate troppo alto
        const errorRate = metrics.totalSessions > 0 ? (metrics.totalErrors / metrics.totalSessions) * 100 : 0;
        if (errorRate > thresholds.errorRateAbove && metrics.totalSessions >= 3) {
            alerts.push({
                type: 'HIGH_ERROR_RATE',
                severity: 'error',
                message: `Error rate alto per ${metrics.agentType}: ${errorRate.toFixed(1)}%`,
                value: errorRate,
                threshold: thresholds.errorRateAbove,
                agentId
            });
        }

        // Processa nuovi alert
        alerts.forEach(alert => this.processAlert(alert));
    }

    /**
     * Processa un alert
     */
    processAlert(alert) {
        const alertId = `${alert.type}_${alert.agentId}_${Date.now()}`;
        alert.id = alertId;
        alert.timestamp = Date.now();
        alert.acknowledged = false;

        // Evita duplicati recenti
        const recentSimilar = this.alerts.history
            .filter(a => a.type === alert.type && a.agentId === alert.agentId)
            .filter(a => (Date.now() - a.timestamp) < 300000); // 5 minuti

        if (recentSimilar.length > 0) {
            return; // Skip duplicato
        }

        // Aggiungi agli alert attivi
        this.alerts.active.set(alertId, alert);

        // Aggiungi alla history
        this.alerts.history.push(alert);

        // Mantieni history limitata
        if (this.alerts.history.length > 1000) {
            this.alerts.history = this.alerts.history.slice(-1000);
        }

        // Emetti evento
        this.emit('alert-triggered', alert);

        // Notifica subscribers
        this.alerts.subscribers.forEach(subscriber => {
            try {
                subscriber(alert);
            } catch (error) {
                console.error('Errore in alert subscriber:', error);
            }
        });

        if (this.options.enableLogging) {
            const severityEmoji = {
                info: '💡',
                warning: '⚠️ ',
                error: '🚨'
            };
            console.log(`${severityEmoji[alert.severity]} ALERT: ${alert.message}`);
        }
    }

    /**
     * Visualizzazione real-time dello stato
     */
    getRealTimeStatus() {
        const now = Date.now();
        const activeSessions = Array.from(this.metrics.sessions.values());
        const recentCompletions = this.metrics.completions
            .filter(c => (now - c.timestamp) < 300000) // Ultimi 5 minuti
            .length;

        return {
            timestamp: now,
            activeSessions: {
                count: activeSessions.length,
                byType: this.groupBy(activeSessions, 'agentType'),
                longestRunning: activeSessions.length > 0
                    ? Math.max(...activeSessions.map(s => now - s.startTime))
                    : 0
            },
            recentActivity: {
                completions: recentCompletions,
                successRate: this.calculateRecentSuccessRate(),
                avgResponseTime: this.calculateRecentAvgResponseTime(),
                activeAlerts: this.alerts.active.size
            },
            resourceUtilization: {
                memory: process.memoryUsage(),
                uptime: process.uptime(),
                sessionsActive: this.counters.sessionsActive
            },
            trends: {
                completionRate: this.calculateCompletionRate(),
                tokenRate: this.calculateTokenRate(),
                errorRate: this.calculateErrorRate()
            }
        };
    }

    /**
     * Utility functions
     */
    generateSessionId() {
        return `sess_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    parseTimeRange(range) {
        const multipliers = {
            h: 60 * 60 * 1000,
            d: 24 * 60 * 60 * 1000,
            w: 7 * 24 * 60 * 60 * 1000
        };

        const match = range.match(/^(\d+)([hdw])$/);
        if (!match) return 24 * 60 * 60 * 1000; // Default 24h

        return parseInt(match[1]) * multipliers[match[2]];
    }

    groupBy(array, key) {
        return array.reduce((groups, item) => {
            const value = item[key];
            groups[value] = groups[value] || [];
            groups[value].push(item);
            return groups;
        }, {});
    }

    calculateRecentSuccessRate() {
        const recent = this.metrics.completions.slice(-20);
        if (recent.length === 0) return 0;

        const successes = recent.filter(c => c.success).length;
        return (successes / recent.length) * 100;
    }

    calculateRecentAvgResponseTime() {
        const recent = this.metrics.completions.slice(-20);
        if (recent.length === 0) return 0;

        return recent.reduce((sum, c) => sum + c.executionTime, 0) / recent.length;
    }

    calculateCompletionRate() {
        const now = Date.now();
        const lastHour = this.metrics.completions
            .filter(c => (now - c.timestamp) < 3600000)
            .length;

        return lastHour; // completions per hour
    }

    calculateTokenRate() {
        const now = Date.now();
        const lastHour = this.metrics.completions
            .filter(c => (now - c.timestamp) < 3600000);

        if (lastHour.length === 0) return 0;

        const totalTokens = lastHour.reduce((sum, c) => sum + c.tokensUsed, 0);
        return totalTokens / (60); // tokens per minute
    }

    calculateErrorRate() {
        const recent = this.metrics.completions.slice(-50);
        if (recent.length === 0) return 0;

        const errors = recent.filter(c => !c.success).length;
        return (errors / recent.length) * 100;
    }

    /**
     * Avvia collection automatica
     */
    startDataCollection() {
        // Raccolta metriche ogni 30 secondi
        this.dataCollectionInterval = setInterval(() => {
            this.collectSystemMetrics();
        }, 30000);

        console.log('📊 Data collection avviata');
    }

    /**
     * Avvia sistema di alert
     */
    startAlertSystem() {
        // Controllo alert ogni minuto
        this.alertCheckInterval = setInterval(() => {
            this.runAlertChecks();
        }, 60000);

        console.log('🚨 Alert system avviato');
    }

    /**
     * Avvia salvataggio periodico
     */
    startPeriodicSave() {
        this.saveInterval = setInterval(() => {
            this.saveMetricsToFile();
        }, this.options.saveInterval);

        console.log('💾 Salvataggio periodico avviato');
    }

    /**
     * Raccolta metriche di sistema
     */
    collectSystemMetrics() {
        const now = Date.now();
        const memUsage = process.memoryUsage();

        const systemMetrics = {
            timestamp: now,
            memory: {
                used: memUsage.heapUsed,
                total: memUsage.heapTotal,
                external: memUsage.external,
                rss: memUsage.rss
            },
            uptime: process.uptime(),
            activeSessions: this.counters.sessionsActive,
            totalCompletions: this.counters.totalCompletions,
            totalErrors: this.counters.totalErrors
        };

        this.metrics.resources.set(now, systemMetrics);

        // Mantieni solo ultimi 1000 punti
        if (this.metrics.resources.size > 1000) {
            const keys = Array.from(this.metrics.resources.keys()).sort((a, b) => a - b);
            const toRemove = keys.slice(0, keys.length - 1000);
            toRemove.forEach(key => this.metrics.resources.delete(key));
        }
    }

    /**
     * Esegue controlli di alert
     */
    runAlertChecks() {
        // Controllo utilizzo risorse
        const latestResource = Array.from(this.metrics.resources.values()).pop();
        if (latestResource) {
            const memUtilization = (latestResource.memory.used / latestResource.memory.total) * 100;

            if (memUtilization > this.options.alertThresholds.resourceUtilizationAbove) {
                this.processAlert({
                    type: 'HIGH_MEMORY_USAGE',
                    severity: 'warning',
                    message: `Utilizzo memoria alto: ${memUtilization.toFixed(1)}%`,
                    value: memUtilization,
                    threshold: this.options.alertThresholds.resourceUtilizationAbove,
                    agentId: 'system'
                });
            }
        }

        // Rimuovi alert vecchi dal set attivo
        const alertTimeout = 30 * 60 * 1000; // 30 minuti
        const now = Date.now();

        this.alerts.active.forEach((alert, alertId) => {
            if ((now - alert.timestamp) > alertTimeout) {
                this.alerts.active.delete(alertId);
            }
        });
    }

    /**
     * Salva metriche su file
     */
    async saveMetricsToFile() {
        try {
            const data = {
                timestamp: new Date().toISOString(),
                counters: this.counters,
                agents: Object.fromEntries(this.metrics.agents),
                completions: this.metrics.completions,
                performance: Object.fromEntries(this.metrics.performance),
                resources: Object.fromEntries(Array.from(this.metrics.resources.entries()).slice(-100))
            };

            fs.writeFileSync(this.metricsPath, JSON.stringify(data, null, 2));

            // Salva alert
            const alertData = {
                timestamp: new Date().toISOString(),
                active: Object.fromEntries(this.alerts.active),
                history: this.alerts.history.slice(-500)
            };

            fs.writeFileSync(this.alertsPath, JSON.stringify(alertData, null, 2));

        } catch (error) {
            console.error('❌ Errore nel salvataggio metriche:', error);
        }
    }

    /**
     * Esporta report completo
     */
    exportAnalyticsReport(format = 'json', timeRange = '24h') {
        const report = {
            metadata: {
                exportedAt: new Date().toISOString(),
                timeRange,
                format,
                version: '1.0'
            },
            summary: this.generateSummaryReport(timeRange),
            comparative: this.generateComparativeReport(timeRange),
            realTime: this.getRealTimeStatus(),
            alerts: {
                active: Object.fromEntries(this.alerts.active),
                recentHistory: this.alerts.history.slice(-50)
            },
            predictions: this.generatePredictionsReport()
        };

        const filename = `analytics_report_${Date.now()}.${format}`;
        const exportPath = path.join(this.dataPath, 'exports', filename);

        if (format === 'json') {
            fs.writeFileSync(exportPath, JSON.stringify(report, null, 2));
        } else if (format === 'csv') {
            // Implementazione CSV se necessaria
            const csv = this.convertToCSV(report);
            fs.writeFileSync(exportPath, csv);
        }

        return {
            filename,
            path: exportPath,
            size: fs.statSync(exportPath).size,
            report
        };
    }

    /**
     * Genera report summary
     */
    generateSummaryReport(timeRange) {
        const now = Date.now();
        const cutoff = now - this.parseTimeRange(timeRange);
        const recent = this.metrics.completions.filter(c => c.timestamp > cutoff);

        return {
            timeRange,
            totalCompletions: recent.length,
            successfulCompletions: recent.filter(c => c.success).length,
            failedCompletions: recent.filter(c => !c.success).length,
            totalTokensUsed: recent.reduce((sum, c) => sum + c.tokensUsed, 0),
            averageExecutionTime: recent.length > 0
                ? recent.reduce((sum, c) => sum + c.executionTime, 0) / recent.length
                : 0,
            uniqueAgents: new Set(recent.map(c => c.agentId)).size,
            activeAlerts: this.alerts.active.size
        };
    }

    /**
     * Genera report predictions
     */
    generatePredictionsReport() {
        const agentTypes = new Set(Array.from(this.metrics.agents.values()).map(a => a.agentType));
        const predictions = {};

        agentTypes.forEach(type => {
            predictions[type] = {
                simple: this.generateETA(type, 'simple'),
                medium: this.generateETA(type, 'medium'),
                complex: this.generateETA(type, 'complex')
            };
        });

        return predictions;
    }

    /**
     * Subscribe ad alert
     */
    subscribeToAlerts(callback) {
        this.alerts.subscribers.push(callback);
        return () => {
            const index = this.alerts.subscribers.indexOf(callback);
            if (index > -1) {
                this.alerts.subscribers.splice(index, 1);
            }
        };
    }

    /**
     * Ottieni statistiche agent specifico
     */
    getAgentStats(agentId) {
        const metrics = this.metrics.agents.get(agentId);
        if (!metrics) return null;

        const recentCompletions = this.metrics.completions
            .filter(c => c.agentId === agentId)
            .slice(-50);

        return {
            ...metrics,
            recentPerformance: {
                completions: recentCompletions.length,
                successRate: recentCompletions.length > 0
                    ? (recentCompletions.filter(c => c.success).length / recentCompletions.length) * 100
                    : 0,
                averageTime: recentCompletions.length > 0
                    ? recentCompletions.reduce((sum, c) => sum + c.executionTime, 0) / recentCompletions.length
                    : 0,
                trend: this.calculateTrendDirection(recentCompletions)
            },
            errorPatterns: Object.fromEntries(metrics.errorPatterns),
            predictions: {
                nextTask: this.generateETA(metrics.agentType, 'medium')
            }
        };
    }

    /**
     * Calcola direzione del trend
     */
    calculateTrendDirection(completions) {
        if (completions.length < 10) return 'insufficient_data';

        const recent = completions.slice(-5);
        const previous = completions.slice(-10, -5);

        if (recent.length === 0 || previous.length === 0) return 'insufficient_data';

        const recentAvg = recent.reduce((sum, c) => sum + c.executionTime, 0) / recent.length;
        const previousAvg = previous.reduce((sum, c) => sum + c.executionTime, 0) / previous.length;

        const change = ((recentAvg - previousAvg) / previousAvg) * 100;

        if (Math.abs(change) < 5) return 'stable';
        return change > 0 ? 'declining' : 'improving';
    }

    /**
     * Cleanup e shutdown
     */
    shutdown() {
        console.log('🔄 Shutdown Dashboard Analytics...');

        // Salva dati finali
        this.saveMetricsToFile();

        // Ferma tutti gli interval
        if (this.dataCollectionInterval) {
            clearInterval(this.dataCollectionInterval);
        }

        if (this.alertCheckInterval) {
            clearInterval(this.alertCheckInterval);
        }

        if (this.saveInterval) {
            clearInterval(this.saveInterval);
        }

        console.log('✅ Dashboard Analytics terminato');
        this.emit('analytics-shutdown');
    }
}

// Export per uso come modulo
module.exports = DashboardAnalytics;

// Esecuzione diretta per demo/test
if (require.main === module) {
    const analytics = new DashboardAnalytics({
        enableLogging: true,
        enableAlerts: true
    });

    // Demo usage
    setTimeout(() => {
        console.log('\n🧪 Demo analytics...\n');

        // Simula alcune sessioni
        const sessionId1 = analytics.registerAgentSessionStart('agent1', 'coder', { task: 'implement feature' });
        const sessionId2 = analytics.registerAgentSessionStart('agent2', 'analyzer', { task: 'code review' });

        // Simula aggiornamenti
        setTimeout(() => {
            analytics.updateSessionMetrics(sessionId1, { tokensUsed: 150, tasksCompleted: 1 });
            analytics.updateSessionMetrics(sessionId2, { tokensUsed: 80 });
        }, 1000);

        // Simula completamenti
        setTimeout(() => {
            analytics.registerAgentCompletion(sessionId1, { success: true, quality: 85 });
            analytics.registerAgentCompletion(sessionId2, { success: true, quality: 92 });

            // Genera e mostra report
            const report = analytics.generateComparativeReport('1h');
            console.log('📊 Report comparativo:');
            console.table(report.agentComparisons);

            // Mostra status real-time
            console.log('\n📈 Status real-time:');
            console.log(JSON.stringify(analytics.getRealTimeStatus(), null, 2));

            // Esporta report
            const exportResult = analytics.exportAnalyticsReport('json', '1h');
            console.log(`\n💾 Report esportato: ${exportResult.filename}`);

        }, 2000);

    }, 1000);

    // Graceful shutdown
    process.on('SIGINT', () => {
        analytics.shutdown();
        process.exit(0);
    });
}
# Piano: Estensione VS Code "Claude-ZAI Router"

## Obiettivo
Creare un'estensione VS Code per il Marketplace che permetta di usare `@zai` e `@claude` nella chat, con timeout differenziati e gestione dinamica dei provider.

## Decisioni Utente
- **Invocazione**: `@zai` e `@claude` nella chat di VS Code
- **Provider**: Supporto sia ZAI che Anthropic API
- **Distribuzione**: Pubblicazione su VS Code Marketplace

## Architettura

### Chat Participants (VS Code 1.92+)
Due partecipanti registrati nella chat:
- `@zai` → API ZAI (timeout 50 min)
- `@claude` → API Anthropic (timeout 30 sec, richiede API key)

### Struttura Estensione
```
claude-zai-extension/
├── package.json              # Manifest + marketplace metadata
├── src/
│   ├── extension.ts          # Entry point, registra participants
│   ├── participants/
│   │   ├── zai-participant.ts    # Handler @zai
│   │   └── claude-participant.ts # Handler @claude
│   ├── providers/
│   │   ├── base-provider.ts      # Classe base (dal proxy)
│   │   ├── zai-provider.ts       # Client ZAI
│   │   └── anthropic-provider.ts # Client Anthropic
│   ├── services/
│   │   ├── secrets.ts            # Gestione API key sicura
│   │   ├── config.ts             # Settings VS Code
│   │   └── status-bar.ts         # Indicatore stato
│   └── utils/
│       ├── errors.ts             # Tipi errore (dal proxy)
│       └── logger.ts             # Output channel
├── media/
│   └── icon.png              # Icona estensione
├── tsconfig.json
├── .vscodeignore
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Funzionalità

### 1. Chat Participant `@zai`
```
@zai spiega questo codice
```
- Invia a `https://api.z.ai/api/anthropic/v1/messages`
- Timeout: 50 minuti (3.000.000 ms)
- Streaming della risposta
- Indicatore di progresso

### 2. Chat Participant `@claude`
```
@claude refactorizza questa funzione
```
- Invia a `https://api.anthropic.com/v1/messages`
- Timeout: 30 secondi
- Richiede API key Anthropic valida (sk-ant-...)
- Errore chiaro se non configurata

### 3. Comandi
| Comando | Descrizione |
|---------|-------------|
| `Claude-ZAI: Configura ZAI API Key` | Setup chiave ZAI |
| `Claude-ZAI: Configura Anthropic API Key` | Setup chiave Anthropic |
| `Claude-ZAI: Verifica Configurazione` | Health check provider |

### 4. Status Bar
- `$(cloud) ZAI` - Verde se configurato
- Click → mostra stato dettagliato

### 5. Settings (settings.json)
```json
{
  "claude-zai.zai.baseUrl": "https://api.z.ai/api/anthropic",
  "claude-zai.zai.timeout": 3000000,
  "claude-zai.anthropic.baseUrl": "https://api.anthropic.com",
  "claude-zai.anthropic.timeout": 30000,
  "claude-zai.defaultModel": "claude-sonnet-4-20250514"
}
```

## File Critici

### 1. package.json
```json
{
  "name": "claude-zai-router",
  "displayName": "Claude-ZAI Router",
  "description": "Route requests between ZAI and Anthropic with extended timeouts",
  "version": "1.0.0",
  "publisher": "your-publisher-id",
  "engines": { "vscode": "^1.92.0" },
  "categories": ["Chat"],
  "activationEvents": ["onStartupFinished"],
  "main": "./out/extension.js",
  "contributes": {
    "chatParticipants": [
      {
        "id": "zai",
        "name": "zai",
        "description": "Send requests to ZAI with 50-minute timeout",
        "isSticky": false
      },
      {
        "id": "claude-api",
        "name": "claude",
        "description": "Send requests to Anthropic API directly",
        "isSticky": false
      }
    ],
    "commands": [...],
    "configuration": {...}
  }
}
```

### 2. src/extension.ts
- Registra entrambi i chat participants
- Inizializza status bar
- Carica API keys da SecretStorage
- Verifica disponibilità provider

### 3. src/participants/zai-participant.ts
- Handler per `@zai`
- Usa `vscode.chat.createChatParticipant()`
- Stream risposta con `stream.markdown()`
- Gestisce abort con CancellationToken

### 4. src/providers/zai-provider.ts
- Adattamento di `src/providers/zai.js` esistente
- Usa `fetch` nativo (Node 18+)
- AbortController per timeout

## Flusso Implementazione

1. **Setup progetto** (5 file)
   - Inizializza npm, TypeScript, esbuild
   - Crea package.json con metadata Marketplace

2. **Provider** (3 file)
   - Porta logica da proxy esistente
   - Adatta per VS Code (fetch, secrets)

3. **Participants** (2 file)
   - Implementa handler @zai
   - Implementa handler @claude

4. **UI** (3 file)
   - Status bar
   - Comandi configurazione
   - Output channel per log

5. **Pubblicazione**
   - Crea publisher su marketplace
   - Package con `vsce`
   - Pubblica

## Verifica
1. `npm run compile` - compila senza errori
2. `F5` in VS Code - avvia Extension Host
3. Nella chat: `@zai ciao` → risposta da ZAI
4. Nella chat: `@claude ciao` → errore se no API key, risposta se configurata
5. `Claude-ZAI: Verifica Configurazione` → mostra stato provider
6. Test timeout: richiesta lunga con @zai non va in timeout

## Note Marketplace
- Serve account Microsoft/Azure DevOps
- Publisher ID unico
- Icona 128x128 PNG
- README con screenshot
- CHANGELOG aggiornato

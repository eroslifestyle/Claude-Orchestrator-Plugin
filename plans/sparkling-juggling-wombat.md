# Piano: Telegram_STA (Standalone per VPS)

## Configurazione Richiesta
- **GUI:** Completa (PyQt5)
- **Licenze:** RIMOSSE
- **CSV:** Modulo completo
- **cTrader:** ESCLUSO

---

## Analisi Dipendenze

### File da Copiare
```
Telegram_STA/
├── TELEGRAM/              # Intero modulo (core + gui + src)
├── GUI/
│   └── styles/            # Solo cartella styles (dipendenza import)
│       ├── __init__.py
│       ├── mastercopy_theme.py
│       ├── colors.py
│       ├── unified_theme.py
│       ├── constants.py
│       ├── button_styles.py
│       ├── phantom_design.py
│       └── components.py
├── data/                  # Directory vuota per config runtime
├── logs/                  # Directory vuota per log
├── run.py                 # Entry point semplificato (NUOVO)
├── requirements.txt       # Dipendenze Python (NUOVO)
└── README.md              # Documentazione (NUOVO)
```

### Da NON Copiare
- `LICENSE_MANAGER/` - Rimosso come richiesto
- `CTRADER/` - Escluso come richiesto
- `APP_CORE/` - Non usato da TELEGRAM standalone
- `METATRADER/` - Non richiesto
- `BETA_TEST/` - Non necessario
- `documents/` - Solo documentazione
- `scripts/` - Script di sviluppo
- `tests/` root - Test integrazione

---

## Modifiche Necessarie

### 1. Rimuovere Controllo Licenze
**File:** `TELEGRAM/gui/dialogs/license_dialog.py`
- Bypassare validazione licenza
- Restituire sempre licenza valida

**File:** `TELEGRAM/gui/main_window_tray.py`
- Rimuovere import LICENSE_MANAGER
- Rimuovere controlli licenza

### 2. Nuovo Entry Point (run.py)
```python
#!/usr/bin/env python
"""Telegram Standalone - Entry Point"""
import sys
from pathlib import Path

# Setup paths
base = Path(__file__).parent.resolve()
sys.path.insert(0, str(base))
sys.path.insert(0, str(base / "TELEGRAM"))
sys.path.insert(0, str(base / "TELEGRAM" / "src"))
sys.path.insert(0, str(base / "TELEGRAM" / "gui"))

# Avvia GUI
from TELEGRAM.gui.main_window_tray import run_telegram_gui
sys.exit(run_telegram_gui())
```

### 3. requirements.txt
```
PyQt5>=5.15
python-dotenv>=1.0.0
telethon>=1.34.0
aiohttp>=3.9.0
cryptography>=41.0.0
```

---

## Esecuzione

### Task Paralleli (Fase 1)
| # | Task | Agent |
|---|------|-------|
| T1 | Creare struttura directory Telegram_STA | Coder |
| T2 | Copiare TELEGRAM/ | Coder |
| T3 | Copiare GUI/styles/ | Coder |

### Task Sequenziali (Fase 2)
| # | Task | Dipende | Agent |
|---|------|---------|-------|
| T4 | Modificare license_dialog.py (bypass) | T2 | Coder |
| T5 | Creare run.py entry point | T1 | Coder |
| T6 | Creare requirements.txt | T1 | Coder |
| T7 | Creare README.md | T5,T6 | Documenter |

---

## Verifica

1. **Struttura:** `ls -la Telegram_STA/`
2. **Import Test:** `python -c "import sys; sys.path.insert(0,'Telegram_STA'); from TELEGRAM.gui.main_window_tray import MainWindowTray"`
3. **Avvio GUI:** `python Telegram_STA/run.py`

---

## File Critici da Modificare

1. `Telegram_STA/TELEGRAM/gui/dialogs/license_dialog.py` - Bypass licenza
2. `Telegram_STA/TELEGRAM/gui/main_window_tray.py` - Rimuovi import LICENSE_MANAGER
3. `Telegram_STA/run.py` - Nuovo entry point

---

## Stima

- **Directory da copiare:** 2 (TELEGRAM, GUI/styles)
- **File da creare:** 3 (run.py, requirements.txt, README.md)
- **File da modificare:** 2-3 (bypass licenze)

---
name: MQL Optimization L2
description: L2 specialist for EA performance, memory management, and tick processing
---

# MQL Optimization - L2 Sub-Agent

> **Parent:** mql_expert.md
> **Level:** L2 (Sub-Agent)
> **Model:** sonnet
> **Specializzazione:** EA Performance, Memory Optimization, Tick Processing

---

## EXPERTISE

- CPU optimization per EA
- Memory management MQL5
- Array pre-allocation
- Symbol data caching
- Timer optimization
- Tick processing efficiency
- Handle management
- Indicator buffer optimization
- Multi-symbol EA
- Backtesting performance

---

## PATTERN COMUNI

### 1. Array Pre-Allocation

```mql5
// ❌ SBAGLIATO
void OnTick_Bad() {
    double prices[];
    ArrayResize(prices, 100);  // Ogni tick!
    CopyClose(_Symbol, 0, 0, 100, prices);
}

// ✅ CORRETTO
class CArrayManager {
private:
    double m_prices[];
    int m_size;

public:
    CArrayManager() {
        m_size = 1000;
        ArrayResize(m_prices, m_size, m_size);
        ArraySetAsSeries(m_prices, true);
    }

    bool Update(int count) {
        if(count > m_size) {
            m_size = count + 500;
            ArrayResize(m_prices, m_size, 500);
        }
        return CopyClose(_Symbol, 0, 0, count, m_prices) == count;
    }

    double Get(int i) { return m_prices[i]; }
};

CArrayManager g_arrays;
void OnTick() {
    g_arrays.Update(100);
    double price = g_arrays.Get(0);
}
```

### 2. Symbol Cache

```mql5
class CSymbolCache {
private:
    string m_symbol;
    double m_point;
    double m_ticksize;
    int m_digits;
    double m_lotstep;
    double m_minlot;
    double m_maxlot;

public:
    bool Init(string symbol) {
        if(m_symbol == symbol) return true;
        m_symbol = symbol;
        m_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        m_ticksize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        m_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        m_lotstep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        m_minlot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        m_maxlot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        return true;
    }

    double Point() { return m_point; }
    int Digits() { return m_digits; }

    double NormalizeLots(double lots) {
        lots = MathMax(lots, m_minlot);
        lots = MathMin(lots, m_maxlot);
        return MathFloor(lots / m_lotstep) * m_lotstep;
    }

    double NormalizePrice(double price) {
        return NormalizeDouble(MathRound(price / m_ticksize) * m_ticksize, m_digits);
    }
};

CSymbolCache g_cache;
int OnInit() {
    g_cache.Init(_Symbol);
    return INIT_SUCCEEDED;
}
```

### 3. Timer Manager

```mql5
class CTimerManager {
private:
    datetime m_last_hour;
    datetime m_last_day;
    int m_tick_count;
    int m_ticks_per_check;

public:
    CTimerManager() : m_tick_count(0), m_ticks_per_check(100) {}

    bool ShouldCheckHourly() {
        datetime now = TimeCurrent();
        if(now >= m_last_hour + 3600) {
            m_last_hour = now;
            return true;
        }
        return false;
    }

    bool ShouldCheckDaily() {
        datetime now = TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(now, dt);
        if(dt.hour == 0 && dt.min == 0 && now > m_last_day + 86000) {
            m_last_day = now;
            return true;
        }
        return false;
    }

    bool ShouldProcessHeavy() {
        m_tick_count++;
        if(m_tick_count >= m_ticks_per_check) {
            m_tick_count = 0;
            return true;
        }
        return false;
    }
};

CTimerManager g_timer;
void OnTick() {
    ProcessLight();
    if(g_timer.ShouldProcessHeavy()) ProcessHeavy();
    if(g_timer.ShouldCheckHourly()) UpdateStats();
}
```

### 4. Indicator Handle Manager

```mql5
class CIndicatorManager {
private:
    int m_ma_fast;
    int m_ma_slow;
    int m_rsi;
    double m_ma_fast_buf[];
    double m_ma_slow_buf[];
    double m_rsi_buf[];
    bool m_init;

public:
    CIndicatorManager() : m_init(false), m_ma_fast(INVALID_HANDLE),
        m_ma_slow(INVALID_HANDLE), m_rsi(INVALID_HANDLE) {}

    ~CIndicatorManager() { Release(); }

    bool Init(string symbol, ENUM_TIMEFRAMES tf) {
        if(m_init) return true;

        m_ma_fast = iMA(symbol, tf, 20, 0, MODE_EMA, PRICE_CLOSE);
        m_ma_slow = iMA(symbol, tf, 50, 0, MODE_EMA, PRICE_CLOSE);
        m_rsi = iRSI(symbol, tf, 14, PRICE_CLOSE);

        if(m_ma_fast == INVALID_HANDLE || m_ma_slow == INVALID_HANDLE ||
           m_rsi == INVALID_HANDLE) {
            Release();
            return false;
        }

        ArraySetAsSeries(m_ma_fast_buf, true);
        ArraySetAsSeries(m_ma_slow_buf, true);
        ArraySetAsSeries(m_rsi_buf, true);
        ArrayResize(m_ma_fast_buf, 10, 10);
        ArrayResize(m_ma_slow_buf, 10, 10);
        ArrayResize(m_rsi_buf, 10, 10);

        m_init = true;
        return true;
    }

    void Release() {
        if(m_ma_fast != INVALID_HANDLE) IndicatorRelease(m_ma_fast);
        if(m_ma_slow != INVALID_HANDLE) IndicatorRelease(m_ma_slow);
        if(m_rsi != INVALID_HANDLE) IndicatorRelease(m_rsi);
        m_ma_fast = m_ma_slow = m_rsi = INVALID_HANDLE;
        m_init = false;
    }

    bool Update(int count = 3) {
        if(!m_init) return false;
        if(CopyBuffer(m_ma_fast, 0, 0, count, m_ma_fast_buf) != count) return false;
        if(CopyBuffer(m_ma_slow, 0, 0, count, m_ma_slow_buf) != count) return false;
        if(CopyBuffer(m_rsi, 0, 0, count, m_rsi_buf) != count) return false;
        return true;
    }

    double MAFast(int i = 0) { return m_ma_fast_buf[i]; }
    double MASlow(int i = 0) { return m_ma_slow_buf[i]; }
    double RSI(int i = 0) { return m_rsi_buf[i]; }
    bool BullishCross() { return m_ma_fast_buf[1] < m_ma_slow_buf[1] && m_ma_fast_buf[0] > m_ma_slow_buf[0]; }
    bool BearishCross() { return m_ma_fast_buf[1] > m_ma_slow_buf[1] && m_ma_fast_buf[0] < m_ma_slow_buf[0]; }
};

CIndicatorManager g_ind;
int OnInit() { return g_ind.Init(_Symbol, PERIOD_CURRENT) ? INIT_SUCCEEDED : INIT_FAILED; }
void OnDeinit(const int r) { g_ind.Release(); }
```

### 5. Multi-Symbol Manager

```mql5
class CMultiSymbol {
private:
    struct SymbolData {
        string symbol;
        double bid, ask;
        datetime update;
        CSymbolCache cache;
        CIndicatorManager ind;
    };
    SymbolData m_sym[];
    int m_count;

public:
    bool Init(string &symbols[]) {
        m_count = ArraySize(symbols);
        ArrayResize(m_sym, m_count);
        for(int i = 0; i < m_count; i++) {
            m_sym[i].symbol = symbols[i];
            SymbolSelect(symbols[i], true);
            m_sym[i].cache.Init(symbols[i]);
            m_sym[i].ind.Init(symbols[i], PERIOD_H1);
        }
        return true;
    }

    void UpdatePrices() {
        MqlTick tick;
        for(int i = 0; i < m_count; i++) {
            if(SymbolInfoTick(m_sym[i].symbol, tick)) {
                if(m_sym[i].bid != tick.bid || m_sym[i].ask != tick.ask) {
                    m_sym[i].bid = tick.bid;
                    m_sym[i].ask = tick.ask;
                    m_sym[i].update = tick.time;
                }
            }
        }
    }

    void Process(int i) {
        if(i < 0 || i >= m_count) return;
        m_sym[i].ind.Update();
        if(m_sym[i].ind.BullishCross()) {
            // Signal buy per m_sym[i].symbol
        }
    }

    int Count() { return m_count; }
};

CMultiSymbol g_multi;
void OnTick() {
    g_multi.UpdatePrices();
    static int cur = 0;
    g_multi.Process(cur);
    cur = (cur + 1) % g_multi.Count();
}
```

---

## ESEMPI CONCRETI

### Esempio 1: EA Ottimizzato per Backtest

```mql5
input int InpMA = 20;
input double InpLot = 0.1;
input int InpSL = 50;
input int InpTP = 100;

double g_point;
int g_digits, g_sl, g_tp;
int g_ma;
double g_ma_buf[];
datetime g_lastbar;

int OnInit() {
    g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    g_sl = InpSL * 10;
    g_tp = InpTP * 10;

    g_ma = iMA(_Symbol, 0, InpMA, 0, MODE_SMA, PRICE_CLOSE);
    if(g_ma == INVALID_HANDLE) return INIT_FAILED;

    ArraySetAsSeries(g_ma_buf, true);
    ArrayResize(g_ma_buf, 3, 10);
    g_lastbar = 0;
    return INIT_SUCCEEDED;
}

void OnTick() {
    datetime bar = iTime(_Symbol, 0, 0);
    if(bar == g_lastbar) return;
    g_lastbar = bar;

    if(PositionSelect(_Symbol)) return;
    if(CopyBuffer(g_ma, 0, 0, 3, g_ma_buf) != 3) return;

    double c1 = iClose(_Symbol, 0, 1);
    double c2 = iClose(_Symbol, 0, 2);

    if(c2 < g_ma_buf[2] && c1 > g_ma_buf[1]) OpenBuy();
    else if(c2 > g_ma_buf[2] && c1 < g_ma_buf[1]) OpenSell();
}

void OpenBuy() {
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    MqlTradeRequest req = {};
    MqlTradeResult res = {};
    req.action = TRADE_ACTION_DEAL;
    req.symbol = _Symbol;
    req.volume = InpLot;
    req.type = ORDER_TYPE_BUY;
    req.price = ask;
    req.sl = NormalizeDouble(ask - g_sl * g_point, g_digits);
    req.tp = NormalizeDouble(ask + g_tp * g_point, g_digits);
    req.deviation = 10;
    OrderSend(req, res);
}
```

---

## CHECKLIST DI VALIDAZIONE

### Memory
- [ ] Array pre-allocati
- [ ] No allocation in OnTick
- [ ] Handle rilasciati in OnDeinit
- [ ] Pool oggetti per allocazioni

### CPU
- [ ] Symbol info cached
- [ ] Check su nuova barra
- [ ] Task pesanti distribuiti
- [ ] Loop ottimizzati

### Indicators
- [ ] Handle in OnInit
- [ ] Buffer con ArraySetAsSeries
- [ ] CopyBuffer minimo
- [ ] Indicatori custom ottimizzati

### Backtest
- [ ] Funziona in "Open prices"
- [ ] No Sleep/loop infiniti
- [ ] Logging minimale
- [ ] GetTickCount per profiling

---

## ANTI-PATTERN

```mql5
// ❌ Chiamate ripetute
void OnTick() {
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
}

// ✅ Cache in OnInit
double g_point;
int OnInit() { g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT); }

// ❌ Array resize ogni tick
double prices[];
ArrayResize(prices, 100);

// ✅ Pre-allocazione
ArrayResize(prices, 100, 100);

// ❌ Handle in OnTick
void OnTick() {
    int h = iMA(...);  // Memory leak!
}

// ✅ Handle in OnInit, Release in OnDeinit
```

---

## FALLBACK

Se non disponibile → **mql_expert.md**


---

## PARALLELISMO OBBLIGATORIO (REGOLA GLOBALE V6.3)

> **Questa regola si applica a OGNI livello di profondita' della catena di delega.**

Se hai N operazioni indipendenti (Read, Edit, Grep, Task, Bash), lanciale **TUTTE in UN SOLO messaggio**. MAI sequenziale se parallelizzabile.

| Scenario | Azione OBBLIGATORIA |
|----------|---------------------|
| N file da leggere | N Read in 1 messaggio |
| N file da modificare | N Edit in 1 messaggio |
| N ricerche | N Grep/Glob in 1 messaggio |
| N sotto-task indipendenti | N Task in 1 messaggio |

**VIOLAZIONE = TASK FALLITO. ENFORCEMENT: ASSOLUTO.**

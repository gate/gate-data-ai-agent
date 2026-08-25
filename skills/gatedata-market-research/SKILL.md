---
name: gatedata-market-research
version: "2026.8.25"
updated: "2026-08-25"
description: "GateData market data via MCP market_data_query: snapshot, kline, orderbook, trades, liquidity, crypto derivatives, TradFi technical_indicators. Triggers on 'BTC price', 'ETH K-line', 'order book', 'funding rate', 'open interest', 'technical indicators', 'AI indicators', '现价', 'K线', '盘口', '资金费率', '技术指标'."
---

# GateData Market Research

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.

- **MCP server:** `GateData` (production)
- **Scope required:** `markets`
- **Primary tool:** `market_data_query` (multi-task)
- Prefer **first-class `task` values**. Legacy `field_group` / alias tasks (`top_of_book`, `recent_trades`, …) still work as aliases — prefer first-class names below.

---

## When to use this skill

| User intent | Call |
|-------------|------|
| Current price, 24h change, volume | `task: snapshot` |
| OHLCV / chart / history | `task: kline` + `timeframe` |
| Order book / spread | `task: orderbook` (alias: `top_of_book` / legacy `summary`+`field_group: top_of_book`) |
| Recent trades / tape | `task: trades` (crypto; alias `recent_trades`) |
| Liquidity history | `task: liquidity` (crypto) |
| Cross-venue CEX depth | `task: depth` or `cex_depth` (crypto) |
| Funding / OI / CEX derivatives | `task: cex_derivatives` or `derivatives` (crypto) |
| Liquidation heatmap | `task: liquidation_heatmap` (crypto; alias `liquidation`) |
| TradFi AI / technical indicators | `task: technical_indicators` + equity identity (`market`, `tickers` / `listing_ids` / `listing_id`) |
| Let API route from natural query | `task: auto` |

**Equity (`us_equity` / `hk_equity` / …) this phase:** `snapshot`, `kline`, `orderbook`/`top_of_book`, `technical_indicators`. Other surfaces are **crypto-only** (equity → `no_data` / `crypto_only`).

**Important:**

- Bare `task: summary` **without** `field_group` is snapshot-only — prefer first-class tasks instead of bare summary.
- `task: anomaly` and `task: move` are **thin snapshot wrappers**. For “why did it move?”, use `kline` + [signals](../gatedata-signals-news/SKILL.md) `content_search`/`sentiment`.

**Do not use** for prediction markets → [gatedata-prediction-markets](../gatedata-prediction-markets/SKILL.md).  
**Do not use** for news/sentiment → [gatedata-signals-news](../gatedata-signals-news/SKILL.md).  
**Do not use** for financial statements / earnings → [gatedata-fundamentals-earnings](../gatedata-fundamentals-earnings/SKILL.md).

---

## Key parameters

- `query` — free-form symbol/asset (`BTC`, `ETH_USDT`, `AAPL`)
- `market` / `context.market` — **required for equity** (`us_equity`, `hk_equity`, `kr_equity`, `uk_equity`, `jp_equity`, `crypto`)
- `venue` / `venue_id` + `market_type` (`spot` | `perp`) — disambiguate listings
- `timeframe` / `interval`, `from` / `to` — kline windows. **Honor explicit `from`/`to`**: equity live and crypto live filter candles by that window; date-only `to` is treated as end-of-day bound. Prefer ISO datetimes when the user names a calendar range.
- `listing_id` / `object_refs` — preferred for exact prices
- `depth`, `limit`, `include_indicators`
- **`technical_indicators`:** `tickers`+`market`, and/or `listing_id`/`listing_ids` (Doris `US.AAPL` or Gate `listing_aapl_xnas`), optional `analysis_as_of`, `part_date`
- `field_group` — **legacy only**; prefer first-class `task`

---

## object_refs chaining

1. First call may use `query` (e.g. `BTC`, `ETH`, `AAPL`).
2. Read `metadata.object_refs` from the response.
3. Pass refs in subsequent calls to avoid re-resolution and `40001 ambiguous` errors.

Example chain: `task: snapshot` → `task: kline` → `task: orderbook`, all on `market_data_query` with the same `object_refs`.

---

## Ambiguity handling

When the API returns `40001` or `metadata.candidates`:

1. If user named a venue (Binance, Gate), add `venue`/`venue_id` + `market_type` (`spot` / `perp`).
2. If multiple listings match, ask one clarifying question OR pick `listing_id` from `candidates`.
3. For pairs like `ETH_USDT` without venue, always disambiguate before order book / kline.
4. Cross-domain ambiguity (stock vs token) → [gatedata-assets-resolve](../gatedata-assets-resolve/SKILL.md) first.
5. If `assets_resolve` returns HTTP 200 with `resolution_status=ambiguous` and candidates — ask the user; do not treat as a tool error.

---

## Response presentation

- Always show `updated_at` or candle time when quoting prices.
- Mention `data_status` / `limitations` if partial or delayed.
- Free tier sample symbols: BTC, ETH, SOL (crypto); AAPL, NVDA, TSLA (TradFi).

---

## References

- [scenarios.md](./references/scenarios.md) — example dialogues
- [troubleshooting.md](./references/troubleshooting.md) — auth, scope, ambiguity

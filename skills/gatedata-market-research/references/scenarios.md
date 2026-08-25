# Market Research — Example Scenarios

All calls use MCP tool `market_data_query`. Prefer first-class `task` values.

## 1. Spot price check

**User:** BTC 现在多少钱？

**Flow:**
1. `market_data_query` with `{ "task": "snapshot", "query": "BTC" }`
2. Present price, 24h change, volume; cite `updated_at`.

---

## 2. K-line then order book

**User:** Show me ETH daily candles for the last month, then current order book.

**Flow:**
1. `market_data_query` with `{ "task": "kline", "query": "ETH", "timeframe": "1d", "limit": 30 }`
2. Extract `object_refs` from response metadata.
3. `market_data_query` with `{ "task": "orderbook", "object_refs": [...] }`
   (or `{ "task": "orderbook", "query": "ETH", "venue": "...", "market_type": "spot" }`)

---

## 3. Derivatives / funding (crypto)

**User:** Is BTC funding rate high? Any liquidation risk?

**Flow:**
1. `market_data_query` with `{ "task": "cex_derivatives", "query": "BTC" }` for funding / OI.
2. Optional: `{ "task": "liquidation_heatmap", "query": "BTC" }` for heatmap clusters.
3. Do **not** use bare `task: summary` (snapshot-only without `field_group`).

---

## 4. Cross-venue liquidity

**User:** Compare ETH liquidity across major CEXes.

**Flow:**
1. Prefer `{ "task": "depth", "query": "ETH" }` (or `cex_depth`) for cross-venue depth.
2. Or `{ "task": "liquidity", "query": "ETH" }` for liquidity history.
3. Present per-venue depth; note aggregation window. Equity tickers are **not** supported on these surfaces.

---

## 5. Ambiguous pair resolution

**User:** What's the order book for ETH_USDT?

**Flow:**
1. `market_data_query` with `{ "task": "orderbook", "query": "ETH_USDT" }`
2. If `40001` / candidates returned → ask: "Spot or perp? Which exchange?"
3. Retry with `venue` + `market_type` or selected `listing_id`.

---

## 6. US equity quote

**User:** NVDA 现价多少？

**Flow:**
1. `market_data_query` with `{ "task": "snapshot", "query": "NVDA", "market": "us_equity" }`
2. Present price with market session context.

---

## 7. TradFi technical indicators

**User:** Show AI / technical indicators for AAPL.

**Flow:**
1. `market_data_query` with `{ "task": "technical_indicators", "tickers": "AAPL", "market": "us_equity" }`
   — or `listing_id` / `listing_ids` like `US.AAPL` / `listing_aapl_xnas`.
2. Optional: `analysis_as_of`, `part_date`.
3. If Doris is down → `503` / `not_ready`; tell the user.

---

## 8. “Why did price move?”

**User:** Why did BTC dump today?

**Flow:**
1. `market_data_query` `{ "task": "kline", "query": "BTC", "timeframe": "1h" }` for the move shape.
2. `events_news_query` `{ "task": "content_search", "ticker": "BTC", "market": "crypto" }` / `{ "task": "sentiment", ... }` for catalysts.
3. Do **not** rely on `task: move` / `task: anomaly` — they only return snapshot-style price facts.

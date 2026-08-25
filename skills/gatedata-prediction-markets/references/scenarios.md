# Prediction Markets — Example Scenarios

All calls use MCP tool `prediction_markets_query`.

## 1. Top volume events

**User:** 预测市场今天成交量排行前五

**Flow:**
1. `prediction_markets_query` with `{ "task": "rankings", "ranking_type": "volume_24h", "limit": 5 }`
2. Present ranked events with volume; offer drill-down.

---

## 2. Search then detail

**User:** Find prediction markets about the US election.

**Flow:**
1. `prediction_markets_query` with `{ "task": "search", "query": "US election", "limit": 10 }`
2. User picks an event → `{ "task": "event_detail", "event_ref": "..." }` with ref from metadata.
3. Optional: `{ "task": "event_signal", "event_ref": "..." }` for model view.

---

## 3. Market order book

**User:** Show the order book for market X on Polymarket.

**Flow:**
1. If no `market_id`: run `task: market` or `task: event_detail` first.
2. `prediction_markets_query` with `{ "task": "order_book", "venue": "polymarket", "market_id": "..." }`
3. Present bids/asks and spread.

---

## 4. Event signal

**User:** Is there an edge on this prediction event?

**Flow:**
1. Resolve `event_ref` (from search or user paste).
2. `prediction_markets_query` with `{ "task": "event_signal", "event_ref": "..." }`
3. Summarize signal; link to `task: order_book` for executable prices.

---

## 5. Liquidity leaders

**User:** Which prediction markets have the best liquidity right now?

**Flow:**
1. `prediction_markets_query` with `{ "task": "rankings", "ranking_type": "liquidity", "limit": 10 }`
2. For top item: `{ "task": "market", "market_id": "..." }` using emitted `market_ref`.

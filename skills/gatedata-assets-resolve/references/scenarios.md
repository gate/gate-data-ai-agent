# Assets Resolve — Example Scenarios

All calls use MCP tool `assets_resolve`.

## 1. Ambiguous name (stock vs token)

**User:** Tell me about Apple.

**Flow:**
1. `assets_resolve` with `{ "task": "search", "query": "Apple", "limit": 5 }`
2. If `resolution_status=ambiguous`, present candidates (e.g. AAPL `us_equity` vs APP token).
3. Ask user to pick; then continue with market or fundamentals using `object_refs`.

---

## 2. Crypto contract address

**User:** What asset is this contract `0x…`?

**Flow:**
1. `assets_resolve` with `{ "task": "resolve", "query": "0x…", "context": { "chain": "…" } }` when chain is known.
2. Present asset id / symbol; optional `task: deployments` for chain deployments.
3. Offer price via `market_data_query` if user wants a quote.

---

## 3. Listings for an asset

**User:** Where is BTC listed on major CEXes?

**Flow:**
1. `assets_resolve` `{ "task": "resolve", "query": "BTC" }` (or `profile`).
2. `assets_resolve` `{ "task": "listings", "asset_id": "…", "object_refs": […] }`.
3. Summarize venues / market types; for a specific book use market skill with `venue` + `market_type`.

---

## 4. Equity bias with StandardMarket

**User:** Resolve NVDA as a US stock.

**Flow:**
1. `assets_resolve` with `{ "task": "resolve", "query": "NVDA", "context": { "market": "us_equity" } }`
2. Pass refs to `market_data_query` (`market: us_equity`) or `fundamentals_query`.

---
version: v1.3.0
last_updated: 2026-08-13
---

# GateData Composite Scenarios

> Cross-skill playbooks: when a user question spans markets, prediction, signals, fundamentals, and resolve.
> Read [gatedata-skills-disambiguation.md](./gatedata-skills-disambiguation.md) first for routing.

---

## 1. BTC price + recent news

**User:** BTC 现在多少钱？最近有什么重要新闻？

**Flow:**
1. `gatedata-market-research` → `market_data_query` (`task: snapshot`, `query: BTC`)
2. `gatedata-signals-news` → `events_news_query` (`task: content_search`, `ticker: BTC`, `market: crypto`, recent window)
3. Present price with `updated_at`, then news headlines with timestamps.

---

## 2. Prediction market rank + underlying asset price

**User:** 预测市场成交量第一的事件是什么？相关资产现价多少？

**Flow:**
1. `gatedata-prediction-markets` → `prediction_markets_query` (`task: rankings`, `ranking_type: volume_24h`)
2. Read top event asset/ticker from response metadata or `object_refs`
3. `gatedata-market-research` → `market_data_query` (`task: snapshot`) with resolved asset ref

---

## 3. Sentiment + price snapshot

**User:** 今天 BTC 相关情绪怎么样？价格和 24h 变化呢？

**Flow:**
1. `gatedata-signals-news` → `events_news_query` (`task: sentiment` or `task: content_search`) for BTC
2. `gatedata-market-research` → `market_data_query` (`task: snapshot`) for same asset
3. Correlate sentiment summary with price change; cite both data times.
4. Do not call removed signals tasks (`news`/`insight`/…). Market `task: move` is snapshot-only — use `kline`/`snapshot` + content_search/sentiment for causal claims.

---

## 4. Earnings result + price reaction

**User:** NVDA 上季度财报怎么样？股价当时反应如何？

**Flow:**
1. `gatedata-fundamentals-earnings` → `estimates_earnings_query` (`task: results`, `query: NVDA`, `window: previous_quarter`) — explicit task, not `auto`
2. `gatedata-market-research` → `market_data_query` (`task: kline`, `market: us_equity`) around the report date
3. Present surprise vs consensus, then the price move; cite fiscal period and candle times.
4. Do not call earnings `ratings` / `summary`.

---

## 5. Ambiguous name → resolve → quote

**User:** Tell me about Apple — what is it trading at?

**Flow:**
1. `gatedata-assets-resolve` → `assets_resolve` (`task: search`, `query: Apple`)
2. If `resolution_status=ambiguous`, ask user to pick (e.g. AAPL `us_equity`)
3. `gatedata-market-research` → `market_data_query` (`task: snapshot`, `market: us_equity`) with `object_refs`

---

## 6. Install missing MCP mid-task

**User asks for GateData data but MCP tools are missing.**

**Flow:**
1. Read [gatedata-runtime-rules.md](./gatedata-runtime-rules.md) §1
2. Offer install from this repo: `https://github.com/gate/gate-data-ai-agent`
3. `bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor`
4. Restart client; retry original question.

---

## Rules

- Chain with **`object_refs`** when the same asset/event appears in step 2+.
- Do not call tools from multiple skills in parallel if step 2 depends on step 1 resolution.
- If scope missing (e.g. `prediction` denied), explain which API key scope is needed.
- Match plan domains: Free = markets/assets/prediction; Plus+ for signals; Pro/Enterprise for fundamentals/earnings.

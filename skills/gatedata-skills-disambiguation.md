---
version: v1.3.1
last_updated: 2026-08-25
---

# GateData Skills Disambiguation

> Read **before** selecting a domain skill.  
> Each domain skill's `SKILL.md` should reference this file for cross-domain routing.  
> For multi-domain playbooks, see [gatedata-composite-scenarios.md](./gatedata-composite-scenarios.md).

---

## Decision flow

```
1. User wants to INSTALL / setup MCP?
   → gatedata-mcp-installer

2. User wants to RESOLVE a ticker / name / contract / listings (ambiguous entity)?
   → gatedata-assets-resolve
   (no task: universe)

3. User wants LIVE PRICE, chart, order book, funding, liquidation, TradFi technical indicators?
   → gatedata-market-research
   (prefer first-class tasks: orderbook, cex_derivatives, technical_indicators, …)

4. User wants PREDICTION MARKET odds, Polymarket, event probability, rankings?
   → gatedata-prediction-markets

5. User wants NEWS, sentiment, headlines, social posts (X/YouTube), macro events?
   → gatedata-signals-news
   (only content_search | event_search | social_search | sentiment)

6. User wants FUNDAMENTALS, financial statements, tokenomics/supply, earnings dates,
   or analyst consensus?
   → gatedata-fundamentals-earnings
   (only calendar/results/consensus/auto — do NOT call ratings/summary/transcript/guidance;
    ratings/target prices and guidance/transcript payloads are not in this release)

7. Ambiguous ("tell me about BTC" / "Apple")?
   → If identity unclear → gatedata-assets-resolve first
   → Else default: gatedata-market-research (price snapshot)
   → If user mentions news/sentiment → signals
   → If user mentions prediction/odds → prediction
   → If user mentions earnings/financials/tokenomics → fundamentals-earnings
```

---

## Keyword hints

| Keywords (EN) | Skill |
|---------------|-------|
| price, K-line, chart, order book, funding, OI, liquidation, depth, technical indicators | market |
| resolve, ticker lookup, contract address, asset id, listings, deployments | assets-resolve |
| prediction, Polymarket, odds, yes/no, probability, ranking (events) | prediction |
| news, sentiment, headline, social, UGC, YouTube, "what happened" | signals |
| earnings, EPS, revenue, consensus, financial statements, balance sheet, tokenomics, supply | fundamentals-earnings |
| analyst rating / target price | **unavailable this release** — say so; offer consensus if useful |
| company guidance / transcript (context) | fundamentals-earnings → `results`/`consensus` only; **no** `task: guidance`/`transcript` |
| install, setup, MCP, connect | installer |

| Keywords (中文) | Skill |
|-----------------|-------|
| 现价、价格、K线、盘口、资金费率、清算、深度、技术指标 | market |
| 解析标的、合约地址、这个 ticker、上市列表 | assets-resolve |
| 预测市场、概率、赔率、Polymarket、排行 | prediction |
| 新闻、情绪、利好利空、社媒、YouTube | signals |
| 财报、业绩、每股收益、营收、资产负债表、代币经济、供给 | fundamentals-earnings |
| 分析师评级 / 目标价 | **本版本不可用** — 可改用 consensus |
| 指引 / 电话会纪要 | fundamentals-earnings → `results`/`consensus`（勿调 `guidance`/`transcript`）|
| 安装、接入、配置 MCP | installer |

---

## Multi-domain queries

When user asks for **both** price and news (e.g. "BTC price and recent news"):

1. `gatedata-market-research` → `market_data_query` (`task: snapshot`)
2. Pass refs / ticker to `gatedata-signals-news` → `events_news_query` (`task: content_search` or `task: sentiment`)
3. Present combined answer with timestamps

When user asks for **prediction + news**:

1. `gatedata-prediction-markets` for odds
2. `gatedata-signals-news` only if user wants related headlines (not default)

When user asks for **earnings + price reaction**:

1. `gatedata-fundamentals-earnings` → `estimates_earnings_query` (`task: results` or `calendar`)
2. `gatedata-market-research` → `market_data_query` (`task: kline`) around the earnings date

When user asks **why price moved**:

1. Market `kline` / `snapshot` for the move shape
2. Signals `content_search` / `sentiment` for catalysts
3. Do not use market `task: move` / `task: anomaly` for causal explanation

---

## MCP server names

Any of these indicate GateData MCP is configured:

- `GateData`
- `GateData.AI`
- `gatedata-remote-prod`
- URL contains `mcp.gatedata.ai` or `api.gatedata.ai/mcp`

Do **not** require renaming to `GateData` if an existing server already works.

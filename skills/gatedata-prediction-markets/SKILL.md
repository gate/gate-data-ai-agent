---
name: gatedata-prediction-markets
version: "2026.8.2"
updated: "2026-08-02"
description: "GateData prediction markets via MCP prediction_markets_query: search events, rankings, market detail, signals, order book. Triggers on 'prediction market', 'Polymarket', 'event odds', 'yes/no price', 'prediction ranking', '预测市场', '事件概率', '成交量排行'."
---

# GateData Prediction Markets

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.

- **MCP server:** `GateData` (production)
- **Scope required:** `prediction`
- **Primary tool:** `prediction_markets_query` (multi-task). Legacy `prediction_*` names are invoke aliases only — prefer `prediction_markets_query` + `task`.

---

## When to use this skill

One tool, routed by `task`:

| User intent | Call |
|-------------|------|
| Search events by topic/keyword | `task: search` + `query` |
| Top events by volume or liquidity | `task: rankings` + `ranking_type` |
| Full event + child markets | `task: event_detail` + `event_ref`/`event_id` |
| Model signal / edge on an event | `task: event_signal` + `event_ref`/`event_id` |
| Single market probability & rules | `task: market` + `market_id` |
| Yes/no order book | `task: order_book` + `venue` + `market_id` |
| Event overview | `task: summary` |
| Let API route from natural query | `task: auto` (default) |

**Do not call (planned):** `task: probability_history`, `task: volume_delta` — not live; use `market` / `summary` / `order_book` instead.

**Do not use** for CEX crypto spot/perp prices → [gatedata-market-research](../gatedata-market-research/SKILL.md).  
**Do not use** for news headlines → [gatedata-signals-news](../gatedata-signals-news/SKILL.md).  
Ambiguous entity (ticker vs contract) → [gatedata-assets-resolve](../gatedata-assets-resolve/SKILL.md) first.

---

## object_refs chaining

1. `task: search` or `task: rankings` emits `event` / `market` refs.
2. Use refs in `event_detail`, `market`, `event_signal` tasks.
3. `task: order_book` needs `venue` + `market_id` (from prior market detail).

Typical chain: `rankings` → `event_detail` → `order_book` (same tool, changing `task`).

---

## ranking_type guide

| User says | `ranking_type` |
|-----------|----------------|
| "hottest", "top volume", "most traded" | `volume_24h` |
| "most liquid", "deepest markets" | `liquidity` |

Optional: `venue`, `status`, `limit`, `include_markets`, `depth`.

---

## Response presentation

- Show implied probability / yes-no prices clearly.
- Note resolution rules and `status` when present.
- If `task: event_signal` returns `50301`, explain signal is not ready yet.

---

## References

- [scenarios.md](./references/scenarios.md)
- [troubleshooting.md](./references/troubleshooting.md)

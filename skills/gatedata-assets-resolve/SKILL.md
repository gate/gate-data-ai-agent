---
name: gatedata-assets-resolve
version: "2026.8.13"
updated: "2026-08-13"
description: "GateData asset resolution via MCP assets_resolve: ticker/name/address search, profile (object metadata), listings, deployments, coverage. Triggers on 'resolve ticker', 'what is this contract', 'Gate symbol', 'asset id', 'listings for', 'resolve Apple', '解析标的', '合约地址', '这个 ticker 是什么'."
---

# GateData Assets Resolve

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.

- **MCP server:** `GateData` (production)
- **Scope required:** `assets` (Free plan includes this domain)
- **Primary tool:** `assets_resolve` (multi-task)
- Prefer this skill **before** market / fundamentals / earnings / signals when the entity is ambiguous.

**Public tasks:** `auto` | `resolve` | `search` | `profile` | `listings` | `deployments` | `coverage`  
**Do not call:** `universe` (phase-1 hard reject / out of public scope).

---

## When to use this skill

| User intent | Call |
|-------------|------|
| Resolve NL ticker / name / symbol | `task: auto` or `task: resolve` + `query` |
| Search candidates | `task: search` + `query` |
| Asset object metadata profile | `task: profile` + `query` or `asset_id` |
| Venue listings for an asset | `task: listings` |
| On-chain deployments (crypto) | `task: deployments` + `asset_id` / `query` |
| Coverage probe | `task: coverage` |

**Do not use** for live prices → [gatedata-market-research](../gatedata-market-research/SKILL.md).  
**Do not use** for equity company fundamentals / company background content → [gatedata-fundamentals-earnings](../gatedata-fundamentals-earnings/SKILL.md) `task: profile`.  
**Do not use** for news → [gatedata-signals-news](../gatedata-signals-news/SKILL.md).

---

## Key parameters

- `query` — ticker, name, Gate symbol, or contract address
- `task` — see table above (`auto` default)
- `context.market` / StandardMarket (`us_equity`, `hk_equity`, `crypto`, …) to bias resolution
- `context.chain`, `context.venue_id`, `context.asset_class`, `context.quote_currency`, `context.market_type` (`spot` \| `perp`) when relevant
- Top-level aliases may include `market`, `chain`, `venue_id`, `listing_id`, `entity_id`
- `asset_id`, `object_refs`, `limit`

---

## Ambiguous resolution (important)

`assets_resolve` may return **HTTP 200** with:

- `resolution_status=ambiguous`
- `data[]` candidate rows

This is **success with a choice**, not a tool failure. Ask the user which candidate to use, then pass `asset_id` / `object_refs` / `listing_id` into the next domain tool.

---

## Chaining

1. Resolve → read `metadata.object_refs` / `asset_id` / listing ids.
2. Next tools (typical): `market_data_query`, `fundamentals_query`, `estimates_earnings_query`, `events_news_query`.
3. Prefer refs over re-sending raw `query` to avoid re-ambiguity.

---

## References

- [scenarios.md](./references/scenarios.md)
- [troubleshooting.md](./references/troubleshooting.md)

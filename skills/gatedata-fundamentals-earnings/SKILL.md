---
name: gatedata-fundamentals-earnings
version: "2026.8.25"
updated: "2026-08-25"
description: "GateData fundamentals & earnings via MCP fundamentals_query and estimates_earnings_query: company profiles, statements, metrics, segments, corporate actions, crypto tokenomics/supply, earnings calendar/results/consensus. Triggers on 'earnings', 'EPS', 'revenue', 'consensus', 'balance sheet', 'tokenomics', '财报', '业绩', '营收', '代币经济'."
---

# GateData Fundamentals & Earnings

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.

- **MCP server:** `GateData` (production)
- **Scopes required:** `fundamentals` (for `fundamentals_query`) and `earnings` (for `estimates_earnings_query`)
- **Also useful:** `assets` only when calling `assets_resolve` first — install path `/mcp/assets` ≠ scope `assets`
- **Plan:** fundamentals/earnings need **Pro or Enterprise**
- **Tools:** `fundamentals_query` and `estimates_earnings_query`. Use [gatedata-assets-resolve](../gatedata-assets-resolve/SKILL.md) first when the entity is ambiguous.

---

## Which tool

| User intent | Tool | Call |
|-------------|------|------|
| Company profile / business overview | `fundamentals_query` | `task: profile` (alias: `company_profile`) |
| Income statement / balance sheet / cash flow | `fundamentals_query` | `task: statements` + `statement_type` (alias: `financial_statements`) |
| Financial metrics | `fundamentals_query` | `task: metrics` + `metric_set` (alias: `financial_metrics`) |
| Revenue segments | `fundamentals_query` | `task: segments` + `segment_type` |
| Dividends, splits, buybacks, mergers, redemptions | `fundamentals_query` | `task: corporate_actions` + `action_type` |
| Crypto tokenomics | `fundamentals_query` | `task: tokenomics` |
| Crypto supply metrics | `fundamentals_query` | `task: supply` |
| Fundamentals overview | `fundamentals_query` | `task: summary` |
| Earnings dates / calendar | `estimates_earnings_query` | `task: calendar` + `window` |
| Reported results & surprises | `estimates_earnings_query` | `task: results` |
| Analyst consensus (EPS, revenue…) | `estimates_earnings_query` | `task: consensus` + `estimate_metric` |

**Earnings public tasks only:** `auto` | `calendar` | `results` | `consensus`.

**Do not call (rejected / not in this release):**

| Tool | Task | Why |
|------|------|-----|
| `estimates_earnings_query` | `ratings`, `summary`, `transcript`, `guidance` | **Rejected** — not advertised on `tools/list`; invoke returns unsupported |
| `fundamentals_query` | `valuation_metrics` | Out of crawl MVP / weak |
| `fundamentals_query` | `signals` | Not ready — avoid; use `metrics` |

**Do not use `task: auto` when the user asks for company guidance or earnings-call transcripts.** Those tasks are not public — call explicit live tasks: `results` or `consensus`, and tell the user full guidance/transcript payloads are unavailable.

**`estimate_metric: guidance` ≠ `task: guidance`** — the former is only a **consensus metric filter** on `task: consensus`. Never call `task: guidance`.

**Do not use** for live prices / klines → [gatedata-market-research](../gatedata-market-research/SKILL.md).  
**Do not use** for news headlines / sentiment → [gatedata-signals-news](../gatedata-signals-news/SKILL.md).  
**Do not use** for analyst ratings / target prices — **not in this release**; tell the user clearly.

Equity company profile / background language belongs on **`fundamentals_query` `task: profile`**, not `assets_resolve` profile (assets profile = object metadata only).

---

## Key parameters

**fundamentals_query:**

- `query` or `entity_id` / `asset_id` (preferred for company data)
- `statement_type`: `income_statement` | `balance_sheet` | `cash_flow`
- `period_type`: `annual` | `quarterly` | `ttm`
- `window`: `latest` | `30d` | `90d` | `latest_fiscal_year` | `last_3y` | `custom` (+ `from`/`to`)
- `metric_set`: `valuation` | `profitability` | `growth` | `leverage` | `liquidity` | `dividend`
- `segment_type`: `business` | `product` | `industry` | `geography` | …
- `action_type`: `dividend` | `split` | `buyback` | `merger` | `listing_change` | `redemption`
- Prefer `market` / `context.market` as StandardMarket (`us_equity`, `hk_equity`, `crypto`, …)

**estimates_earnings_query:**

- `query`; `entity_id` preferred for `calendar` / `results` / `consensus`
- `window`: `latest` | `next_30d` | `next_90d` | `previous_quarter` | `fy_current` | `custom`
- `period_type`: `quarterly` | `annual` | `ttm`; `fiscal_period` for a specific quarter
- `estimate_metric`: `eps` | `revenue` | `forward_eps` | `ebitda` | `gross_margin` | `guidance` — use with `task: consensus` only when filtering metrics

---

## object_refs chaining

1. Resolve the company once (via `query` or `assets_resolve`), then reuse `metadata.object_refs` / `entity_id`.
2. If `assets_resolve` returns HTTP 200 with `resolution_status=ambiguous` and `data[]` candidates — ask the user to pick; do **not** treat as a tool error.
3. Typical chain: `estimates_earnings_query` (`task: calendar`) → (`task: results`) → `market_data_query` (`task: kline`) for price reaction; or → `fundamentals_query` (`task: statements`) for deeper financials.
4. Fundamentals + earnings for the same company can share `entity_id`.

---

## Coverage & caveats

- Equity coverage focuses on US (MVP), with HK expanding.
- Crypto `tokenomics` / `supply` come from Tokenomist DWS — state gaps when thin.
- Scope denied → need `fundamentals` and/or `earnings` on the API key (not `assets`).
- Plan entitlement denied → upgrade to Pro/Enterprise.

---

## Response presentation

- Always cite the **fiscal period** (e.g. FY2026 Q2) and report date.
- For surprises, show actual vs consensus and the delta.
- If results include company-reported guidance fields, distinguish them from analyst consensus; do not invent transcript text.

---

## References

- [scenarios.md](./references/scenarios.md)
- [troubleshooting.md](./references/troubleshooting.md)

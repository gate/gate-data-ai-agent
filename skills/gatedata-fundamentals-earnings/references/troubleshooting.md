# Fundamentals & Earnings — Troubleshooting

## HTTP 401 / unauthorized

- Production API key with `enable_mcp`.
- Scopes: `fundamentals` for `fundamentals_query`, `earnings` for `estimates_earnings_query`.
- `assets` alone is **not** enough (and install path `/mcp/assets` ≠ scope `assets`).

## Plan entitlement / domain not included

- Fundamentals and earnings require **Pro or Enterprise**.
- Free / Plus / Alpha keys are blocked even if scopes appear on the key — ask user to upgrade or use another domain skill.

## invalid_task (earnings)

- Public tasks only: `auto` | `calendar` | `results` | `consensus`.
- `ratings`, `summary`, `transcript`, `guidance` → **not supported in this release** — remap to `consensus` / `results` / `calendar`, or explain unavailable.
- Prefer explicit live tasks over hoping `auto` lands correctly.

## missing_required_param

| Tool / task | Typical requirement |
|-------------|---------------------|
| `estimates_earnings_query` `calendar` / `results` / `consensus` | `query` or `entity_id` |
| `fundamentals_query` `statements` | `statement_type` |
| `fundamentals_query` `segments` | `segment_type` recommended |

## not_found / no_data

- Resolve the company first with `assets_resolve` (ambiguous names, non-US listings).
- If resolve returns `resolution_status=ambiguous` with candidates, ask the user — do not retry as an error.
- Coverage is US-first (HK expanding); other markets may return thin or no data — state this to the user.
- For equity price context use `market_data_query` with `market: us_equity` etc.

## Guidance / transcript intents

- Do **not** call `task: transcript` or `task: guidance` (rejected).
- Do **not** use `task: auto` when the query mentions guidance / transcript / earnings call / 电话会 / 公司指引 — use explicit `task: results` or `task: consensus`.
- `estimate_metric: guidance` is a **consensus metric filter**, not `task: guidance`.
- Avoid fundamentals `valuation_metrics` and not-ready `signals`.
- Fall back to `task: results` / `task: consensus` / `task: metrics` / `task: tokenomics` — **not** earnings `summary`.

## 503 serving_snapshot_missing

- Retry with `allow_stale: true` if schema supports it; report data delay.

## Cross-skill routing

| Need | Skill |
|------|-------|
| Live price / kline / technical indicators | `gatedata-market-research` |
| News / sentiment on the stock | `gatedata-signals-news` |
| Prediction market odds | `gatedata-prediction-markets` |

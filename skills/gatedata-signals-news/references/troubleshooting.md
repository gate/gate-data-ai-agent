# Signals & News — Troubleshooting

All calls use MCP tool `events_news_query`.

## HTTP 401 / unauthorized

- Production API key with `enable_mcp` and `signals` scope (Plus+ plan).

## invalid_task

- Only phase-1 tasks are accepted: `content_search`, `event_search`, `social_search`, `sentiment`.
- Legacy names (`news`, `events`, `ugc`, `auto`, `event_detail`, `announcements`, `ratings`, `insight`) → **hard reject**. Remap and retry.

## missing_required_param

| Task | Typical requirement |
|------|---------------------|
| `sentiment` | `ticker` + `market` (StandardMarket) |
| `content_search` / `event_search` / `social_search` | `query` and/or `ticker` (+ `market` when ticker-bound) |
| `social_search` | `platform` (`x` / `twitter` / `youtube` / `all` / `web` as applicable) |
| `event_search` | prefer `from` + `to` (ISO); defaults when both omitted |

## no_results / empty feed

- Widen `window` or `from`/`to`.
- Try broader `query`, or switch between `content_search` / `event_search` / `social_search`.
- Some symbols have thin coverage — state clearly to user.

## 503 serving_snapshot_missing

- Retry with `allow_stale: true` if schema supports it.
- Report data delay to user.

## Ambiguous query / candidates

- May return `metadata.candidates` for ambiguous tickers.
- Ask user to clarify symbol or pass `ticker` + `market` explicitly (`us_equity`, not bare `us`).
- Or resolve first with `assets_resolve`.

## Platform notes

- `twitter` aliases `x`.
- `youtube` is **social_search-only** and is not merged into `platform=all`.
- YouTube `from`/`to` apply to `source_published_at` (gaps in publish fields can drop rows — widen the window if sparse).
- `has_object_refs: true` filters YouTube list results to posts with Serving object links.

## Response tips

- Crypto content may include `signal_strength` and `object_signals` — cite when explaining relevance.
- Sentiment `sample_refs` may include `author_info`.
- YouTube posts may include `video_viewpoint`.

## Cross-skill routing

| Need | Skill |
|------|-------|
| Live price | `gatedata-market-research` |
| Prediction odds | `gatedata-prediction-markets` |
| Financial statements / earnings | `gatedata-fundamentals-earnings` |
| Ambiguous ticker / contract | `gatedata-assets-resolve` |
| Analyst ratings / target prices | **Not in this release** — do not invent via signals |

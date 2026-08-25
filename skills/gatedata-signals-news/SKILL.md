---
name: gatedata-signals-news
version: "2026.8.25"
updated: "2026-08-25"
description: "GateData signals & news via MCP events_news_query: content_search, event_search, social_search (X/YouTube), sentiment. Triggers on 'news', 'sentiment', 'headlines', 'what happened to', 'social posts', 'YouTube', '新闻', '情绪', '利好利空', '最近发生了什么'."
---

# GateData Signals & News

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.

- **MCP server:** `GateData` (production)
- **Scope required:** `signals` (**Plus+** plan)
- **Primary tool:** `events_news_query` (multi-task)
- **Phase-1 public tasks only** (API hard-rejects everything else):
  `content_search` | `event_search` | `social_search` | `sentiment`

---

## When to use this skill

| User intent | Call |
|-------------|------|
| News / headlines / free-text content | `task: content_search` + `query` (and/or `ticker` + `market`) |
| Events calendar / time-bounded event feed | `task: event_search` + prefer `from` + `to` |
| Social posts (X / Twitter / YouTube) | `task: social_search` + `platform` + `query`/`ticker` |
| Aggregated sentiment score | `task: sentiment` + `ticker` + `market` |

**Do not call (rejected / out of phase-1):** `news`, `events`, `ugc`, `auto`, `event_detail`, `announcements`, `ratings`, `insight`, `anomalies`, `market_move_evidence`.

Omitted `task` may still auto-route server-side; **always pass an explicit phase-1 task** in skills so calls stay predictable.

**Do not use** for live prices → [gatedata-market-research](../gatedata-market-research/SKILL.md).  
**Do not use** for prediction odds → [gatedata-prediction-markets](../gatedata-prediction-markets/SKILL.md).  
**Do not use** for financial statements / earnings → [gatedata-fundamentals-earnings](../gatedata-fundamentals-earnings/SKILL.md).  
**Do not use** for analyst ratings / target prices (not in this release) → say unavailable; use `consensus` on earnings only for estimate consensus.  
Ambiguous entity → [gatedata-assets-resolve](../gatedata-assets-resolve/SKILL.md) first.

---

## Task selection guide

```
Headlines / article search for a ticker or topic?
  → task: content_search (query and/or ticker + market)

Calendar-style / time-bounded events?
  → task: event_search (prefer from + to; short tickers: pass listing_ids when known)

Social posts?
  → task: social_search + platform (x|twitter|youtube|all)

Sentiment score (not individual articles)?
  → task: sentiment + ticker + market
```

---

## Key parameters

- `ticker` + `market` — required for `sentiment`. Use StandardMarket (`us_equity`, `hk_equity`, `crypto`, …); e.g. `BTC`+`crypto`, `NVDA`+`us_equity`
- `query` — free text for `content_search` / `event_search` / `social_search`
- `from` + `to` (ISO) — time window on **`source_published_at`** (YouTube UGC and content/social feeds). Either side may be sent alone; defaults apply when both omitted
- `platform` — for `social_search`: `x` | `twitter` (alias of `x`) | `youtube` | `all` | `web` (as advertised). **`youtube` is social_search-only** (not merged into `platform=all`)
- `has_object_refs` — YouTube list only: when `true`, return posts that have non-empty Serving `object_refs` (skip macro / unlinked). Default `false`
- `listing_ids` — preferred when chaining from market tools; helps `event_search` / content filters for short tickers
- `signal_strength` — optional content filter (`all` or strength token as schema allows)
- `window` (`1d` | `7d` | `30d`), `limit`, `mode` (`standard` | `web` for content_search), `source_type`, `allow_stale`

### Response fields to surface

- Crypto `content_search`: top-level `signal_strength` and per-object `object_signals` when present
- YouTube `social_search`: `video_viewpoint`, channel/native metadata, `source_url`
- `sentiment` `sample_refs` may include `author_info`

---

## object_refs chaining

1. `content_search` / `event_search` / `social_search` may emit asset / event refs.
2. Prefer `listing_ids` / `object_refs` from `market_data_query` when correlating price moves with news.
3. Combine with `market_data_query` for price + news context.

---

## Caveats

- Coverage strongest for `us_equity`, `hk_equity`, `crypto`.
- Ratings / insight / announcements / event_detail are **not** public on this tool.
- For “why did price move?”: market `kline`/`snapshot` + `content_search`/`sentiment` — not market `task: move`.

---

## References

- [scenarios.md](./references/scenarios.md)
- [troubleshooting.md](./references/troubleshooting.md)

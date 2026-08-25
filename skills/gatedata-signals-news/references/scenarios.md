# Signals & News — Example Scenarios

All calls use MCP tool `events_news_query`. Phase-1 tasks only:
`content_search` | `event_search` | `social_search` | `sentiment`.

## 1. Crypto news headlines

**User:** Any big news on BTC in the last 24 hours?

**Flow:**
1. `events_news_query` with `{ "task": "content_search", "ticker": "BTC", "market": "crypto", "window": "1d", "limit": 10 }`
2. Summarize headlines with source timestamps.

---

## 2. Sentiment check

**User:** What's the social sentiment on ETH?

**Flow:**
1. `events_news_query` with `{ "task": "sentiment", "ticker": "ETH", "market": "crypto", "window": "7d" }`
2. Present score, mention ratios, sample size.
3. Optional: `task: content_search` or `task: social_search` for supporting posts.

---

## 3. Stock news + quote

**User:** Give me recent news and sentiment for NVDA.

**Flow:**
1. `events_news_query` with `{ "task": "content_search", "ticker": "NVDA", "market": "us_equity", "limit": 10 }`
2. `events_news_query` with `{ "task": "sentiment", "ticker": "NVDA", "market": "us_equity" }`
3. Cross-link price from `market_data_query` (`task: snapshot`, `market: us_equity`) if user also wants a quote.
4. Do **not** call `task: insight` / `ratings` / `announcements` (rejected).

---

## 4. Event timeline

**User:** What macro events affected crypto between Jan 1 and Jan 15?

**Flow:**
1. `events_news_query` with `{ "task": "event_search", "from": "2026-01-01T00:00:00Z", "to": "2026-01-15T23:59:59Z", "market": "crypto" }`
2. List events; use `event_id` filters on a follow-up `event_search` if the schema returns detail hooks — do **not** call removed `task: event_detail`.

---

## 5. Social UGC (X)

**User:** What are people saying about SOL on X?

**Flow:**
1. `events_news_query` with `{ "task": "social_search", "platform": "x", "ticker": "SOL", "market": "crypto", "window": "1d", "limit": 20 }`
2. Summarize themes; optional `task: sentiment` for aggregate score.

---

## 6. YouTube social search

**User:** Any recent YouTube discussion on BTC ETF?

**Flow:**
1. `events_news_query` with `{ "task": "social_search", "platform": "youtube", "query": "BTC ETF", "from": "…", "to": "…", "limit": 10 }`
   — `from`/`to` filter on `source_published_at`.
2. Optional: `"has_object_refs": true` to keep only videos linked to Serving object refs.
3. Present titles / channel / `source_url` / `video_viewpoint` when present.
4. Do not expect `platform=all` to include YouTube.

---

## 7. Free-text topic search

**User:** 最近有什么关于稳定币监管的新闻和讨论？

**Flow:**
1. `events_news_query` with `{ "task": "content_search", "query": "stablecoin regulation", "limit": 10 }`
2. Optional: `{ "task": "social_search", "platform": "x", "query": "stablecoin regulation" }`
3. Merge and present with source timestamps.

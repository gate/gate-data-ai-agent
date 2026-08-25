# Fundamentals & Earnings — Example Scenarios

## 1. Next earnings date

**User:** NVDA 什么时候发财报？

**Flow:**
1. `estimates_earnings_query` with `{ "task": "calendar", "query": "NVDA", "window": "next_90d" }`
2. Present date, fiscal period, and confirmed/estimated status.

---

## 2. Last quarter results vs expectations

**User:** How did Apple do last quarter — beat or miss?

**Flow:**
1. `estimates_earnings_query` with `{ "task": "results", "query": "AAPL", "window": "previous_quarter" }`
2. Show actual EPS/revenue vs consensus and the surprise delta; cite fiscal period.

---

## 3. Analyst consensus

**User:** What's the consensus EPS for TSLA this fiscal year?

**Flow:**
1. `estimates_earnings_query` with `{ "task": "consensus", "query": "TSLA", "estimate_metric": "eps", "window": "fy_current" }`
2. Present mean/median estimate, analyst count, revision trend if present.
3. Do **not** call `task: ratings` or `task: summary` (rejected).

---

## 4. Financial statements

**User:** Show me Microsoft's income statement for the last 3 years.

**Flow:**
1. `fundamentals_query` with `{ "task": "statements", "query": "MSFT", "statement_type": "income_statement", "period_type": "annual", "window": "last_3y" }`
2. Present key lines (revenue, gross profit, operating income, net income) per year.

---

## 5. Company profile + segments

**User:** What does Broadcom's business look like — main segments?

**Flow:**
1. `fundamentals_query` with `{ "task": "profile", "query": "AVGO" }`
2. `fundamentals_query` with `{ "task": "segments", "query": "AVGO", "segment_type": "business" }` (reuse `entity_id` / `object_refs`)
3. Summarize segment revenue mix.

---

## 6. Crypto tokenomics / supply

**User:** What's the token unlock / supply picture for SOL?

**Flow:**
1. `fundamentals_query` with `{ "task": "tokenomics", "query": "SOL" }` (or `asset_id` after resolve)
2. Optional: `{ "task": "supply", "query": "SOL" }` for supply metrics subset.
3. State coverage limits if DWS returns thin data.

---

## 7. Earnings + price reaction (cross-skill)

**User:** NVDA 上次财报后股价怎么走的？

**Flow:**
1. `estimates_earnings_query` with `{ "task": "results", "query": "NVDA", "window": "previous_quarter" }` — get report date
2. `market_data_query` with `{ "task": "kline", "query": "NVDA", "market": "us_equity", "timeframe": "1d" }` around that date
3. Correlate surprise direction with the move.

---

## 8. Ratings request (unsupported)

**User:** Any recent analyst upgrades on NVDA?

**Flow:**
1. Do **not** call `estimates_earnings_query` `task: ratings` (invalid_task).
2. Tell the user analyst ratings / target prices are **not in this release**.
3. Offer `task: consensus` for estimate consensus instead, if useful.

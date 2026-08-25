---
version: v1.4.2
last_updated: 2026-08-25
---

# GateData Agent Runtime Rules

> Shared runtime rules for all GateData agent skills.
> Each domain skill's `SKILL.md` (in a skill subdirectory) should include:
> `Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) first.`
> Flat docs in this folder use `./` for sibling links (e.g. [disambiguation](./gatedata-skills-disambiguation.md)).

---

## 0. Intent routing (MUST read first)

⚠️ Before selecting a domain skill, read [gatedata-skills-disambiguation.md](./gatedata-skills-disambiguation.md).

For **cross-domain** questions (price + news, prediction + market, earnings + price), see [gatedata-composite-scenarios.md](./gatedata-composite-scenarios.md).

---

## 1. MCP Detection

Before using GateData data capabilities, verify MCP is configured.

**Detection:**

- List MCP tools (`tools/list` or client MCP panel)
- GateData MCP exposes **6 domain-level tools**:
  `assets_resolve`, `market_data_query`, `prediction_markets_query`,
  `events_news_query`, `fundamentals_query`, `estimates_earnings_query`
- If any of these exist → GateData MCP is configured
- Server name may be **`GateData`**, **`GateData.AI`**, or any entry pointing to `mcp.gatedata.ai`
- Streamable `/mcp` remains compatible across client protocol revisions (including MCP **`2026-07-28`** when negotiated); installer remote config stays the same

> Legacy fine-grained names (`markets_get_snapshot`, `prediction_get_rankings`, `signals_search_news`, …)
> no longer appear in `tools/list`. They remain callable as invoke aliases, but **prefer the domain tools + `task` param**.

**If MCP is not configured:**

- Offer one-click install from this repository:
  `https://github.com/gate/gate-data-ai-agent`
- Ask user consent, then run:
  `bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor`
  or skills-only: `bash scripts/sync-skills.sh --platform cursor`
- After install, restart the client and retry the original task.

---

## 2. Authentication

| Error | Recovery |
|-------|----------|
| HTTP 401 / unauthorized | Verify production API key (`gd_live_*`), `enable_mcp`, and scopes on Dashboard |
| Scope denied | Enable the matching scope on the API key (see table below). Install path `/mcp/assets` ≠ scope `assets`. |
| Plan / domain not included | Free = markets/assets/prediction; **Plus+** for `signals`; **Pro/Enterprise** for fundamentals & earnings |

**Scopes ↔ tools (full skill pack):**

| Scope | Tools |
|-------|-------|
| `markets` | `market_data_query` |
| `assets` | `assets_resolve` |
| `prediction` | `prediction_markets_query` |
| `signals` | `events_news_query` |
| `fundamentals` | `fundamentals_query` |
| `earnings` | `estimates_earnings_query` |

Recommended install scopes: `markets`, `assets`, `prediction`, `signals`, `fundamentals`, `earnings`.

**Never** paste full API keys into chat. Guide user to [gatedata.ai](https://gatedata.ai) Dashboard or `~/.gatedata/config.yaml`.

---

## 3. Tool Selection

- Each domain tool is **multi-task**: pass an explicit public `task` (prefer not relying on omitted/`auto` when the enum is narrow).
- Use **AgentCard** hints in tool descriptions (`Use when`, `Do not use when`, `Next tools`).
- Prefer **`object_refs`** to chain calls and avoid re-resolution.
- Equity tickers require `market` / `context.market` as StandardMarket (`us_equity`, `hk_equity`, `kr_equity`, `uk_equity`, `jp_equity`, `crypto`).
- **Phase-1 hard cuts (do not call):**
  - `events_news_query`: only `content_search` | `event_search` | `social_search` | `sentiment` (no `news`/`events`/`ugc`/`auto`/`event_detail`/`announcements`/`ratings`/`insight`)
  - `estimates_earnings_query`: only `auto` | `calendar` | `results` | `consensus` (no `ratings` / `summary` / `transcript` / `guidance`)
  - `assets_resolve`: no `universe`
- Prefer first-class market tasks (`orderbook`, `trades`, `cex_derivatives`, `liquidation_heatmap`, `technical_indicators`, …) over legacy `field_group`.
- Fundamentals crypto: `tokenomics` / `supply` are live; avoid not-ready `signals` / weak `valuation_metrics`.
- For earnings guidance/transcript **intents**, never call those tasks and never rely on `task: auto` — force `results` / `consensus` (`estimate_metric: guidance` ≠ `task: guidance`).
- Discovery: `GET /api/v1/mcp/tools?live=true` (only `real_data=true` tools are production-ready). Catalog may list planned tools (`ownership_flows_query`, `risk_compliance_query`) that are **not** in live `tools/list`.

**Skill routing:**

| User intent | Skill | Primary tool |
|-------------|-------|--------------|
| Price, K-line, order book, derivatives, TradFi indicators | `gatedata-market-research` | `market_data_query` |
| Prediction markets, rankings, odds | `gatedata-prediction-markets` | `prediction_markets_query` |
| News, sentiment, events, social (X/YouTube) | `gatedata-signals-news` | `events_news_query` |
| Fundamentals, statements, tokenomics, earnings, consensus | `gatedata-fundamentals-earnings` | `fundamentals_query`, `estimates_earnings_query` |
| Symbol / contract / listing resolution | `gatedata-assets-resolve` | `assets_resolve` |
| Install / MCP missing | `gatedata-mcp-installer` | — |

### assets_resolve (see also `gatedata-assets-resolve`)

Use before other tools when the entity is ambiguous (stock vs token, contract address, Gate symbol). Full playbooks: [gatedata-assets-resolve/SKILL.md](./gatedata-assets-resolve/SKILL.md).

| Task | Use when |
|------|----------|
| `auto` / `resolve` / `search` | NL ticker / name / address lookup |
| `profile` | Asset **object metadata** (`asset_id` if no `query`) — not equity company fundamentals |
| `listings` | Venue listings for an asset |
| `deployments` | On-chain deployments (crypto) |
| `coverage` | Coverage probe |

Do **not** call `universe`. HTTP **200** + `resolution_status=ambiguous` + `data[]` candidates is success with choice — ask the user. After resolve, chain with `object_refs` into market / fundamentals / earnings / signals.

---

## 4. Error Recovery

- Follow API `next_action` / recoverable error fields when present.
- On ambiguous query (e.g. "Apple" = stock vs token), ask one clarifying question before calling tools, or resolve via `assets_resolve` first.
- `assets_resolve` may return HTTP **200** with `resolution_status=ambiguous` and candidate rows — ask the user to pick; do not treat as a tool failure.
- On `invalid_task`, remap to the phase-1 public enum for that tool (do not retry the same rejected task).
- On rate limit / billing errors, suggest checking Dashboard credits.

---

## 5. Version & Updates

- Skill version is in each `SKILL.md` frontmatter.
- This skill does **not** auto-update at runtime.
- Check for updates: `bash scripts/sync-skills.sh --check`
- To sync: `bash scripts/sync-skills.sh --platform cursor`
- Product docs: [gatedata.ai/docs](https://gatedata.ai/docs) (EN) · [gatedata.ai/zh-hans/docs](https://gatedata.ai/zh-hans/docs) (ZH)

---

## 6. Safety

1. Read-only data queries by default — no trading or write operations via GateData MCP.
2. Do not exfiltrate API keys or user credentials.
3. Cite data timestamps when presenting market data (prices go stale quickly).

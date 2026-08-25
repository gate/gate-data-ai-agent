# Changelog

All notable changes to this repository are documented here.

## 0.2.9 — 2026-08-25

### Fixed

- Scrub internal protocol-engineering wording from public docs (keep user-facing compatibility guidance only)

## 0.2.8 — 2026-08-25

### Added

- Document MCP protocol compatibility: existing clients keep working; newer MCP revisions (including `2026-07-28`) negotiate automatically — no installer config change
- Installer skill / EN+ZH install + getting-started + runtime rules note client negotiation

## 0.2.7 — 2026-08-25

### Fixed

- Earnings: public MCP tasks are only `auto`/`calendar`/`results`/`consensus` — drop `transcript`/`guidance` (API 0814)
- Signals: document YouTube `has_object_refs`, `source_published_at` time filters, `video_viewpoint`, crypto `object_signals` / `signal_strength`, sentiment `author_info`
- Market: clarify kline `from`/`to` window semantics for equity and crypto live paths

## 0.2.6 — 2026-08-13

### Fixed

- Align all skills with current API MCP contracts (still 6 live domain tools)
- Signals: phase-1 tasks only (`content_search` / `event_search` / `social_search` / `sentiment`); drop legacy `news`/`events`/`ugc`/`auto`/`event_detail`/`announcements`/`ratings`/`insight`
- Earnings: drop public `ratings`/`summary`; ratings/target prices not in this release; guidance/transcript intents → `results`/`consensus`
- Assets: remove `universe` (phase-1 reject); clarify assets `profile` vs fundamentals company profile
- Market: prefer first-class tasks (`orderbook`, `trades`, `cex_derivatives`, `liquidation_heatmap`, `technical_indicators`); equity surfaces + TradFi AI indicators
- Fundamentals: teach live crypto `tokenomics`/`supply`
- Runtime / disambiguation / composite / getting-started + verify guards updated

## 0.2.5 — 2026-08-02

### Fixed

- Harden release hygiene for the public distribution tree

## 0.2.4 — 2026-08-02

### Fixed

- Signals troubleshooting no longer recommends market `task: move` as causal fallback
- Getting-started intros cover assets + fundamentals/earnings; README_zh community links; installer ZH getting-started link
- Clarify composite wording (move = thin, not planned); disambiguation → composite cross-link

## 0.2.3 — 2026-08-02

### Fixed

- Warn that earnings `task: auto` routes guidance/transcript intents to planned tasks — force `results`/`summary`/`consensus`
- Clarify `estimate_metric: guidance` ≠ planned `task: guidance`
- Fix relative links for install layout (`runtime-rules`, `skills/README`, market troubleshooting)
- Refresh composite scenarios (assets-resolve playbook); cross-link assets-resolve from prediction/signals
- verify.sh asserts link layout + earnings auto/metric warnings

## 0.2.2 — 2026-08-02

### Added

- New skill `gatedata-assets-resolve` for `assets_resolve` (search/profile/listings/deployments/universe/coverage) with ambiguous-resolution playbooks

### Fixed (carried from 0.2.1)

- Fundamentals/earnings scopes and plan domains; demoted planned tasks; market `field_group` accuracy; public README hygiene

## 0.2.1 — 2026-08-02

### Fixed

- Fundamentals/earnings scopes: `fundamentals_query` requires `fundamentals`, `estimates_earnings_query` requires `earnings` (`assets` alone is not enough; install path `/mcp/assets` ≠ scope `assets`)
- Installer / getting-started / runtime-rules now list all six scopes and note plan domains (Plus+ for signals; Pro/Enterprise for fundamentals/earnings)
- Demoted planned/not-ready tasks from primary call paths: earnings `transcript`/`guidance`, signals `anomalies`/`market_move_evidence`, prediction `probability_history`/`volume_delta`
- Signals examples use StandardMarket `us_equity` (not bare `us`)
- Documented `assets_resolve` ambiguous resolution (HTTP 200 + `resolution_status=ambiguous`)
- Market skill: bare `summary` is snapshot-only; document `field_group` for book/trades/liquidity and extended crypto derivatives/liquidation routes; `anomaly`/`move` marked as thin snapshot wrappers
- Removed non-public smoke-test references from README
- README_zh now mirrors EN API key / plan prerequisites

## 0.2.0 — 2026-07-31

### Changed

- Aligned all skills with the consolidated GateData MCP tool surface: 6 domain-level tools
  (`assets_resolve`, `market_data_query`, `prediction_markets_query`, `events_news_query`,
  `fundamentals_query`, `estimates_earnings_query`) routed by `task`, replacing the legacy
  fine-grained `markets_*` / `prediction_*` / `signals_*` names (still callable as invoke aliases,
  no longer listed in `tools/list`)
- MCP detection, verification steps, and docs now reference the domain tools
- Signals skill covers new unified search tasks (`content_search`, `event_search`, `social_search`)
- API key scope guidance includes `assets`, `fundamentals`, and `earnings` as needed

### Added

- New skill `gatedata-fundamentals-earnings`: company fundamentals (`fundamentals_query`)
  and earnings / analyst estimates (`estimates_earnings_query`)
- Earnings + price reaction composite scenario

## 0.1.0 — 2026-07-13

### Added

- Public GateData MCP installer for Cursor, Claude Code, and Codex
- Domain skills: market research, prediction markets, signals & news
- Shared runtime rules, skill disambiguation, and composite scenarios
- Bootstrap / sync / status / verify helper scripts
- GitHub Actions verify workflow
- SECURITY.md, issue templates, and pull request template
- CODE_OF_CONDUCT.md

### Notes

- Production MCP only (`mcp.gatedata.ai`)
- Remote HTTP MCP is the recommended install path; stdio requires a local `gatedata` binary

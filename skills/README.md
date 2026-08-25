# GateData Agent Skills

User-facing skills for GateData MCP (production). Install via [gatedata-mcp-installer](./gatedata-mcp-installer/SKILL.md).

| Skill | Domain | MCP scope |
|-------|--------|-----------|
| [gatedata-mcp-installer](./gatedata-mcp-installer/SKILL.md) | One-click MCP + skills install | — |
| [gatedata-runtime-rules.md](./gatedata-runtime-rules.md) | Shared runtime rules (all skills) | — |
| [gatedata-market-research](./gatedata-market-research/SKILL.md) | Prices, K-line, order book, derivatives, TradFi indicators (`market_data_query`) | `markets` |
| [gatedata-prediction-markets](./gatedata-prediction-markets/SKILL.md) | Prediction events, rankings, odds (`prediction_markets_query`) | `prediction` |
| [gatedata-signals-news](./gatedata-signals-news/SKILL.md) | Content/event/social search + sentiment (`events_news_query`) | `signals` |
| [gatedata-fundamentals-earnings](./gatedata-fundamentals-earnings/SKILL.md) | Fundamentals, tokenomics, earnings calendar/results/consensus | `fundamentals`, `earnings` |
| [gatedata-assets-resolve](./gatedata-assets-resolve/SKILL.md) | Ticker/name/address resolve, listings, deployments (`assets_resolve`) | `assets` |

**Not included yet:** `gatedata-onchain` (`ownership_flows_query` is planned, not live).

| Shared reference | Purpose |
|------------------|---------|
| [gatedata-skills-disambiguation.md](./gatedata-skills-disambiguation.md) | Intent routing across skills |
| [gatedata-composite-scenarios.md](./gatedata-composite-scenarios.md) | Cross-skill playbooks (price + news, prediction + market, earnings + price) |

All skills assume MCP server **`GateData`** at `https://mcp.gatedata.ai/mcp`, which exposes 6 domain-level tools: `assets_resolve`, `market_data_query`, `prediction_markets_query`, `events_news_query`, `fundamentals_query`, `estimates_earnings_query`.

Full skill pack scopes: `markets`, `assets`, `prediction`, `signals`, `fundamentals`, `earnings`. Note: install path `/mcp/assets` for fundamentals/earnings ≠ API scope `assets`. Plan domains: Plus+ for signals; Pro/Enterprise for fundamentals/earnings.

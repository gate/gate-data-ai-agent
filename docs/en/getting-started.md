# Getting Started

This repository provides a **MCP installer** and **user-facing Agent Skills** for asset resolution, market data, prediction markets, news/signals, and fundamentals/earnings in Cursor, Claude Code, or Codex.

**Environment: production only** (`https://mcp.gatedata.ai/mcp`).

The MCP endpoint stays compatible with current clients and supports newer MCP protocol revisions when the client negotiates them — **no installer config change required**. Details: [install.md](./install.md#mcp-protocol-compatibility).

---

## 1. Create an API Key

1. Open [gatedata.ai](https://gatedata.ai) → Dashboard → **API Keys**
2. Create a key (`gd_live_*`)
3. Enable **`enable_mcp`**
4. Select scopes: `markets`, `assets`, `prediction`, `signals`, `fundamentals`, `earnings` (as needed). Plan domains: **Plus+** for `signals`; **Pro or Enterprise** for fundamentals/earnings. Free covers markets/assets/prediction.

---

## 2. Install

### Option A: Natural language (Cursor Agent)

```
Help me auto install GateData MCP: https://github.com/gate/gate-data-ai-agent
```

### Option B: Git clone

```bash
git clone https://github.com/gate/gate-data-ai-agent.git
cd gate-data-ai-agent
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor --api-key gd_live_xxx
```

If `~/.cursor/mcp.json` **already has** a GateData MCP server (e.g. `GateData.AI`), the installer **syncs skills only** by default:

```bash
bash scripts/sync-skills.sh --platform cursor
```

### Option C: One-line curl

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor --api-key gd_live_xxx
```

From an existing clone: `bash scripts/bootstrap.sh --platform cursor --api-key gd_live_xxx`

### Option D: Skills CLI (skills only)

```bash
npx skills add https://github.com/gate/gate-data-ai-agent
```

> `npx skills add` installs skills only — it does **not** write MCP config. Use `install.sh` for MCP.

---

## 3. Restart and verify

```bash
bash scripts/status.sh --platform cursor --live
```

1. Restart Cursor (or reload MCP)
2. MCP panel should show a GateData server
3. Tools list includes the 6 domain tools: `assets_resolve`, `market_data_query`, `prediction_markets_query`, `events_news_query`, `fundamentals_query`, `estimates_earnings_query`

---

## 4. Try these prompts

| You ask | Expected skill / tool |
|---------|------------------------|
| What is the BTC price? | `gatedata-market-research` → `market_data_query` (`task: snapshot`) |
| Top prediction markets by volume | `gatedata-prediction-markets` → `prediction_markets_query` (`task: rankings`) |
| Recent BTC news | `gatedata-signals-news` → `events_news_query` (`task: content_search`) |
| When is NVDA's next earnings? | `gatedata-fundamentals-earnings` → `estimates_earnings_query` (`task: calendar`) |
| Resolve Apple (stock vs token) | `gatedata-assets-resolve` → `assets_resolve` |

---

## 5. Installed skills

| Skill | Purpose |
|-------|---------|
| `gatedata-mcp-installer` | Install / update |
| `gatedata-market-research` | Prices, K-line, order book, derivatives |
| `gatedata-prediction-markets` | Prediction markets |
| `gatedata-signals-news` | News, sentiment, events |
| `gatedata-fundamentals-earnings` | Fundamentals, financial statements, earnings, estimates |
| `gatedata-assets-resolve` | Ticker / contract / listings resolution |

---

## Next steps

- Installer flags: [install.md](./install.md)
- Other distribution paths: [distribution.md](./distribution.md)
- Product API docs: [gatedata.ai/docs](https://gatedata.ai/docs)

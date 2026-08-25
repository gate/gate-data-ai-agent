---
name: gatedata-mcp-installer
version: "2026.8.25"
updated: "2026-08-25"
description: "One-click installer for GateData MCP and agent skills on Cursor, Claude Code, or Codex. Triggers on 'install GateData MCP', 'setup GateData Cursor', 'GateData skills', '接入 GateData', '安装 GateData MCP', 'GateData agent'."
---

# GateData MCP Installer

## General Rules

⚠️ STOP — Read [gatedata-runtime-rules.md](../gatedata-runtime-rules.md) before proceeding.

- **Only call MCP tools documented in domain skills.** Undocumented tools must NOT be called without user intent.
- **Never echo API keys** in chat or installer output.

---

## MCP Dependencies

### Required MCP Server (after install)

| MCP Server | Endpoint |
|------------|----------|
| `GateData` | `https://mcp.gatedata.ai/mcp` |

Production Streamable MCP is **backward compatible** with current clients and supports newer MCP protocol revisions (including **`2026-07-28`**) when negotiated. Existing remote configs keep working. See [install.md](../../docs/en/install.md#mcp-protocol-compatibility).

### API Key Prerequisites

Create a production key at [gatedata.ai](https://gatedata.ai):

| Setting | Required |
|---------|----------|
| `enable_mcp` | ✅ |
| scopes | `markets`, `assets`, `prediction`, `signals`, `fundamentals`, `earnings` (as needed) |
| plan | **Plus+** for `signals`; **Pro or Enterprise** for fundamentals/earnings; Free covers markets/assets/prediction |

---

## Installation Check

1. Run the installer script (preferred), or guide the user to run it.
2. If multiple clients exist on one machine (Cursor + Claude), the script requires `--platform`.

---

## Execution

**Read and follow** [`references/mcp.md`](./references/mcp.md), then run:

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor
```

### Flags

| Flag | Meaning |
|------|---------|
| `--platform` | `cursor` \| `claude` \| `codex` |
| `--mode` | `remote` (default, Streamable HTTP) \| `stdio` (`gatedata mcp-bridge`) |
| `--api-key` | `gd_live_*` |
| `--gatedata-bin` | Path to `gatedata` binary (stdio mode) |
| `--no-skills` | MCP config only |
| `--skills-only` | Sync skills only; no MCP changes |
| `--dry-run` | Preview without writing files |
| `--force-mcp` | Update MCP even if GateData already configured |

Skills update check: `bash scripts/sync-skills.sh --check`

### API key resolution

1. `--api-key`
2. `GATEDATA_API_KEY` env
3. Existing MCP config GateData Bearer (Cursor/Claude JSON, Codex TOML) via `read-api-key.js`
4. `~/.gatedata/config.yaml`
5. Interactive prompt (hidden input; skipped with `--skills-only`)

---

## Platform matrix

| Platform | MCP config | Skills directory |
|----------|------------|------------------|
| **Cursor** | `~/.cursor/mcp.json` | `~/.cursor/skills/` |
| **Claude Code** | `~/.claude.json` → `mcpServers` | `~/.claude/skills/` |
| **Codex** | `~/.codex/config.toml` | `~/.codex/skills/` |

---

## Verification

After install and client restart:

1. MCP panel shows `GateData`
2. `tools/list` includes the 6 domain tools: `assets_resolve`, `market_data_query`, `prediction_markets_query`, `events_news_query`, `fundamentals_query`, `estimates_earnings_query`
3. Test call: ask user "BTC 现价" — should route to `market_data_query` (`task: snapshot`)

---

## Resources

| Type | Link |
|------|------|
| Domain skills | `gatedata-market-research`, `gatedata-prediction-markets`, `gatedata-signals-news`, `gatedata-fundamentals-earnings`, `gatedata-assets-resolve` |
| Getting started (EN) | [docs/en/getting-started.md](../../docs/en/getting-started.md) |
| Getting started (ZH) | [docs/zh-hans/getting-started.md](../../docs/zh-hans/getting-started.md) |
| API docs (EN) | https://gatedata.ai/docs |
| API docs (ZH) | https://gatedata.ai/zh-hans/docs |
| MCP setup | [gatedata.ai/docs](https://gatedata.ai/docs) |

---

## One-click prompts

**中文：**

```
帮我自动安装 GateData MCP：https://github.com/gate/gate-data-ai-agent
```

**English:**

```
Help me auto install GateData MCP: https://github.com/gate/gate-data-ai-agent
```

# Installer Reference

Entry script: `skills/gatedata-mcp-installer/scripts/install.sh`

---

## Command

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh [options]
```

| Flag | Description | Default |
|------|-------------|---------|
| `--platform` | `cursor` / `claude` / `codex` | Auto-detect |
| `--mode` | `remote` (HTTP) / `stdio` (`gatedata mcp-bridge`) | `remote` |
| `--api-key` | Production key `gd_live_*` | See resolution order below |
| `--skills-only` | Sync skills only; no MCP changes | off |
| `--dry-run` | Preview without writing files | off |
| `--force-mcp` | Update MCP even if GateData is already configured | off |
| `--no-skills` | MCP config only; skip skills | off |
| `--gatedata-bin` | Path to `gatedata` binary (stdio mode) | Auto-detect |

---

## API key resolution order

1. `--api-key`
2. Environment variable `GATEDATA_API_KEY`
3. Existing GateData Bearer in MCP config (Cursor/Claude: `mcp.json`; Codex: `config.toml`)
4. `api_key` in `~/.gatedata/config.yaml`
5. Interactive prompt (skipped with `--skills-only`)

Implementation: `skills/gatedata-mcp-installer/scripts/read-api-key.js`

---

## MCP configuration

**Remote (default)** — writes a `GateData` server:

```json
{
  "GateData": {
    "url": "https://mcp.gatedata.ai/mcp",
    "transport": "streamable-http",
    "timeout": 60,
    "headers": {
      "Accept": "application/json, text/event-stream",
      "Authorization": "Bearer gd_live_xxx"
    }
  }
}
```

**Stdio** — requires a local `gatedata` binary connecting to `https://api.gatedata.ai`.

### MCP protocol compatibility

GateData Streamable MCP (`POST/GET /mcp`) is **backward compatible** with current Cursor / Claude / Codex clients and also supports the newer MCP **`2026-07-28`** revision when the client negotiates it.

- **Existing installer configs do not need changes** (same URL, API key, `streamable-http`).
- Clients negotiate the protocol revision automatically.
- REST and other non-Streamable MCP paths are unaffected.
- Product docs: [gatedata.ai/docs](https://gatedata.ai/docs)

---

## Smart behavior

- If GateData MCP already exists (URL contains `gatedata.ai` or name matches `GateData*`) → **skills only** by default
- With `--force-mcp`, **updates the existing** GateData server in place (no duplicate entry)
- Backs up config to `*.bak.YYYYMMDD-HHMMSS` before writing
- Sets `chmod 600` on config files
- Optionally probes the tools API before install

---

## Helper scripts

```bash
bash scripts/sync-skills.sh --platform cursor   # same as --skills-only
bash scripts/sync-skills.sh --check             # compare installed vs repo versions
bash scripts/status.sh --platform cursor --live # status (cursor/claude/codex)
bash scripts/check-remote.sh                    # GitHub raw URL check
bash scripts/verify.sh                          # CI static checks
```

---

## Agent skill

The installer is also an Agent Skill: `skills/gatedata-mcp-installer/SKILL.md`  
Execution spec: `skills/gatedata-mcp-installer/references/mcp.md`

---
name: gatedata-mcp-installer-mcp
version: "2026.8.25"
updated: "2026-08-25"
description: "Execution specification for GateData MCP + agent skills installer (Cursor, Claude Code, Codex). Production environment only."
---

# GateData MCP Installer — execution specification

## 1. Scope

**In scope**

- Detect or accept target platform; merge/write MCP config without removing unrelated servers.
- Install GateData **production** MCP (remote Streamable HTTP by default, or stdio bridge).
- Clone **gate-data-ai-agent** skills into the platform skills directory unless `--no-skills`.

**Out of scope**

- Non-production / staging endpoints.
- Creating API keys (user must use gatedata.ai Dashboard).
- Trading, billing, or data queries (installer only).
- Forcing a single MCP protocol revision (server negotiates with the client).

---

## 1.1 Protocol compatibility

GateData `POST/GET /mcp` works with current Cursor / Claude / Codex setups and supports newer MCP protocol revisions (including **`2026-07-28`**) when the client negotiates them.

- Installer remote fragment: `transport: streamable-http`, `Accept: application/json, text/event-stream`, Bearer API key — **unchanged**.
- Do **not** tell users to rotate keys or change URL solely for protocol compatibility.
- Stdio `gatedata mcp-bridge` follows the bridge/client negotiation path.

---

## 2. Platform detection

1. If `--platform cursor|claude|codex` is set, use it.
2. Otherwise detect:
   - **cursor**: `~/.cursor` (Windows: `%APPDATA%\Cursor`)
   - **claude**: `~/.claude.json` or `~/.claude/`
   - **codex**: `$CODEX_HOME` or `~/.codex/`
3. If **more than one** signal → **stop**, require `--platform`.
4. If **none** → stop with install instructions.

**Fallback**

- If Node is missing (Cursor / Claude): print JSON fragment for manual merge.

---

## 3. Authentication

- Installer requires a **production** GateData API key (`gd_live_*`) with Bearer auth.
- Key must have `enable_mcp` enabled.
- Installer masks key in output (`gd_l...xxxx` format).
- Never log or echo full key.

---

## 4. Entrypoint

```bash
skills/gatedata-mcp-installer/scripts/install.sh
```

| Flag | Meaning |
|------|---------|
| `--platform` | `cursor` \| `claude` \| `codex` |
| `--mode` | `remote` \| `stdio` |
| `--api-key` | Production API key (`gd_live_*`) |
| `--skills-only` | Sync skills only; no MCP changes |
| `--dry-run` | Preview without writing |
| `--force-mcp` | Merge MCP even if GateData already configured |

`--env` is **not supported** (production only).

---

## 5. Execution SOP

1. Confirm mode (`remote` vs `stdio`).
2. Resolve platform; abort if ambiguous without `--platform`.
3. Resolve API key (flag → env → MCP config via read-api-key.js → config.yaml → prompt).
4. Run `install.sh` with agreed flags.
5. Verify:
   - **Cursor / Claude**: `mcpServers.GateData` in JSON.
   - **Codex**: `[mcp_servers.GateData]` in `config.toml`.
6. Tell user to restart client; mask secrets in summary.
7. Optional: after restart, `tools/list` should show the 6 domain tools.

---

## 6. Output template

```markdown
## Installer Result
- Platform: {cursor|claude|codex}
- Environment: prod
- Mode: {remote|stdio}
- MCP Server: GateData
- Skills Installed: {yes|no}
- Config: {path}
- Next Steps: restart client + verify tools/list
```

---

## 7. Safety

1. Never delete unrelated MCP server entries.
2. On malformed JSON, stop and explain remediation.
3. Do not claim success without config write confirmation.
4. Do not echo API secrets.

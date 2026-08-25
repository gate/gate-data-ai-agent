# Distribution & Install Paths

Install and distribution options beyond `install.sh`. Quick start: [getting-started.md](./getting-started.md).

---

## 1. One-line bootstrap (curl)

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor --api-key gd_live_xxx
```

From a local clone:

```bash
bash scripts/bootstrap.sh --platform cursor --api-key gd_live_xxx
```

---

## 2. Skills ecosystem (Cursor `npx skills`)

Same as [gate-skills](https://github.com/gate/gate-skills), Cursor users can install via the official CLI:

```bash
npx skills add https://github.com/gate/gate-data-ai-agent
```

Install a single skill:

```bash
npx skills add https://github.com/gate/gate-data-ai-agent --skill gatedata-market-research
```

> **Note:** `npx skills add` installs skills only — it does **not** write MCP config. Use `gatedata-mcp-installer` or `install.sh` for `~/.cursor/mcp.json`.
>
> Check if local skills match the repo: `bash scripts/sync-skills.sh --check`

---

## 3. Stdio mode (developers)

Requires a locally available `gatedata` binary that talks to `https://api.gatedata.ai`:

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh \
  --platform cursor \
  --mode stdio \
  --gatedata-bin /path/to/gatedata \
  --api-key gd_live_xxx
```

Stdio is optional. Most users should use **remote** MCP. A download helper exists at `scripts/install-gatedata-cli.sh` only if you set `GATEDATA_CLI_RELEASE_BASE` and `GATEDATA_CLI_VERSION` yourself.

---

## 4. Natural language (Cursor Agent)

```
Help me auto install GateData MCP: https://github.com/gate/gate-data-ai-agent
```

---

## 5. Verification

```bash
bash scripts/verify.sh
bash scripts/verify.sh --live gd_live_xxx
bash scripts/status.sh --platform cursor --live
bash scripts/sync-skills.sh --check
```

---

## Related docs

- [getting-started.md](./getting-started.md)
- [install.md](./install.md)

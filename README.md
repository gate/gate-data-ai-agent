# gate-data-ai-agent

GateData agent distribution layer: one-click MCP config, Agent Skills, and runtime rules.

MCP/API capabilities: [gatedata.ai/docs](https://gatedata.ai/docs).  
Pattern follows [gate-skills](https://github.com/gate/gate-skills) `gate-mcp-installer`.

**Production only** (`gatedata.ai` / `mcp.gatedata.ai`).  
中文说明：[README_zh.md](README_zh.md)

## Quick install

Tell Cursor Agent:

```
Help me auto install GateData MCP: https://github.com/gate/gate-data-ai-agent
```

Or clone and run:

```bash
git clone https://github.com/gate/gate-data-ai-agent.git
cd gate-data-ai-agent
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor
```

One-line bootstrap:

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor
```

Create a production API key at [gatedata.ai](https://gatedata.ai) (`gd_live_*`, `enable_mcp`, scopes: `markets`, `assets`, `prediction`, `signals`, `fundamentals`, `earnings`). Plan domains: **Plus+** for `signals`; **Pro or Enterprise** for fundamentals/earnings. Free covers markets/assets/prediction.

Full guide: [docs/en/getting-started.md](docs/en/getting-started.md) · [中文](docs/zh-hans/getting-started.md)

## Commands

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor --api-key gd_live_xxx
bash scripts/sync-skills.sh --platform cursor      # skills only
bash scripts/sync-skills.sh --check                # compare installed vs repo
bash scripts/status.sh --platform cursor --live
bash scripts/check-remote.sh                       # verify GitHub raw URLs
bash scripts/verify.sh
```

| Flag | Description |
|------|-------------|
| `--skills-only` | Sync skills only (no MCP changes) |
| `--dry-run` | Preview without writing |
| `--force-mcp` | Merge MCP even if GateData already configured |

## License

MIT — see [LICENSE](LICENSE).

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Security

See [SECURITY.md](SECURITY.md).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Layout

```
skills/                 # Installer + domain skills
scripts/                # bootstrap, sync-skills, status, verify
docs/                   # User docs (en/ + zh-hans/)
```

## Documentation

| English | 中文 |
|---------|------|
| [getting-started.md](docs/en/getting-started.md) | [getting-started.md](docs/zh-hans/getting-started.md) |
| [install.md](docs/en/install.md) | [install.md](docs/zh-hans/install.md) |
| [distribution.md](docs/en/distribution.md) | [distribution.md](docs/zh-hans/distribution.md) |
| [docs index](docs/README.md) | |

Script reference: [scripts/README.md](scripts/README.md)

## Links

- https://gatedata.ai/docs
- https://github.com/gate/gate-data-ai-agent

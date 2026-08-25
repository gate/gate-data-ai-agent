# Contributing

Thanks for contributing to GateData Agent.

## Before you open a PR

1. Run static checks: `bash scripts/verify.sh`
2. Do not commit secrets (`.env`, API keys, local `mcp.json`)
3. Keep user-facing docs in sync (English under `docs/en/`, Chinese under `docs/zh-hans/`)

Security reports: see [SECURITY.md](SECURITY.md) (do not post secrets in issues).

## Repository URL override

Default clone URL is GitHub. Override when needed:

```bash
export GATEDATA_AGENT_REPO=https://github.com/gate/gate-data-ai-agent.git
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor
```

See `scripts/repo-defaults.sh` for `GATEDATA_AGENT_GITHUB_*` variables.

## CI

- GitHub Actions: `.github/workflows/verify.yml` (every push / PR)
- GitHub Actions: `.github/workflows/check-remote.yml` (manual or weekly — verifies public raw URLs)

After changing bootstrap or install entrypoints, run:

```bash
bash scripts/check-remote.sh
```

## Related projects

- [gate-skills](https://github.com/gate/gate-skills) — Gate MCP + Skills pattern this repo follows
- Product docs: https://gatedata.ai/docs


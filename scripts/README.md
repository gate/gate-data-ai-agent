# Scripts

Helper scripts for GateData Agent install, sync, and verification.

| Script | Purpose |
|--------|---------|
| [bootstrap.sh](./bootstrap.sh) | One-line install via curl or local clone |
| [sync-skills.sh](./sync-skills.sh) | Sync skills only (`--check` to compare versions) |
| [check-skills.sh](./check-skills.sh) | Compare installed vs repo skill versions |
| [status.sh](./status.sh) | Local MCP/skills status (`--platform`, `--live`) |
| [verify.sh](./verify.sh) | CI static checks (`--live KEY` optional) |
| [verify-cli.sh](./verify-cli.sh) | Verify local `gatedata` CLI (`--rebuild`, `--platform`) |
| [check-remote.sh](./check-remote.sh) | Verify GitHub raw URLs |
| [install-gatedata-cli.sh](./install-gatedata-cli.sh) | Download `gatedata` binary for stdio MCP |
| [repo-defaults.sh](./repo-defaults.sh) | GitHub URL defaults (source in shell) |

## Common flows

```bash
# First install
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor

# Update skills after git pull
bash scripts/sync-skills.sh --platform cursor

# Check if skills need update
bash scripts/sync-skills.sh --check

# Status + live tools probe
bash scripts/status.sh --platform cursor --live

# Verify local gatedata CLI (requires binary + gd_live_ key)
bash scripts/verify-cli.sh
bash scripts/verify-cli.sh --rebuild

# Verify public raw URLs
bash scripts/check-remote.sh
```

Installer entry: `skills/gatedata-mcp-installer/scripts/install.sh`

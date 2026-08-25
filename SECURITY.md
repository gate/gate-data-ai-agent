# Security Policy

## Supported versions

This repository distributes GateData MCP installer scripts and Agent Skills for the **production** environment only (`mcp.gatedata.ai` / `api.gatedata.ai`).

Use the latest `main` branch (or the latest GitHub Release tag).

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security-sensitive reports (especially anything involving API keys, tokens, or account access).

Instead:

1. Revoke or rotate any exposed GateData API key in the [gatedata.ai](https://gatedata.ai) Dashboard immediately.
2. Contact GateData support through the Dashboard or the channels listed on [gatedata.ai](https://gatedata.ai).
3. Include: affected component (installer / skill / docs), impact, and reproduction steps — **without** pasting live secrets.

## Safe use notes

- Never commit API keys, `.env` files, or local `mcp.json` with real credentials.
- Prefer remote MCP (`https://mcp.gatedata.ai/mcp`) over sharing binary bridges with embedded secrets.
- The installer masks keys in terminal output; do not paste full `gd_live_*` keys into chat or issues.

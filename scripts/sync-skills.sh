#!/usr/bin/env bash
# Sync GateData agent skills only (no MCP config changes).
#
# Usage:
#   bash scripts/sync-skills.sh [--platform cursor|claude|codex]
#   bash scripts/sync-skills.sh --check [--platform cursor|claude|codex]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--check" ]]; then
  shift
  exec bash "$SCRIPT_DIR/check-skills.sh" "$@"
fi

exec bash "$SCRIPT_DIR/../skills/gatedata-mcp-installer/scripts/install.sh" --skills-only "$@"

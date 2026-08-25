#!/usr/bin/env bash
# GateData Agent one-line bootstrap.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh | bash -s -- --platform cursor --api-key gd_live_xxx
#
# Or from a local clone:
#   bash scripts/bootstrap.sh --platform cursor
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=repo-defaults.sh
if [[ -f "$REPO_ROOT/scripts/repo-defaults.sh" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/repo-defaults.sh"
fi
GATEDATA_AGENT_REPO="${GATEDATA_AGENT_REPO:-${GATEDATA_AGENT_GITHUB_REPO:-https://github.com/gate/gate-data-ai-agent.git}}"
GATEDATA_AGENT_BRANCH="${GATEDATA_AGENT_BRANCH:-main}"
INSTALL_SH="$REPO_ROOT/skills/gatedata-mcp-installer/scripts/install.sh"

run_install() {
  if [[ ! -f "$INSTALL_SH" ]]; then
    echo "Error: install.sh not found at $INSTALL_SH" >&2
    exit 1
  fi
  exec bash "$INSTALL_SH" "$@"
}

if [[ -f "$INSTALL_SH" ]]; then
  run_install "$@"
fi

if ! command -v git &>/dev/null; then
  echo "Error: git is required to clone gate-data-ai-agent." >&2
  exit 1
fi

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t gatedata-agent)
trap 'rm -rf "$TMP"' EXIT

echo "Cloning gate-data-ai-agent..."
git clone --depth 1 -b "$GATEDATA_AGENT_BRANCH" "$GATEDATA_AGENT_REPO" "$TMP"

INSTALL_SH="$TMP/skills/gatedata-mcp-installer/scripts/install.sh"
[[ -f "$INSTALL_SH" ]] || { echo "install.sh missing in clone" >&2; exit 1; }

bash "$INSTALL_SH" "$@"

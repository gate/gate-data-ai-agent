#!/usr/bin/env bash
# Verify public GitHub raw URLs used by curl bootstrap (release checklist).
#
# Usage:
#   bash scripts/check-remote.sh
#   GATEDATA_AGENT_GITHUB_RAW=https://raw.githubusercontent.com/org/repo/main bash scripts/check-remote.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=repo-defaults.sh
if [[ -f "$REPO_ROOT/scripts/repo-defaults.sh" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/repo-defaults.sh"
fi

RAW_BASE="${GATEDATA_AGENT_GITHUB_RAW:-https://raw.githubusercontent.com/gate/gate-data-ai-agent/main}"
WEB="${GATEDATA_AGENT_GITHUB_WEB:-https://github.com/gate/gate-data-ai-agent}"

paths=(
  scripts/bootstrap.sh
  skills/gatedata-mcp-installer/scripts/install.sh
)

echo "== Remote URL check =="
echo "  Raw base: $RAW_BASE"
echo "  Web:      $WEB"
echo ""

FAIL=0
for rel in "${paths[@]}"; do
  url="${RAW_BASE%/}/${rel}"
  code=$(curl -sS -m 15 -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "  OK  $rel (HTTP $code)"
  else
    echo "  !!  $rel (HTTP $code)"
    FAIL=1
  fi
done

echo ""
if [[ $FAIL -eq 1 ]]; then
  echo "Public raw URLs unreachable. Confirm main is pushed and raw.githubusercontent.com is serving this repo."
  exit 1
fi
echo "All remote URLs reachable."

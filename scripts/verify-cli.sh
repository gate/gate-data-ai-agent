#!/usr/bin/env bash
# Verify local gatedata CLI against production API.
#
# Usage:
#   bash scripts/verify-cli.sh [--platform cursor|claude|codex]
#   bash scripts/verify-cli.sh --rebuild [--platform cursor|claude|codex]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
READ_KEY_JS="$REPO_ROOT/skills/gatedata-mcp-installer/scripts/read-api-key.js"
API_REPO="${GATEDATA_API_REPO:-}"
REBUILD=0
PLATFORM="cursor"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rebuild) REBUILD=1; shift ;;
    --platform)
      shift
      case "${1:-}" in
        cursor|claude|codex) PLATFORM="$1" ;;
        *) echo "Unknown --platform: ${1:-}" >&2; exit 1 ;;
      esac
      shift
      ;;
    -h|--help)
      echo "Usage: verify-cli.sh [--rebuild] [--platform cursor|claude|codex]"
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

mask_api_key() {
  local key="$1"
  printf '%s...%s' "${key:0:7}" "${key: -4}"
}

extract_price() {
  node -e '
const fs = require("fs");
const raw = fs.readFileSync(0, "utf8").trim();
if (!raw) {
  process.stderr.write("empty CLI output\n");
  process.exit(1);
}
let body;
try {
  body = JSON.parse(raw);
} catch {
  process.stderr.write("invalid JSON from CLI\n");
  process.exit(1);
}
const price = body.price ?? (body.data && body.data.price);
if (price == null) {
  process.stderr.write("missing price field\n");
  process.exit(1);
}
process.stdout.write(String(price));
'
}

run_cli_expect_ok() {
  local label="$1"
  shift
  local err
  err=$(mktemp "${TMPDIR:-/tmp}/gd-verify-cli.err.XXXXXX")
  trap 'rm -f "$err"' RETURN
  if ! "$GATEDATA_BIN" -base-url "$GATEDATA_BASE_URL" "$@" 2>"$err"; then
    echo "  FAIL: $label" >&2
    [[ -s "$err" ]] && cat "$err" >&2
    return 1
  fi
  if [[ -s "$err" ]]; then
    cat "$err" >&2
  fi
}

run_cli_json() {
  local label="$1"
  shift
  local err out rc
  err=$(mktemp "${TMPDIR:-/tmp}/gd-verify-cli.err.XXXXXX")
  trap 'rm -f "$err"' RETURN
  set +e
  out=$("$GATEDATA_BIN" -base-url "$GATEDATA_BASE_URL" "$@" 2>"$err")
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "  FAIL: $label (exit $rc)" >&2
    [[ -s "$err" ]] && cat "$err" >&2
    return 1
  fi
  if [[ -z "$out" ]]; then
    echo "  FAIL: $label (empty stdout)" >&2
    [[ -s "$err" ]] && cat "$err" >&2
    return 1
  fi
  if [[ -s "$err" ]]; then
    cat "$err" >&2
  fi
  printf '%s' "$out"
}

resolve_gatedata_bin() {
  if [[ -n "${GATEDATA_BIN:-}" && -x "$GATEDATA_BIN" ]]; then
    return 0
  fi
  if command -v gatedata &>/dev/null; then
    GATEDATA_BIN="$(command -v gatedata)"
    return 0
  fi
  local candidates=(
    "$HOME/.local/bin/gatedata"
    "$API_REPO/bin/gatedata"
  )
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      GATEDATA_BIN="$c"
      return 0
    fi
  done
  echo "Error: gatedata binary not found." >&2
  echo "  Install gatedata on PATH, or: export GATEDATA_BIN=/path/to/gatedata" >&2
  echo "  Or rebuild: GATEDATA_API_REPO=/path/to/cli-src bash scripts/verify-cli.sh --rebuild" >&2
  exit 1
}

if [[ $REBUILD -eq 1 ]]; then
  if [[ -z "$API_REPO" || ! -d "$API_REPO" ]]; then
    echo "Error: set GATEDATA_API_REPO to a local checkout that can build the gatedata CLI." >&2
    exit 1
  fi
  echo "== Rebuilding gatedata CLI =="
  ( cd "$API_REPO" && go build -o bin/gatedata ./cmd/cli )
  mkdir -p "${HOME}/.local/bin"
  install -m 755 "$API_REPO/bin/gatedata" "${HOME}/.local/bin/gatedata"
  echo "  Installed: ${HOME}/.local/bin/gatedata"
fi

resolve_gatedata_bin
GATEDATA_BASE_URL="${GATEDATA_BASE_URL:-https://api.gatedata.ai}"
if [[ -z "${GATEDATA_API_KEY:-}" ]]; then
  GATEDATA_API_KEY=$(node "$READ_KEY_JS" "$PLATFORM" 2>/dev/null || true)
fi

if [[ -z "$GATEDATA_API_KEY" ]]; then
  echo "Error: no API key. Set GATEDATA_API_KEY or configure MCP / ~/.gatedata/config.yaml" >&2
  exit 1
fi
if [[ "$GATEDATA_API_KEY" != gd_live_* ]]; then
  echo "Error: verify-cli expects production key (gd_live_*)." >&2
  exit 1
fi

export GATEDATA_BASE_URL GATEDATA_API_KEY

echo "== GateData CLI verify =="
echo "  binary:   $GATEDATA_BIN"
echo "  base:     $GATEDATA_BASE_URL"
echo "  platform: $PLATFORM"
echo "  key:      $(mask_api_key "$GATEDATA_API_KEY")"

echo ""
echo "== health =="
run_cli_expect_ok "health" -json health >/dev/null || exit 1
echo "  OK"

echo ""
echo "== mcp ping =="
PING=$(run_cli_json "mcp ping" mcp ping) || exit 1
PING=${PING//$'\r'/}
PING=${PING//$'\n'/}
[[ "$PING" == "ok" ]] || { echo "  FAIL: unexpected ping response: $PING" >&2; exit 1; }
echo "  OK"

echo ""
echo "== call markets.snapshot =="
SNAP=$(run_cli_json "call markets.snapshot" -q call markets.snapshot --query BTC --venue gate --market_type spot) || exit 1
PRICE=$(printf '%s' "$SNAP" | extract_price) || exit 1
echo "  OK  BTC/USDT gate spot price=$PRICE"

echo ""
echo "== mcp call market_data_query =="
MCP_OUT=$(run_cli_json "mcp call market_data_query" -q mcp call --tool market_data_query \
  --args '{"task":"snapshot","query":"BTC","venue":"gate","market_type":"spot"}') || exit 1
MCP_PRICE=$(printf '%s' "$MCP_OUT" | extract_price) || exit 1
echo "  OK  MCP tool price=$MCP_PRICE"

echo ""
echo "All CLI checks passed."

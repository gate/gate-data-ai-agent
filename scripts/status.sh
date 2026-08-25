#!/usr/bin/env bash
# GateData agent installation status (local checks + optional live probe).
#
# Usage:
#   bash scripts/status.sh [--platform cursor|claude|codex]
#   bash scripts/status.sh --live          # read prod key from MCP config
#   bash scripts/status.sh --live gd_live_xxx
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_KEY_JS="$SCRIPT_DIR/../skills/gatedata-mcp-installer/scripts/read-api-key.js"

LIVE=0
LIVE_KEY=""
PLATFORM="cursor"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      shift
      case "${1:-}" in
        cursor|claude|codex) PLATFORM="$1" ;;
        *) echo "Unknown --platform: $1" >&2; exit 1 ;;
      esac
      shift
      ;;
    --live)
      LIVE=1
      shift
      if [[ $# -gt 0 && "$1" != --* ]]; then
        LIVE_KEY="$1"
        shift
      fi
      ;;
    -h|--help)
      echo "Usage: status.sh [--platform cursor|claude|codex] [--live [gd_live_xxx]]"
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

resolve_paths() {
  case "$PLATFORM" in
    cursor)
      if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "win32" ]]; then
        MCP_CONFIG="${APPDATA:-$HOME/AppData/Roaming}/Cursor/mcp.json"
        SKILLS_DIR="${APPDATA:-$HOME/AppData/Roaming}/Cursor/skills"
      else
        MCP_CONFIG="${HOME}/.cursor/mcp.json"
        SKILLS_DIR="${HOME}/.cursor/skills"
      fi
      ;;
    claude)
      MCP_CONFIG="${HOME}/.claude.json"
      SKILLS_DIR="${HOME}/.claude/skills"
      ;;
    codex)
      local h="${CODEX_HOME:-$HOME/.codex}"
      MCP_CONFIG="${h}/config.toml"
      SKILLS_DIR="${h}/skills"
      ;;
  esac
}

skill_version() {
  local f="$1"
  [[ -f "$f" ]] || { echo "?"; return; }
  node -e "
const fs=require('fs');
const raw=fs.readFileSync(process.argv[1],'utf8');
const m=raw.match(/^version:\\s*[\"']?([^\"'\\n]+)[\"']?/m);
console.log(m?m[1].trim():'?');
" "$f" 2>/dev/null || echo "?"
}

required_skills=(
  gatedata-mcp-installer
  gatedata-market-research
  gatedata-prediction-markets
  gatedata-signals-news
  gatedata-fundamentals-earnings
  gatedata-assets-resolve
)

resolve_paths

echo "== GateData Agent Status =="
echo "  Platform: $PLATFORM"
echo ""

echo "Skills ($SKILLS_DIR):"
for s in "${required_skills[@]}"; do
  if [[ -f "$SKILLS_DIR/$s/SKILL.md" ]]; then
    ver=$(skill_version "$SKILLS_DIR/$s/SKILL.md")
    echo "  OK  $s ($ver)"
  else
    echo "  --  $s (missing)"
  fi
done
if [[ -f "$SKILLS_DIR/gatedata-runtime-rules.md" ]]; then
  echo "  OK  gatedata-runtime-rules.md"
else
  echo "  --  gatedata-runtime-rules.md (missing)"
fi

echo ""
if [[ "$PLATFORM" == "codex" ]]; then
  echo "MCP ($MCP_CONFIG):"
  if [[ ! -f "$MCP_CONFIG" ]]; then
    echo "  --  file not found"
  elif grep -qE '^\[mcp_servers\.(GateData|gatedata)' "$MCP_CONFIG" 2>/dev/null; then
    echo "  OK  GateData section found in config.toml"
    grep -E '^\[mcp_servers\.' "$MCP_CONFIG" | sed 's/^/      /' || true
  else
    echo "  --  no GateData MCP server section"
  fi
else
  echo "MCP ($MCP_CONFIG):"
  if [[ ! -f "$MCP_CONFIG" ]]; then
    echo "  --  file not found"
  else
    MCP_JSON="$MCP_CONFIG" node -e "
const fs = require('fs');
const path = process.env.MCP_JSON;
let j;
try { j = JSON.parse(fs.readFileSync(path, 'utf8')); } catch { console.log('  !!  invalid JSON'); process.exit(0); }
let found = false;
for (const [name, v] of Object.entries(j.mcpServers || {})) {
  const u = (v && v.url) || '';
  if (u.includes('gatedata.ai') || /^gatedata/i.test(name) || /^GateData/i.test(name)) {
    found = true;
    const auth = (v.headers && v.headers.Authorization) || '';
    const masked = auth.replace(/Bearer (gd_\\w+)/, (_, k) => 'Bearer ' + k.slice(0, 7) + '...' + k.slice(-4));
    console.log('  OK  ' + name);
    console.log('      url: ' + (v.url || '(stdio)'));
    if (masked) console.log('      auth: ' + masked);
  }
}
if (!found) console.log('  --  no GateData MCP server');
"
  fi
fi

if [[ $LIVE -eq 1 ]]; then
  if [[ -z "$LIVE_KEY" && -f "$MCP_CONFIG" ]]; then
    LIVE_KEY=$(node "$READ_KEY_JS" "$PLATFORM" 2>/dev/null || true)
  fi
  echo ""
  echo "Live probe (api.gatedata.ai):"
  if [[ -z "$LIVE_KEY" ]]; then
    echo "  --  no gd_live_ key (pass --live KEY or configure MCP)"
  else
    HTTP=$(curl -sS -m 10 -o /tmp/gd-status-tools.json -w "%{http_code}" \
      -H "Authorization: Bearer $LIVE_KEY" \
      "https://api.gatedata.ai/api/v1/mcp/tools?live=true&real_data=true" 2>/dev/null || echo "000")
    if [[ "$HTTP" == "200" ]]; then
      COUNT=$(node -e "const j=require('/tmp/gd-status-tools.json');console.log((j.tools||j.data||[]).length)" 2>/dev/null || echo 0)
      echo "  OK  tools API HTTP 200 ($COUNT live tools)"
    else
      echo "  !!  tools API HTTP $HTTP"
    fi
    rm -f /tmp/gd-status-tools.json
  fi
fi

echo ""
echo "Quick fix:"
echo "  bash scripts/sync-skills.sh --platform $PLATFORM"
echo "  bash skills/gatedata-mcp-installer/scripts/install.sh --platform $PLATFORM --api-key gd_live_xxx"

#!/usr/bin/env bash
# GateData MCP unified installer: Cursor / Claude Code / Codex (production only)
#
# Usage:
#   install.sh [--platform cursor|claude|codex]
#            [--mode remote|stdio]       # default: remote
#            [--api-key gd_live_xxx]
#            [--skills-only]             # sync skills only, no MCP changes
#            [--dry-run]                 # preview, no writes
#            [--force-mcp]               # merge MCP even if GateData already configured
#            [--gatedata-bin PATH]       # stdio mode
#            [--no-skills]               # MCP only
#            [-h|--help]
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MERGE_JS="$SCRIPT_DIR/merge-mcp-config.js"
MERGE_CODEX_JS="$SCRIPT_DIR/merge-codex-config.js"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=../../scripts/repo-defaults.sh
if [[ -f "$REPO_ROOT/scripts/repo-defaults.sh" ]]; then
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/repo-defaults.sh"
fi
GATEDATA_AGENT_REPO="${GATEDATA_AGENT_REPO:-${GATEDATA_AGENT_GITHUB_REPO:-https://github.com/gate/gate-data-ai-agent.git}}"
GATEDATA_AGENT_BRANCH="${GATEDATA_AGENT_BRANCH:-main}"

PLATFORM=""
MODE="remote"
API_KEY=""
GATEDATA_BIN=""
INSTALL_SKILLS=1
SKILLS_ONLY=0
DRY_RUN=0
FORCE_MCP=0

usage() {
  cat <<'EOF'
Usage: install.sh [options]

Options:
  --platform cursor|claude|codex   Target client (required if multiple detected)
  --mode remote|stdio              remote = Streamable HTTP (default)
  --api-key KEY                    GateData API key (gd_live_*)
  --skills-only                    Sync skills only; do not change MCP config
  --dry-run                        Preview actions without writing files
  --force-mcp                      Merge MCP even if GateData server already exists
  --gatedata-bin PATH              Path to gatedata binary (stdio mode)
  --no-skills                      MCP config only, skip skills install
  -h, --help                       Show this help

Environment: production only (https://mcp.gatedata.ai/mcp)

API key resolution order:
  1. --api-key
  2. GATEDATA_API_KEY env var
  3. Existing mcp.json GateData server (gd_live_* Bearer)
  4. ~/.gatedata/config.yaml (api_key field)
  5. Interactive prompt (skipped with --skills-only)

Prerequisites:
  - Production API key from https://gatedata.ai (enable_mcp + scopes:
      markets, assets, prediction, signals, fundamentals, earnings as needed;
      fundamentals/earnings also need Pro or Enterprise; signals needs Plus+)
  - Node.js (for JSON merge on Cursor / Claude)
EOF
}

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
    --env)
      echo "Error: --env is no longer supported. This installer only targets production (gatedata.ai)." >&2
      exit 1
      ;;
    --mode)
      shift
      case "${1:-}" in
        remote|stdio) MODE="$1" ;;
        *) echo "Unknown --mode: $1 (remote|stdio)" >&2; exit 1 ;;
      esac
      shift
      ;;
    --api-key)
      shift
      API_KEY="${1:-}"
      shift
      ;;
    --gatedata-bin)
      shift
      GATEDATA_BIN="${1:-}"
      shift
      ;;
    --skills-only) SKILLS_ONLY=1; INSTALL_SKILLS=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force-mcp) FORCE_MCP=1; shift ;;
    --no-skills) INSTALL_SKILLS=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

detect_cursor() {
  if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "win32" ]]; then
    local base="${APPDATA:-$HOME/AppData/Roaming}"
    [[ -d "$base/Cursor" ]]
  else
    [[ -d "${HOME}/.cursor" ]]
  fi
}

detect_claude() {
  [[ -f "${HOME}/.claude.json" ]] || [[ -d "${HOME}/.claude" ]]
}

detect_codex() {
  local h="${CODEX_HOME:-$HOME/.codex}"
  [[ -d "$h" ]]
}

resolve_platform() {
  [[ -n "$PLATFORM" ]] && return 0
  local candidates=()
  detect_cursor && candidates+=("cursor")
  detect_claude && candidates+=("claude")
  detect_codex && candidates+=("codex")

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "Could not detect Cursor, Claude Code, or Codex." >&2
    echo "Install a client or pass --platform cursor|claude|codex" >&2
    exit 1
  fi
  if [[ ${#candidates[@]} -gt 1 ]]; then
    echo "Multiple environments detected: ${candidates[*]}" >&2
    echo "Re-run with: --platform cursor|claude|codex" >&2
    exit 1
  fi
  PLATFORM="${candidates[0]}"
}

read_config_yaml() {
  local cfg="${HOME}/.gatedata/config.yaml"
  [[ -f "$cfg" ]] || return 1
  local line
  line=$(grep -E '^[[:space:]]*api_key:[[:space:]]*' "$cfg" | head -1 || true)
  [[ -n "$line" ]] || return 1
  API_KEY=$(echo "$line" | sed -E 's/^[[:space:]]*api_key:[[:space:]]*//' | tr -d '"' | tr -d "'" | xargs)
  [[ -n "$API_KEY" ]]
}

mcp_json_has_gatedata() {
  local json_path="$1"
  [[ -f "$json_path" ]] || return 1
  command -v node &>/dev/null || return 1
  node -e "
const fs=require('fs');
let j; try { j=JSON.parse(fs.readFileSync(process.argv[1],'utf8')); } catch { process.exit(1); }
for (const [name,v] of Object.entries(j.mcpServers||{})) {
  const u=(v&&v.url)||'';
  if (u.includes('gatedata.ai')||u.includes('mcp.gatedata.ai')||/^gatedata/i.test(name)||/^GateData/i.test(name))
    process.exit(0);
}
process.exit(1);
" "$json_path" 2>/dev/null
}

resolve_api_key() {
  [[ -n "$API_KEY" ]] && return 0
  if [[ -n "${GATEDATA_API_KEY:-}" ]]; then
    API_KEY="$GATEDATA_API_KEY"
    return 0
  fi

  if command -v node &>/dev/null && [[ -n "$PLATFORM" ]]; then
    local key
    key=$(node "$SCRIPT_DIR/read-api-key.js" "$PLATFORM" 2>/dev/null || true)
    if [[ -n "$key" ]]; then
      API_KEY="$key"
      return 0
    fi
  fi

  read_config_yaml && return 0

  if [[ $SKILLS_ONLY -eq 1 ]]; then
    return 0
  fi

  echo ""
  echo "GateData production API key required (Dashboard → API Keys, enable enable_mcp + scopes)."
  echo "  https://gatedata.ai"
  echo ""
  read -r -s -p "  API Key (gd_live_*, input hidden): " API_KEY
  echo ""
  if [[ -z "$API_KEY" ]]; then
    echo "Error: API key is required." >&2
    exit 1
  fi
}

mask_key() {
  local k="$1"
  [[ -z "$k" ]] && { echo "(none)"; return; }
  local len=${#k}
  if [[ $len -le 8 ]]; then
    echo "****"
  else
    echo "${k:0:7}...${k: -4}"
  fi
}

validate_api_key() {
  [[ -z "$API_KEY" ]] && return 0
  if [[ "$API_KEY" != gd_live_* ]]; then
    echo "Warning: production installer expects key starting with gd_live_" >&2
  fi
}

probe_api_key() {
  [[ -z "$API_KEY" ]] || [[ $DRY_RUN -eq 1 ]] && return 0
  command -v curl &>/dev/null || return 0
  local http
  http=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    "https://api.gatedata.ai/api/v1/mcp/tools?live=true" 2>/dev/null || echo "000")
  case "$http" in
    200) echo "  API key probe: OK (tools/list)" ;;
    401) echo "Warning: API key rejected (401). Check key and enable_mcp." >&2 ;;
    403) echo "Warning: API key forbidden (403). Check scopes." >&2 ;;
    *)   echo "Warning: API key probe HTTP $http (continuing)." >&2 ;;
  esac
}

resolve_gatedata_bin() {
  if [[ -n "$GATEDATA_BIN" ]]; then
    [[ -x "$GATEDATA_BIN" ]] || { echo "Error: not executable: $GATEDATA_BIN" >&2; exit 1; }
    return 0
  fi
  if command -v gatedata &>/dev/null; then
    GATEDATA_BIN="$(command -v gatedata)"
    return 0
  fi
  local candidates=(
    "$HOME/.local/bin/gatedata"
    "/usr/local/bin/gatedata"
  )
  for c in "${candidates[@]}"; do
    if [[ -x "$c" ]]; then
      GATEDATA_BIN="$c"
      return 0
    fi
  done
  echo "Error: gatedata binary not found for stdio mode." >&2
  echo "  Install the gatedata CLI, or pass: --gatedata-bin /path/to/gatedata" >&2
  exit 1
}

fragment_name() {
  if [[ "$MODE" == "stdio" ]]; then
    echo "gatedata-stdio.json"
  else
    echo "gatedata-prod.json"
  fi
}

cursor_paths() {
  if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "win32" ]]; then
    CONFIG_JSON="${APPDATA:-$HOME/AppData/Roaming}/Cursor/mcp.json"
    SKILLS_DIR="${APPDATA:-$HOME/AppData/Roaming}/Cursor/skills"
  else
    CONFIG_JSON="${HOME}/.cursor/mcp.json"
    SKILLS_DIR="${HOME}/.cursor/skills"
  fi
}

claude_paths() {
  CONFIG_JSON="${HOME}/.claude.json"
  SKILLS_DIR="${HOME}/.claude/skills"
}

codex_paths() {
  local h="${CODEX_HOME:-$HOME/.codex}"
  CONFIG_TOML="${h}/config.toml"
  SKILLS_DIR="${h}/skills"
}

secure_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  chmod 600 "$f" 2>/dev/null || true
}

backup_config() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  [[ $DRY_RUN -eq 1 ]] && return 0
  local bak="${f}.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$f" "$bak"
  echo "  Backup: $bak"
}

install_skills() {
  local SKILLS_DIR="$1"
  if [[ $INSTALL_SKILLS -eq 0 ]]; then
    echo "Skipped skills installation (--no-skills)."
    return 0
  fi

  echo "Installing GateData agent skills..."
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  [dry-run] would install skills to: $SKILLS_DIR"
    return 0
  fi

  mkdir -p "$SKILLS_DIR"

  local SKILLS_SRC=""
  if [[ -d "$REPO_ROOT/skills/gatedata-mcp-installer" ]]; then
    SKILLS_SRC="$REPO_ROOT/skills"
    echo "  Using local skills from: $SKILLS_SRC"
  else
    if ! command -v git &>/dev/null; then
      echo "git is required to clone skills. Use --no-skills for MCP only." >&2
      exit 1
    fi
    local tmp
    tmp=$(mktemp -d 2>/dev/null || mktemp -d -t gatedata-agent)
    # shellcheck disable=SC2064
    trap "rm -rf \"$tmp\"" RETURN
    git clone --depth 1 -b "$GATEDATA_AGENT_BRANCH" "$GATEDATA_AGENT_REPO" "$tmp"
    SKILLS_SRC="$tmp/skills"
    if [[ ! -d "$SKILLS_SRC" ]]; then
      echo "skills/ not found in cloned repo" >&2
      exit 1
    fi
  fi

  for dir in "$SKILLS_SRC"/*; do
    [[ -d "$dir" ]] || continue
    local name
    name=$(basename "$dir")
    local dst="$SKILLS_DIR/$name"
    [[ -d "$dst" ]] && rm -rf "$dst"
    cp -R "$dir" "$dst"
    echo "  Installed skill: $name"
  done

  if [[ -f "$SKILLS_SRC/gatedata-runtime-rules.md" ]]; then
    cp "$SKILLS_SRC/gatedata-runtime-rules.md" "$SKILLS_DIR/gatedata-runtime-rules.md"
    echo "  Installed: gatedata-runtime-rules.md"
  fi
  if [[ -f "$SKILLS_SRC/gatedata-skills-disambiguation.md" ]]; then
    cp "$SKILLS_SRC/gatedata-skills-disambiguation.md" "$SKILLS_DIR/gatedata-skills-disambiguation.md"
    echo "  Installed: gatedata-skills-disambiguation.md"
  fi
  if [[ -f "$SKILLS_SRC/gatedata-composite-scenarios.md" ]]; then
    cp "$SKILLS_SRC/gatedata-composite-scenarios.md" "$SKILLS_DIR/gatedata-composite-scenarios.md"
    echo "  Installed: gatedata-composite-scenarios.md"
  fi

  echo "Skills installed to: $SKILLS_DIR"
}

install_json_platform() {
  local kind="$1"
  local FRAG_DIR CONFIG_JSON SKILLS_DIR frag

  if [[ "$kind" == "cursor" ]]; then
    cursor_paths
    FRAG_DIR="$SCRIPT_DIR/mcp-fragments/cursor"
  else
    claude_paths
    FRAG_DIR="$SCRIPT_DIR/mcp-fragments/claude"
  fi

  if [[ $SKILLS_ONLY -eq 1 ]]; then
    install_skills "$SKILLS_DIR"
    return 0
  fi

  if [[ $FORCE_MCP -eq 0 ]] && mcp_json_has_gatedata "$CONFIG_JSON"; then
    echo "GateData MCP already configured in $CONFIG_JSON (use --force-mcp to merge GateData entry)."
    install_skills "$SKILLS_DIR"
    return 0
  fi

  frag="$(fragment_name)"
  local frag_path="$FRAG_DIR/$frag"

  local tmp_frag=""
  if [[ "$MODE" == "stdio" ]]; then
    resolve_gatedata_bin
    tmp_frag=$(mktemp)
    sed "s|__GATEDATA_BIN__|$GATEDATA_BIN|g" "$frag_path" > "$tmp_frag"
    frag_path="$tmp_frag"
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would merge MCP into: $CONFIG_JSON"
    echo "[dry-run] fragment: $frag_path"
    echo "[dry-run] API key: $(mask_key "$API_KEY")"
    [[ -n "$tmp_frag" ]] && rm -f "$tmp_frag"
    install_skills "$SKILLS_DIR"
    return 0
  fi

  if ! command -v node &>/dev/null; then
    echo "Node.js not found. Install Node or merge manually into $CONFIG_JSON:" >&2
    sed "s/__REPLACE_ME__/$(mask_key "$API_KEY")/g" "$frag_path" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$CONFIG_JSON")"
  backup_config "$CONFIG_JSON"

  local tmp_json
  tmp_json=$(mktemp)
  if [[ -f "$CONFIG_JSON" ]]; then
    cp "$CONFIG_JSON" "$tmp_json"
  else
    echo "{}" > "$tmp_json"
  fi

  export GATEDATA_API_KEY="$API_KEY"
  node "$MERGE_JS" "$tmp_json" "$CONFIG_JSON" "$frag_path"
  unset GATEDATA_API_KEY
  rm -f "$tmp_json"
  [[ -n "$tmp_frag" ]] && rm -f "$tmp_frag"

  secure_file "$CONFIG_JSON"
  echo "MCP config written to: $CONFIG_JSON"
  install_skills "$SKILLS_DIR"
}

codex_has_gatedata() {
  local toml="$1"
  [[ -f "$toml" ]] || return 1
  grep -qE '^\[mcp_servers\.[^]]*[Gg]ate[Dd]ata' "$toml" 2>/dev/null
}

install_codex_platform() {
  codex_paths
  local FRAG_DIR="$SCRIPT_DIR/mcp-fragments/codex"
  local frag_file="$FRAG_DIR/gatedata-prod.toml"

  if [[ $SKILLS_ONLY -eq 1 ]]; then
    install_skills "$SKILLS_DIR"
    return 0
  fi

  if [[ "$MODE" == "stdio" ]]; then
    echo "Error: Codex stdio mode not supported. Use --mode remote." >&2
    exit 1
  fi

  if [[ $FORCE_MCP -eq 0 ]] && codex_has_gatedata "$CONFIG_TOML"; then
    echo "GateData MCP already configured in $CONFIG_TOML (use --force-mcp to update GateData entry)."
    install_skills "$SKILLS_DIR"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would merge GateData into: $CONFIG_TOML"
    echo "[dry-run] API key: $(mask_key "$API_KEY")"
    install_skills "$SKILLS_DIR"
    return 0
  fi

  if ! command -v node &>/dev/null; then
    echo "Node.js required for Codex MCP merge. Append manually to $CONFIG_TOML:" >&2
    sed "s/__REPLACE_ME__/$(mask_key "$API_KEY")/g" "$frag_file" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$CONFIG_TOML")"
  touch "$CONFIG_TOML"
  backup_config "$CONFIG_TOML"

  export GATEDATA_API_KEY="$API_KEY"
  node "$MERGE_CODEX_JS" "$CONFIG_TOML" "$frag_file"
  unset GATEDATA_API_KEY

  secure_file "$CONFIG_TOML"
  echo "MCP config written to: $CONFIG_TOML"
  install_skills "$SKILLS_DIR"
}

print_next_steps() {
  echo ""
  echo "========================================"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo " GateData install preview (dry-run)"
  elif [[ $SKILLS_ONLY -eq 1 ]]; then
    echo " GateData skills sync complete"
  else
    echo " GateData MCP install complete"
  fi
  echo "========================================"
  echo "  Platform:    $PLATFORM"
  echo "  Environment: prod"
  echo "  Mode:        $MODE"
  if [[ $SKILLS_ONLY -eq 0 ]]; then
    echo "  MCP server:  GateData (or existing GateData.*)"
    echo "  API key:     $(mask_key "$API_KEY")"
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo ""
    echo "Re-run without --dry-run to apply."
    return
  fi
  echo ""
  echo "Next steps:"
  echo "  1. Restart $PLATFORM to load changes"
  if [[ $SKILLS_ONLY -eq 0 ]]; then
    echo "  2. Verify MCP tools (market_data_query, prediction_markets_query, events_news_query, fundamentals_query, estimates_earnings_query, assets_resolve)"
  fi
  echo "  3. bash scripts/status.sh --platform $PLATFORM --live"
  echo "  4. Docs: https://gatedata.ai/docs (EN) | https://gatedata.ai/zh-hans/docs (ZH)"
}

main() {
  resolve_platform
  resolve_api_key
  validate_api_key

  echo "GateData MCP installer (production)"
  echo "  Platform: $PLATFORM | Mode: $MODE | Skills-only: $SKILLS_ONLY | Dry-run: $DRY_RUN"
  if [[ $SKILLS_ONLY -eq 0 && -n "$API_KEY" ]]; then
    probe_api_key
  fi

  case "$PLATFORM" in
    cursor) install_json_platform cursor ;;
    claude) install_json_platform claude ;;
    codex)  install_codex_platform ;;
    *) echo "Unsupported platform: $PLATFORM" >&2; exit 1 ;;
  esac

  print_next_steps
}

main

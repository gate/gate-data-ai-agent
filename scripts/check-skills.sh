#!/usr/bin/env bash
# Compare installed GateData skills vs this repository (no writes).
#
# Usage:
#   bash scripts/check-skills.sh [--platform cursor|claude|codex]
#
# Exit 0 when all required skills match repo versions; exit 1 if outdated/missing.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLATFORM="cursor"
NEEDS_SYNC=0

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
    -h|--help)
      echo "Usage: check-skills.sh [--platform cursor|claude|codex]"
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

resolve_skills_dir() {
  case "$PLATFORM" in
    cursor)
      if [[ "${OSTYPE:-}" == "msys" || "${OSTYPE:-}" == "win32" ]]; then
        SKILLS_DIR="${APPDATA:-$HOME/AppData/Roaming}/Cursor/skills"
      else
        SKILLS_DIR="${HOME}/.cursor/skills"
      fi
      ;;
    claude) SKILLS_DIR="${HOME}/.claude/skills" ;;
    codex)  SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills" ;;
  esac
}

skill_version() {
  local f="$1"
  [[ -f "$f" ]] || { echo ""; return; }
  node -e "
const fs=require('fs');
const raw=fs.readFileSync(process.argv[1],'utf8');
const m=raw.match(/^version:\\s*[\"']?([^\"'\\n]+)[\"']?/m);
console.log(m?m[1].trim():'');
" "$f" 2>/dev/null || echo ""
}

required_skills=(
  gatedata-mcp-installer
  gatedata-market-research
  gatedata-prediction-markets
  gatedata-signals-news
  gatedata-fundamentals-earnings
  gatedata-assets-resolve
)

resolve_skills_dir

echo "== GateData Skills Check =="
echo "  Platform:  $PLATFORM"
echo "  Repo:      $REPO_ROOT/skills"
echo "  Installed: $SKILLS_DIR"
echo ""

for s in "${required_skills[@]}"; do
  repo_file="$REPO_ROOT/skills/$s/SKILL.md"
  inst_file="$SKILLS_DIR/$s/SKILL.md"
  repo_ver=$(skill_version "$repo_file")
  inst_ver=$(skill_version "$inst_file")

  if [[ ! -f "$inst_file" ]]; then
    echo "  !!  $s — missing (repo: $repo_ver)"
    NEEDS_SYNC=1
  elif [[ -z "$repo_ver" ]]; then
    echo "  ??  $s — installed $inst_ver (repo version unknown)"
  elif [[ "$repo_ver" == "$inst_ver" ]]; then
    echo "  OK  $s ($inst_ver)"
  else
    echo "  !!  $s — installed $inst_ver, repo $repo_ver"
    NEEDS_SYNC=1
  fi
done

for extra in gatedata-runtime-rules.md gatedata-skills-disambiguation.md gatedata-composite-scenarios.md; do
  repo_file="$REPO_ROOT/skills/$extra"
  inst_file="$SKILLS_DIR/$extra"
  if [[ ! -f "$repo_file" ]]; then
    continue
  fi
  if [[ -f "$inst_file" ]]; then
    echo "  OK  $extra"
  else
    echo "  !!  $extra — missing"
    NEEDS_SYNC=1
  fi
done

echo ""
if [[ $NEEDS_SYNC -eq 1 ]]; then
  echo "Run: bash scripts/sync-skills.sh --platform $PLATFORM"
  exit 1
fi
echo "All skills up to date."

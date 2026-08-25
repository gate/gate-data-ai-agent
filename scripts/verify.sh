#!/usr/bin/env bash
# Verify gate-data-ai-agent installer and skills (CI / local).
#
# Usage:
#   bash scripts/verify.sh                    # static checks
#   bash scripts/verify.sh --live KEY         # optional: probe production MCP tools API
#   bash scripts/verify.sh --live-cli         # optional: run verify-cli.sh (needs local binary + key)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$REPO_ROOT/skills/gatedata-mcp-installer/scripts"
LIVE_KEY=""
LIVE_CLI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --live)
      shift
      LIVE_KEY="${1:-}"
      shift
      ;;
    --live-cli)
      LIVE_CLI=1
      shift
      ;;
    -h|--help)
      echo "Usage: verify.sh [--live gd_live_xxx] [--live-cli]"
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
done

echo "== Static checks =="

bash -n "$INSTALLER/install.sh"
echo "  OK install.sh syntax"

node --check "$INSTALLER/merge-mcp-config.js"
echo "  OK merge-mcp-config.js"

required_skills=(
  gatedata-mcp-installer
  gatedata-market-research
  gatedata-prediction-markets
  gatedata-signals-news
  gatedata-fundamentals-earnings
  gatedata-assets-resolve
)

for s in "${required_skills[@]}"; do
  f="$REPO_ROOT/skills/$s/SKILL.md"
  [[ -f "$f" ]] || { echo "MISSING $f" >&2; exit 1; }
  echo "  OK skills/$s/SKILL.md"
done

[[ -f "$REPO_ROOT/skills/gatedata-runtime-rules.md" ]] || { echo "MISSING runtime rules" >&2; exit 1; }
echo "  OK gatedata-runtime-rules.md"

[[ -f "$REPO_ROOT/skills/gatedata-composite-scenarios.md" ]] || { echo "MISSING composite scenarios" >&2; exit 1; }
echo "  OK gatedata-composite-scenarios.md"

[[ -f "$REPO_ROOT/skills/gatedata-skills-disambiguation.md" ]] || { echo "MISSING disambiguation" >&2; exit 1; }
echo "  OK gatedata-skills-disambiguation.md"

bash -n "$REPO_ROOT/scripts/bootstrap.sh"
bash -n "$REPO_ROOT/scripts/check-skills.sh"
bash -n "$REPO_ROOT/scripts/sync-skills.sh"
bash -n "$REPO_ROOT/scripts/status.sh"
bash -n "$REPO_ROOT/scripts/verify-cli.sh"

echo "  OK helper scripts syntax"

node --check "$INSTALLER/read-api-key.js"
echo "  OK read-api-key.js"

node --check "$INSTALLER/merge-codex-config.js"
echo "  OK merge-codex-config.js"

bash -n "$REPO_ROOT/scripts/check-remote.sh"
echo "  OK check-remote.sh syntax"

fragments=(
  cursor/gatedata-prod.json
  cursor/gatedata-stdio.json
  claude/gatedata-prod.json
  claude/gatedata-stdio.json
  codex/gatedata-prod.toml
)

for f in "${fragments[@]}"; do
  p="$INSTALLER/mcp-fragments/$f"
  [[ -f "$p" ]] || { echo "MISSING fragment $p" >&2; exit 1; }
  echo "  OK mcp-fragments/$f"
done

TMP=$(mktemp)
echo '{"mcpServers":{"Other":{"url":"http://example.com"}}}' > "$TMP"
OUT="${TMP}.out"
GATEDATA_API_KEY=gd_live_verify_test node "$INSTALLER/merge-mcp-config.js" \
  "$TMP" "$OUT" "$INSTALLER/mcp-fragments/cursor/gatedata-prod.json"

grep -q '"GateData"' "$OUT" || { echo "merge failed: no GateData key" >&2; exit 1; }
grep -q 'gd_live_verify_test' "$OUT" || { echo "merge failed: key not substituted" >&2; exit 1; }
grep -q '"Other"' "$OUT" || { echo "merge failed: removed existing server" >&2; exit 1; }
rm -f "$TMP" "$OUT"
echo "  OK merge-mcp-config non-destructive + key substitution"

TMP=$(mktemp)
echo '{"mcpServers":{"GateData.AI":{"url":"https://mcp.gatedata.ai/mcp","headers":{"Authorization":"Bearer old_key"}}}}' > "$TMP"
OUT="${TMP}.out"
GATEDATA_API_KEY=gd_live_update_test node "$INSTALLER/merge-mcp-config.js" \
  "$TMP" "$OUT" "$INSTALLER/mcp-fragments/cursor/gatedata-prod.json"
grep -q '"GateData.AI"' "$OUT" || { echo "merge failed: lost existing server key" >&2; exit 1; }
grep -q 'gd_live_update_test' "$OUT" || { echo "merge failed: in-place key not updated" >&2; exit 1; }
grep -q 'old_key' "$OUT" && { echo "merge failed: stale key remains" >&2; exit 1; }
rm -f "$TMP" "$OUT"
echo "  OK merge-mcp-config updates existing GateData server in-place"

TMP=$(mktemp)
echo '{"mcpServers":{}}' > "$TMP"
OUT="${TMP}.out"
GATEDATA_API_KEY=gd_live_stdio_test node "$INSTALLER/merge-mcp-config.js" \
  "$TMP" "$OUT" "$INSTALLER/mcp-fragments/claude/gatedata-stdio.json"
grep -q 'gd_live_stdio_test' "$OUT" || { echo "merge failed: stdio env key not substituted" >&2; exit 1; }
rm -f "$TMP" "$OUT"
echo "  OK merge-mcp-config stdio env key substitution"

TMP=$(mktemp)
OUT="${TMP}.toml"
GATEDATA_API_KEY=gd_live_codex_test node "$INSTALLER/merge-codex-config.js" \
  "$OUT" "$INSTALLER/mcp-fragments/codex/gatedata-prod.toml"
grep -q 'gd_live_codex_test' "$OUT" || { echo "merge-codex failed: key not substituted" >&2; exit 1; }
GATEDATA_API_KEY=gd_live_codex_new node "$INSTALLER/merge-codex-config.js" \
  "$OUT" "$INSTALLER/mcp-fragments/codex/gatedata-prod.toml"
grep -q 'gd_live_codex_new' "$OUT" || { echo "merge-codex failed: in-place update" >&2; exit 1; }
grep -q 'gd_live_codex_test' "$OUT" && { echo "merge-codex failed: stale key remains" >&2; exit 1; }
rm -f "$OUT"
echo "  OK merge-codex-config append + in-place key update"

user_docs=(
  en/getting-started.md
  en/install.md
  en/distribution.md
  zh-hans/getting-started.md
  zh-hans/install.md
  zh-hans/distribution.md
)

for f in "${user_docs[@]}"; do
  p="$REPO_ROOT/docs/$f"
  [[ -f "$p" ]] || { echo "MISSING docs/$f" >&2; exit 1; }
  echo "  OK docs/$f"
done

grep -q 'protocol compatibility\|backward compatible\|协议兼容' "$REPO_ROOT/docs/en/install.md" \
  || { echo "FAIL: docs/en/install.md missing MCP compatibility note" >&2; exit 1; }
grep -q '协议兼容\|向后兼容' "$REPO_ROOT/docs/zh-hans/install.md" \
  || { echo "FAIL: docs/zh-hans/install.md missing MCP compatibility note" >&2; exit 1; }
grep -q 'Protocol compatibility\|protocol compatibility\|backward compatible' \
  "$REPO_ROOT/skills/gatedata-mcp-installer/references/mcp.md" \
  || { echo "FAIL: installer mcp.md missing protocol compatibility note" >&2; exit 1; }
# Public docs must not ship internal protocol-engineering jargon
# (needles built in parts so this file does not match itself)
_j1=$(printf '%s-%s' 'Dual' 'Stack')
_j2=$(printf '%s-%s' 'ADR' '009')
_j3=$(printf '%s-%s' 'mcp' 'go')
_j4=$(printf '%s %s' 'sticky' 'session')
_j5=$(printf '%s_%s' 'write' 'timeout')
_internal_proto=$(
  grep -RIn --exclude-dir=.git --exclude-dir=node_modules --exclude='verify.sh' \
    -E "${_j1}|${_j2}|${_j3}|${_j4}|${_j5}" \
    "$REPO_ROOT/docs" "$REPO_ROOT/skills" "$REPO_ROOT/CHANGELOG.md" 2>/dev/null || true
)
if [[ -n "$_internal_proto" ]]; then
  echo "FAIL: internal MCP engineering terms found in public-facing docs:" >&2
  echo "$_internal_proto" >&2
  exit 1
fi
unset _j1 _j2 _j3 _j4 _j5 _internal_proto
echo "  OK MCP protocol compatibility docs (no internal jargon)"

[[ -f "$REPO_ROOT/docs/README.md" ]] || { echo "MISSING docs/README.md" >&2; exit 1; }
echo "  OK docs/README.md"

[[ -f "$REPO_ROOT/scripts/README.md" ]] || { echo "MISSING scripts/README.md" >&2; exit 1; }
echo "  OK scripts/README.md"

[[ -f "$REPO_ROOT/scripts/verify-cli.sh" ]] || { echo "MISSING scripts/verify-cli.sh" >&2; exit 1; }
echo "  OK scripts/verify-cli.sh"

if grep -q 'docs\.gatedata\.ai' "$REPO_ROOT/README.md" "$REPO_ROOT/docs/README.md" 2>/dev/null; then
  echo "FAIL: stale docs.gatedata.ai URL in README" >&2
  exit 1
fi
echo "  OK product doc URLs (no docs.gatedata.ai)"

# Public release must not ship private/intranet hostnames
# (needles built in parts so this file does not match itself)
_leak_a=$(printf '%s.%s' 'fulltrust' 'link')
_leak_b=$(printf '%s-%s/' 'gateai' 'data')
LEAK_HITS=$(
  grep -RIn --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=internal \
    --exclude='verify.sh' \
    -E "${_leak_a}|${_leak_b}" "$REPO_ROOT" 2>/dev/null || true
)
if [[ -n "$LEAK_HITS" ]]; then
  echo "FAIL: private/intranet references found:" >&2
  echo "$LEAK_HITS" >&2
  exit 1
fi
echo "  OK no private/intranet hostnames"
unset _leak_a _leak_b

# Fundamentals/earnings must not claim scope=assets as the required auth scope
if grep -nE 'Scope required:\s*`assets`|enable_mcp and `assets` scope' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/references/troubleshooting.md" 2>/dev/null; then
  echo "FAIL: fundamentals-earnings still documents scope=assets (need fundamentals + earnings)" >&2
  exit 1
fi
grep -q '`fundamentals`' "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals-earnings SKILL.md missing fundamentals scope" >&2; exit 1; }
grep -q '`earnings`' "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals-earnings SKILL.md missing earnings scope" >&2; exit 1; }
echo "  OK fundamentals/earnings scopes"

# Public README must not advertise private-only scripts
if grep -n 'one-click-test' "$REPO_ROOT/README.md" "$REPO_ROOT/README_zh.md" 2>/dev/null; then
  echo "FAIL: README advertises one-click-test (public sync excludes it)" >&2
  exit 1
fi
echo "  OK README does not advertise private one-click-test"

# Market skill: first-class tasks + thin anomaly/move
if grep -nE 'summary\` \(crypto CEX derivatives\)|liquidation heatmap\. Triggers' \
  "$REPO_ROOT/skills/gatedata-market-research/SKILL.md" 2>/dev/null; then
  echo "FAIL: market skill still over-promises bare summary / heatmap in description" >&2
  exit 1
fi
grep -q 'task: orderbook\|task: technical_indicators\|thin snapshot' \
  "$REPO_ROOT/skills/gatedata-market-research/SKILL.md" \
  || { echo "FAIL: market skill missing first-class orderbook/technical_indicators / thin-snapshot guidance" >&2; exit 1; }
grep -q 'technical_indicators' "$REPO_ROOT/skills/gatedata-market-research/SKILL.md" \
  || { echo "FAIL: market skill missing technical_indicators" >&2; exit 1; }
echo "  OK market skill first-class tasks"

# Flat skill docs must use ./ for sibling links (install layout under ~/.cursor/skills/)
if grep -nE '\]\(\.\./gatedata-(skills-disambiguation|composite-scenarios)' \
  "$REPO_ROOT/skills/gatedata-runtime-rules.md" 2>/dev/null; then
  echo "FAIL: runtime-rules uses ../ for flat sibling docs (need ./)" >&2
  exit 1
fi
if grep -nE '\]\(\.\./gatedata-' "$REPO_ROOT/skills/README.md" 2>/dev/null; then
  echo "FAIL: skills/README.md uses ../ links (need ./)" >&2
  exit 1
fi
if grep -nE '\]\(\.\./gatedata-mcp-installer' \
  "$REPO_ROOT/skills/gatedata-market-research/references/troubleshooting.md" 2>/dev/null; then
  echo "FAIL: market troubleshooting installer link needs ../../" >&2
  exit 1
fi
echo "  OK relative skill doc links"

# Earnings public tasks: only auto/calendar/results/consensus; reject transcript/guidance/ratings/summary
grep -q 'Do not use `task: auto` when the user asks for company guidance' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals skill missing guidance/transcript intent warning" >&2; exit 1; }
grep -q 'estimate_metric: guidance` ≠ `task: guidance`' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals skill missing estimate_metric vs task:guidance note" >&2; exit 1; }
grep -qE '`auto` \| `calendar` \| `results` \| `consensus`' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals skill missing earnings public-task enum" >&2; exit 1; }
if grep -nE 'public tasks only:.*transcript|public tasks only:.*guidance' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" 2>/dev/null; then
  echo "FAIL: earnings still lists transcript/guidance as public" >&2
  exit 1
fi
grep -qE '`ratings`, `summary`, `transcript`, `guidance`' \
  "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals skill must reject ratings/summary/transcript/guidance" >&2; exit 1; }
grep -q 'tokenomics' "$REPO_ROOT/skills/gatedata-fundamentals-earnings/SKILL.md" \
  || { echo "FAIL: fundamentals skill missing live tokenomics" >&2; exit 1; }
echo "  OK earnings public enum / rejects / tokenomics"

# Signals phase-1 + YouTube extras
grep -q 'content_search' "$REPO_ROOT/skills/gatedata-signals-news/SKILL.md" \
  || { echo "FAIL: signals skill missing content_search" >&2; exit 1; }
grep -q 'has_object_refs' "$REPO_ROOT/skills/gatedata-signals-news/SKILL.md" \
  || { echo "FAIL: signals skill missing has_object_refs" >&2; exit 1; }
grep -q 'source_published_at' "$REPO_ROOT/skills/gatedata-signals-news/SKILL.md" \
  || { echo "FAIL: signals skill missing source_published_at time-axis note" >&2; exit 1; }
if grep -nE '"task": "(news|events|ugc|insight|announcements|ratings|event_detail|auto)"' \
  "$REPO_ROOT/skills/gatedata-signals-news/references/scenarios.md" 2>/dev/null; then
  echo "FAIL: signals scenarios still use rejected tasks" >&2
  exit 1
fi
echo "  OK signals phase-1 tasks"

# Assets must not teach universe as callable
if grep -nE '`task: universe`|Universe / coverage probe \| `task: universe`' \
  "$REPO_ROOT/skills/gatedata-assets-resolve/SKILL.md" 2>/dev/null \
  | grep -v 'Do not call\|no `universe`\|hard reject' >/dev/null; then
  echo "FAIL: assets skill still teaches universe as callable" >&2
  exit 1
fi
grep -q 'universe' "$REPO_ROOT/skills/gatedata-assets-resolve/SKILL.md" \
  && grep -qiE 'Do not call|hard reject|out of' "$REPO_ROOT/skills/gatedata-assets-resolve/SKILL.md" \
  || { echo "FAIL: assets skill must reject universe" >&2; exit 1; }
echo "  OK assets universe rejected"

# Signals troubleshooting must not recommend market task: move as causal fallback
if grep -nE 'market skill `task: move`|or market skill' \
  "$REPO_ROOT/skills/gatedata-signals-news/references/troubleshooting.md" 2>/dev/null; then
  echo "FAIL: signals troubleshooting still recommends market task: move" >&2
  exit 1
fi
echo "  OK signals troubleshooting move fallback"

# Non-distribution paths must not appear in this tree
for p in \
  scripts/one-click-test.sh \
  scripts/sync-public.sh \
  scripts/publish.sh \
  scripts/PUBLIC_SYNC_EXCLUDE \
  docs/internal \
  .gitlab-ci.yml
do
  if [[ -e "$REPO_ROOT/$p" ]]; then
    echo "FAIL: non-distribution path present: $p" >&2
    exit 1
  fi
done
echo "  OK no non-distribution paths"

if [[ -n "$LIVE_KEY" ]]; then
  echo ""
  echo "== Live probe =="
  URL="https://api.gatedata.ai/api/v1/mcp/tools?live=true&real_data=true"
  HTTP=$(curl -sS -o /tmp/gatedata-tools.json -w "%{http_code}" \
    -H "Authorization: Bearer $LIVE_KEY" "$URL" || true)
  if [[ "$HTTP" != "200" ]]; then
    echo "  FAIL tools API HTTP $HTTP" >&2
    exit 1
  fi
  node -e '
const j=require("/tmp/gatedata-tools.json");
const tools=(j.tools||j.data||[]).map(t=>t.name||t.tool).filter(Boolean);
const want=["assets_resolve","market_data_query","prediction_markets_query","events_news_query","fundamentals_query","estimates_earnings_query"];
const missing=want.filter(n=>!tools.includes(n));
if(missing.length){console.error("FAIL missing tools:",missing.join(","),"got",tools.join(",")); process.exit(1);}
console.log("  OK tools API returned 6 domain tools (count="+tools.length+")");
' || exit 1
  rm -f /tmp/gatedata-tools.json
fi

if [[ $LIVE_CLI -eq 1 ]]; then
  echo ""
  echo "== Live CLI probe =="
  bash "$REPO_ROOT/scripts/verify-cli.sh" --platform cursor
fi

echo ""
echo "All checks passed."

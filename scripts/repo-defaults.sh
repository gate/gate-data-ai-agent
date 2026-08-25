# GateData Agent — repository URL defaults
# Source this file or read in shell scripts.
#
# Public distribution: GitHub. Override with GATEDATA_AGENT_REPO if needed.

GATEDATA_AGENT_GITHUB_REPO="${GATEDATA_AGENT_GITHUB_REPO:-https://github.com/gate/gate-data-ai-agent.git}"
GATEDATA_AGENT_GITHUB_RAW="${GATEDATA_AGENT_GITHUB_RAW:-https://raw.githubusercontent.com/gate/gate-data-ai-agent/main}"
GATEDATA_AGENT_GITHUB_WEB="${GATEDATA_AGENT_GITHUB_WEB:-https://github.com/gate/gate-data-ai-agent}"

# Default clone URL for install.sh / bootstrap.sh / sync-skills
GATEDATA_AGENT_REPO="${GATEDATA_AGENT_REPO:-$GATEDATA_AGENT_GITHUB_REPO}"

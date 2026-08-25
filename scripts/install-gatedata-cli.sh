#!/usr/bin/env bash
# Download gatedata CLI binary for stdio MCP (optional).
#
# Prefer remote MCP for most users:
#   bash skills/gatedata-mcp-installer/scripts/install.sh --mode remote
#
# Usage (when you have a published binary URL base):
#   GATEDATA_CLI_RELEASE_BASE=https://example.com/releases \
#   GATEDATA_CLI_VERSION=v0.1.0 \
#   bash scripts/install-gatedata-cli.sh
#
set -euo pipefail

VERSION="${GATEDATA_CLI_VERSION:-}"
INSTALL_DIR="${GATEDATA_CLI_INSTALL_DIR:-$HOME/.local/bin}"
RELEASE_BASE="${GATEDATA_CLI_RELEASE_BASE:-}"

os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) echo "Unsupported arch: $arch" >&2; exit 1 ;;
esac
case "$os" in
  darwin) os=darwin ;;
  linux) os=linux ;;
  *) echo "Unsupported OS: $os" >&2; exit 1 ;;
esac

if [[ -z "$VERSION" || -z "$RELEASE_BASE" ]]; then
  cat >&2 <<'EOF'
Error: CLI binary download is not configured for this release.

Recommended: use remote MCP (no local binary required):
  bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor --mode remote

For stdio mode, provide your own binary:
  bash skills/gatedata-mcp-installer/scripts/install.sh --mode stdio --gatedata-bin /path/to/gatedata

To download a published asset, set both:
  GATEDATA_CLI_RELEASE_BASE   # e.g. https://example.com/releases
  GATEDATA_CLI_VERSION        # e.g. v0.1.0
EOF
  exit 1
fi

ASSET="gatedata_${VERSION}_${os}_${arch}"
URL="${RELEASE_BASE%/}/${ASSET}"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

echo "Downloading $URL ..."
curl -fsSL "$URL" -o "$TMP"
mkdir -p "$INSTALL_DIR"
install -m 755 "$TMP" "$INSTALL_DIR/gatedata"
echo "Installed: $INSTALL_DIR/gatedata"
echo "Run: $INSTALL_DIR/gatedata mcp-bridge"

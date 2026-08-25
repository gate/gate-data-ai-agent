#!/usr/bin/env node
/**
 * Read production GateData API key (gd_live_*) from client MCP config.
 * Usage: node read-api-key.js [cursor|claude|codex]
 * Exit 0 and print key on stdout, or exit 1 if not found.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

const platform = process.argv[2] || 'cursor';

function fromMcpJson(filePath) {
  let j;
  try {
    j = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
  for (const v of Object.values(j.mcpServers || {})) {
    const auth = v.headers && v.headers.Authorization;
    if (auth && auth.startsWith('Bearer gd_live_')) {
      return auth.replace(/^Bearer\s+/, '');
    }
    const ek = v.env && v.env.GATEDATA_API_KEY;
    if (ek && ek.startsWith('gd_live_')) {
      return ek;
    }
  }
  return null;
}

function fromCodexToml(filePath) {
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
  const m = content.match(/Bearer (gd_live_[^"\s]+)/);
  return m ? m[1] : null;
}

function fromConfigYaml() {
  const cfg = path.join(os.homedir(), '.gatedata', 'config.yaml');
  let content;
  try {
    content = fs.readFileSync(cfg, 'utf8');
  } catch {
    return null;
  }
  const m = content.match(/^[ \t]*api_key:[ \t]*["']?([^\s"']+)/m);
  const key = m && m[1];
  return key && key.startsWith('gd_live_') ? key : null;
}

function cursorMcpPath() {
  if (process.platform === 'win32') {
    const appData = process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming');
    return path.join(appData, 'Cursor', 'mcp.json');
  }
  return path.join(os.homedir(), '.cursor', 'mcp.json');
}

function resolvePath() {
  switch (platform) {
    case 'cursor':
      return { type: 'json', path: cursorMcpPath() };
    case 'claude':
      return { type: 'json', path: path.join(os.homedir(), '.claude.json') };
    case 'codex': {
      const home = process.env.CODEX_HOME || path.join(os.homedir(), '.codex');
      return { type: 'toml', path: path.join(home, 'config.toml') };
    }
    default:
      return null;
  }
}

const target = resolvePath();
let key = null;

if (target) {
  key = target.type === 'toml'
    ? fromCodexToml(target.path)
    : fromMcpJson(target.path);
}

if (!key) {
  key = fromConfigYaml();
}

if (key) {
  console.log(key);
  process.exit(0);
}
process.exit(1);

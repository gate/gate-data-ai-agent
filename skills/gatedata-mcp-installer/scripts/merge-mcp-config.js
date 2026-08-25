#!/usr/bin/env node
/**
 * Merge MCP server fragments into existing mcp.json (non-destructive).
 * Usage: node merge-mcp-config.js <existingJsonPath> <outPath> <fragment.json> [...]
 *
 * If env GATEDATA_API_KEY is set, substitutes API key into:
 *   - headers.Authorization (Bearer ...)
 *   - env.GATEDATA_API_KEY (stdio bridge)
 *
 * If an existing GateData server is found (URL or name), updates it in-place
 * instead of adding a duplicate "GateData" entry.
 */
const fs = require('fs');

function readExisting(path) {
  try {
    const raw = fs.readFileSync(path, 'utf8');
    if (!raw.trim()) return {};
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function applyApiKey(server, apiKey) {
  if (!apiKey || !server || typeof server !== 'object') return;
  if (server.headers && typeof server.headers.Authorization === 'string') {
    if (server.headers.Authorization.includes('__REPLACE_ME__')) {
      server.headers.Authorization = `Bearer ${apiKey}`;
    } else if (server.headers.Authorization.startsWith('Bearer ')) {
      server.headers.Authorization = `Bearer ${apiKey}`;
    }
  }
  if (server.env && typeof server.env.GATEDATA_API_KEY === 'string') {
    server.env.GATEDATA_API_KEY = apiKey;
  }
}

function findGatedataServerKey(servers) {
  if (!servers || typeof servers !== 'object') return null;
  for (const [name, v] of Object.entries(servers)) {
    const u = (v && v.url) || '';
    if (u.includes('gatedata.ai') || /^gatedata/i.test(name)) {
      return name;
    }
  }
  return null;
}

function cloneServer(server) {
  return JSON.parse(JSON.stringify(server));
}

const existingPath = process.argv[2];
const outPath = process.argv[3];
const fragmentPaths = process.argv.slice(4).filter(Boolean);

if (!existingPath || !outPath) {
  console.error('Usage: node merge-mcp-config.js <existingJsonPath> <outPath> <fragment.json> [...]');
  process.exit(1);
}

const add = {};
for (const p of fragmentPaths) {
  let raw;
  try {
    raw = fs.readFileSync(p, 'utf8');
  } catch {
    console.error(`merge-mcp-config: cannot read fragment: ${p}`);
    process.exit(1);
  }
  let j;
  try {
    j = JSON.parse(raw);
  } catch {
    console.error(`merge-mcp-config: invalid JSON in fragment: ${p}`);
    process.exit(1);
  }
  Object.assign(add, j);
}

const apiKey = process.env.GATEDATA_API_KEY || '';
for (const name of Object.keys(add)) {
  applyApiKey(add[name], apiKey);
}

const existing = readExisting(existingPath);
existing.mcpServers = existing.mcpServers || {};

const fragmentEntries = Object.entries(add);
const existingKey = findGatedataServerKey(existing.mcpServers);

if (existingKey && fragmentEntries.length > 0) {
  const [, fragmentServer] = fragmentEntries[0];
  existing.mcpServers[existingKey] = cloneServer(fragmentServer);
} else {
  Object.assign(existing.mcpServers, add);
}

fs.writeFileSync(outPath, JSON.stringify(existing, null, 2) + '\n');

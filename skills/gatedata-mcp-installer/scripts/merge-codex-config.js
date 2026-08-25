#!/usr/bin/env node
/**
 * Merge GateData MCP fragment into Codex config.toml.
 * Usage: GATEDATA_API_KEY=... node merge-codex-config.js <config.toml> <fragment.toml>
 *
 * Updates existing [mcp_servers.*GateData*] section in-place, or appends fragment.
 */
const fs = require('fs');

const configPath = process.argv[2];
const fragmentPath = process.argv[3];
const apiKey = process.env.GATEDATA_API_KEY || '';

if (!configPath || !fragmentPath) {
  console.error('Usage: GATEDATA_API_KEY=... node merge-codex-config.js <config.toml> <fragment.toml>');
  process.exit(1);
}

let content = '';
try {
  content = fs.readFileSync(configPath, 'utf8');
} catch {
  content = '';
}

let fragment = fs.readFileSync(fragmentPath, 'utf8').replace(/__REPLACE_ME__/g, apiKey);

function findGatedataSection(lines) {
  let current = null;
  let start = -1;
  for (let i = 0; i < lines.length; i++) {
    const m = lines[i].match(/^\[mcp_servers\.([^\]]+)\]/);
    if (m) {
      if (current && /gatedata/i.test(current)) {
        return { name: current, start, end: i };
      }
      current = m[1];
      start = i;
    }
  }
  if (current && /gatedata/i.test(current)) {
    return { name: current, start, end: lines.length };
  }
  return null;
}

const lines = content.split('\n');
const existing = findGatedataSection(lines);

if (existing) {
  const fragmentLines = fragment.trim().split('\n');
  const body = fragmentLines.slice(1); // skip [mcp_servers.GateData] header
  const updated = [
    `[mcp_servers.${existing.name}]`,
    ...body,
  ];
  const out = [
    ...lines.slice(0, existing.start),
    ...updated,
    ...lines.slice(existing.end),
  ];
  fs.writeFileSync(configPath, out.join('\n').replace(/\n*$/, '\n'));
} else {
  const sep = content.length && !content.endsWith('\n') ? '\n' : '';
  const header = content.length
    ? `${sep}\n################################################################################\n# GateData MCP (added by gatedata-mcp-installer)\n################################################################################\n`
    : '';
  fs.writeFileSync(configPath, content + header + fragment + (fragment.endsWith('\n') ? '' : '\n'));
}

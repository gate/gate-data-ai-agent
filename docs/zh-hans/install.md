# 安装器说明

入口脚本：`skills/gatedata-mcp-installer/scripts/install.sh`

---

## 命令

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh [options]
```

| 参数 | 说明 | 默认 |
|------|------|------|
| `--platform` | `cursor` / `claude` / `codex` | 自动检测 |
| `--mode` | `remote`（HTTP）/ `stdio`（`gatedata mcp-bridge`） | `remote` |
| `--api-key` | 生产 Key `gd_live_*` | 见下方解析顺序 |
| `--skills-only` | 只同步 Skills，不改 MCP | off |
| `--dry-run` | 预览，不写文件 | off |
| `--force-mcp` | 已有 GateData MCP 时仍更新 MCP 配置 | off |
| `--no-skills` | 只写 MCP，不装 Skills | off |
| `--gatedata-bin` | stdio 模式二进制路径 | 自动探测 |

---

## API Key 解析顺序

1. `--api-key`
2. 环境变量 `GATEDATA_API_KEY`
3. 已有 MCP 配置中的 GateData Bearer（Cursor/Claude：`mcp.json`；Codex：`config.toml`）
4. `~/.gatedata/config.yaml` 的 `api_key`
5. 交互输入（`--skills-only` 时可跳过）

实现：`skills/gatedata-mcp-installer/scripts/read-api-key.js`

---

## MCP configuration

**Remote（默认）** — 写入 `GateData` server：

```json
{
  "GateData": {
    "url": "https://mcp.gatedata.ai/mcp",
    "transport": "streamable-http",
    "timeout": 60,
    "headers": {
      "Accept": "application/json, text/event-stream",
      "Authorization": "Bearer gd_live_xxx"
    }
  }
}
```

**Stdio** — 需本地 `gatedata` 二进制，连接 `https://api.gatedata.ai`。

### MCP 协议兼容

GateData Streamable MCP（`POST/GET /mcp`）**向后兼容**现有 Cursor / Claude / Codex 客户端，并在客户端协商时支持较新的 MCP **`2026-07-28`** 修订版。

- **现有安装器配置不用改**（URL、API Key、`streamable-http` 不变）。
- 客户端自动协商协议版本。
- REST 及其他非 Streamable MCP 路径不受影响。
- 产品文档：[gatedata.ai/docs](https://gatedata.ai/docs)

---

## 智能行为

- 检测到已有 GateData MCP（URL 含 `gatedata.ai` 或名称 `GateData*`）→ **默认只装 Skills**
- `--force-mcp` 时**原地更新**已有 GateData server（不新增重复条目）
- 写入前备份 `mcp.json.bak.YYYYMMDD-HHMMSS`
- 写入后 `chmod 600`
- 安装前可选 curl 探测 tools API

---

## 辅助脚本

```bash
bash scripts/sync-skills.sh --platform cursor   # 等同 --skills-only
bash scripts/sync-skills.sh --check             # 对比本地与仓库版本
bash scripts/status.sh --platform cursor --live # 状态检查（支持 cursor/claude/codex）
bash scripts/check-remote.sh                      # GitHub raw URL 检查
bash scripts/verify.sh                            # CI 静态检查
```

---

## Agent Skill

安装器本身也是 Skill：`skills/gatedata-mcp-installer/SKILL.md`  
执行细节：`skills/gatedata-mcp-installer/references/mcp.md`

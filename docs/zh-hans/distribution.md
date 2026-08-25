# GateData Agent 分发与安装

除 `install.sh` 外的安装与分发方式。快速入门见 [getting-started.md](./getting-started.md)。

---

## 1. 一行 bootstrap（curl）

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor --api-key gd_live_xxx
```

本地已有仓库：

```bash
bash scripts/bootstrap.sh --platform cursor --api-key gd_live_xxx
```

---

## 2. Skills 生态（Cursor `npx skills`）

与 [gate-skills](https://github.com/gate/gate-skills) 相同，Cursor 用户可用官方 Skills CLI 安装本仓库：

```bash
npx skills add https://github.com/gate/gate-data-ai-agent
```

仅安装单个 Skill：

```bash
npx skills add https://github.com/gate/gate-data-ai-agent --skill gatedata-market-research
```

> **注意：** `npx skills add` 只安装 Skills，**不会**写入 MCP 配置。MCP 仍建议通过 `gatedata-mcp-installer` 或 `install.sh` 配置 `~/.cursor/mcp.json`。
>
> 检查本地 Skills 是否与仓库同步：`bash scripts/sync-skills.sh --check`

---

## 3. stdio 模式（开发者）

需本地可用的 `gatedata` 二进制（连接 `https://api.gatedata.ai`）：

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh \
  --platform cursor \
  --mode stdio \
  --gatedata-bin /path/to/gatedata \
  --api-key gd_live_xxx
```

stdio 为可选。多数用户应使用 **remote** MCP。仅当你自行设置 `GATEDATA_CLI_RELEASE_BASE` 与 `GATEDATA_CLI_VERSION` 时，才可用 `scripts/install-gatedata-cli.sh` 下载二进制。

---

## 4. 自然语言（Cursor Agent）

```
帮我自动安装 GateData MCP：https://github.com/gate/gate-data-ai-agent
```

---

## 5. 验证

```bash
bash scripts/verify.sh
bash scripts/verify.sh --live gd_live_xxx
bash scripts/status.sh --platform cursor --live
bash scripts/sync-skills.sh --check
```

---

## 相关文档

- [getting-started.md](./getting-started.md)
- [install.md](./install.md)

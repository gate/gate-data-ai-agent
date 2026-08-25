# gate-data-ai-agent

GateData 面向 AI Agent 的**分发与 onboarding 层**：一键安装 MCP、Agent Skills 与运行时规则。

MCP/API 能力见 [产品文档](https://gatedata.ai/zh-hans/docs)；本仓库参照 [gate-skills](https://github.com/gate/gate-skills) 实现。

**环境：仅生产（gatedata.ai / mcp.gatedata.ai）。**

## 一键安装

```
帮我自动安装 GateData MCP：https://github.com/gate/gate-data-ai-agent
```

```bash
git clone https://github.com/gate/gate-data-ai-agent.git
cd gate-data-ai-agent
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor
```

一行 bootstrap：

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor
```

在 [gatedata.ai](https://gatedata.ai) 创建生产 API Key（`gd_live_*`，开启 `enable_mcp`，scopes：`markets`、`assets`、`prediction`、`signals`、`fundamentals`、`earnings`）。套餐：`signals` 需 **Plus+**；基本面/财报需 **Pro 或 Enterprise**。Free 覆盖 markets/assets/prediction。

完整指南：[docs/zh-hans/getting-started.md](docs/zh-hans/getting-started.md) · [English](docs/en/getting-started.md)

## 常用命令

```bash
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor --api-key gd_live_xxx
bash scripts/sync-skills.sh --platform cursor    # 仅 Skills
bash scripts/sync-skills.sh --check              # 检查是否需要更新
bash scripts/status.sh --platform cursor --live  # 状态检查
bash scripts/check-remote.sh                     # GitHub raw URL 检查
bash scripts/verify.sh                           # CI 检查
```

脚本说明：[scripts/README.md](scripts/README.md)

## 许可证

MIT — 见 [LICENSE](LICENSE)。

## 行为准则

见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。

## 安全

见 [SECURITY.md](SECURITY.md)。

## 变更记录

见 [CHANGELOG.md](CHANGELOG.md)。

## 文档结构

| 中文 | English |
|------|---------|
| [docs/zh-hans/getting-started.md](docs/zh-hans/getting-started.md) | [docs/en/getting-started.md](docs/en/getting-started.md) |
| [docs/zh-hans/install.md](docs/zh-hans/install.md) | [docs/en/install.md](docs/en/install.md) |
| [docs/zh-hans/distribution.md](docs/zh-hans/distribution.md) | [docs/en/distribution.md](docs/en/distribution.md) |

## 仓库结构

```
skills/           # 安装器 + 领域 Skills
scripts/          # 工具脚本
docs/             # 用户文档
```

## 相关链接

- https://gatedata.ai/zh-hans/docs
- https://github.com/gate/gate-data-ai-agent

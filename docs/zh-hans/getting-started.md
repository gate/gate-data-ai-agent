# 快速开始

GateData Agent 仓库提供 **MCP 安装器** 与 **用户向 Skills**，覆盖标的解析、行情、预测市场、新闻/情绪，以及基本面/财报，可用于 Cursor / Claude / Codex。

**环境：仅生产**（`https://mcp.gatedata.ai/mcp`）。

MCP 端点兼容现有客户端，并在客户端协商时支持更新的 MCP 协议修订版——**安装器配置无需修改**。详见 [install.md](./install.md#mcp-协议兼容)。

---

## 1. 准备 API Key

1. 打开 [gatedata.ai](https://gatedata.ai) → Dashboard → **API Keys**
2. 创建 Key（`gd_live_*`）
3. 开启 **`enable_mcp`**
4. 勾选 scopes：`markets`、`assets`、`prediction`、`signals`、`fundamentals`、`earnings`（按需）。套餐：`signals` 需 **Plus+**；基本面/财报需 **Pro 或 Enterprise**。Free 覆盖 markets/assets/prediction。

---

## 2. 安装

### 方式 A：自然语言（Cursor Agent）

```
帮我自动安装 GateData MCP：https://github.com/gate/gate-data-ai-agent
```

### 方式 B：Git 克隆

```bash
git clone https://github.com/gate/gate-data-ai-agent.git
cd gate-data-ai-agent
bash skills/gatedata-mcp-installer/scripts/install.sh --platform cursor --api-key gd_live_xxx
```

若 `~/.cursor/mcp.json` **已有** GateData MCP（如 `GateData.AI`），安装器默认**只同步 Skills**：

```bash
bash scripts/sync-skills.sh --platform cursor
```

### 方式 C：一行 curl

```bash
curl -fsSL "https://raw.githubusercontent.com/gate/gate-data-ai-agent/main/scripts/bootstrap.sh" \
  | bash -s -- --platform cursor --api-key gd_live_xxx
```

本地已有仓库时：`bash scripts/bootstrap.sh --platform cursor --api-key gd_live_xxx`

### 方式 D：Skills CLI（仅 Skills）

```bash
npx skills add https://github.com/gate/gate-data-ai-agent
```

> `npx skills add` 只安装 Skills，**不会**写入 MCP 配置。MCP 请用 `install.sh`。

---

## 3. 重启并验证

```bash
bash scripts/status.sh --platform cursor --live
```

1. 重启 Cursor（或 Reload MCP）
2. MCP 面板应出现 GateData 相关 server
3. tools 列表含 6 个域级工具：`assets_resolve`、`market_data_query`、`prediction_markets_query`、`events_news_query`、`fundamentals_query`、`estimates_earnings_query`

---

## 4. 试用对话

| 你说 | 预期 Skill / Tool |
|------|-------------------|
| BTC 现在多少钱？ | `gatedata-market-research` → `market_data_query`（`task: snapshot`）|
| 预测市场成交量排行 | `gatedata-prediction-markets` → `prediction_markets_query`（`task: rankings`）|
| BTC 最近有什么新闻？ | `gatedata-signals-news` → `events_news_query`（`task: content_search`）|
| NVDA 下次财报什么时候？ | `gatedata-fundamentals-earnings` → `estimates_earnings_query`（`task: calendar`）|
| 解析 Apple（股票还是代币） | `gatedata-assets-resolve` → `assets_resolve` |

---

## 5. 已安装 Skills

| Skill | 用途 |
|-------|------|
| `gatedata-mcp-installer` | 安装 / 更新 |
| `gatedata-market-research` | 行情、K 线、盘口、衍生品 |
| `gatedata-prediction-markets` | 预测市场 |
| `gatedata-signals-news` | 新闻、情绪、事件 |
| `gatedata-fundamentals-earnings` | 基本面、财报、业绩、分析师预期 |
| `gatedata-assets-resolve` | 标的 / 合约 / 上市列表解析 |

---

## 下一步

- 安装参数详解：[install.md](./install.md)
- 其他分发方式：[distribution.md](./distribution.md)
- 产品 API 文档：[gatedata.ai/zh-hans/docs](https://gatedata.ai/zh-hans/docs)

# Market Research — Troubleshooting

All calls use MCP tool `market_data_query`.

## HTTP 401 / unauthorized

- Verify production API key (`gd_live_*`) with `enable_mcp` enabled.
- Re-run [gatedata-mcp-installer](../../gatedata-mcp-installer/SKILL.md) if MCP config is missing.

## Scope denied

- Dashboard → API Keys → enable `markets` scope.

## 40001 ambiguous listing

**Symptom:** `candidates` array, or message about ambiguous resolution.

**Fix:**
- Add `venue` / `venue_id` and `market_type` (`spot` / `perp`).
- Or pass `listing_id` from prior `metadata.candidates`.
- Ask user one clarifying question if intent is unclear.

## Empty or partial data

- Check `data_status` and `limitations` in response.
- **Equity ticker returns `no_data`:** add `market` / `context.market` (e.g. `us_equity`).
- **Equity + trades/liquidity/derivatives/depth/heatmap:** crypto-only this phase → expect `no_data` / `crypto_only`; use `snapshot` / `kline` / `orderbook` / `technical_indicators` instead.
- **Bare `task: summary`:** snapshot-only without `field_group` — prefer first-class `orderbook` / `trades` / `cex_derivatives` / …
- TradFi samples (AAPL, NVDA, TSLA) may have narrower fields than crypto.
- Retry with explicit `venue` if single-venue data is required.

## technical_indicators

- Requires equity identity: `tickers`+`market` and/or `listing_id`/`listing_ids` / `object_refs`.
- Doris unavailable → `503` / `not_ready`.
- Accepts Doris `US.AAPL` and Gate `listing_*` forms.

## anomaly / move

- These tasks return snapshot-style price facts only.
- For catalysts / “why”, use signals `content_search` / `sentiment` + market `kline`.

## Wrong skill routed

| Symptom | Route to |
|---------|----------|
| Polymarket / prediction odds | `gatedata-prediction-markets` |
| News / sentiment | `gatedata-signals-news` |
| Financial statements / earnings | `gatedata-fundamentals-earnings` |
| Crypto tokenomics / supply | `gatedata-fundamentals-earnings` |

## Billing / rate limit

- Suggest checking Dashboard credits at [gatedata.ai](https://gatedata.ai).

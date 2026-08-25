# Prediction Markets — Troubleshooting

All calls use MCP tool `prediction_markets_query`.

## HTTP 401 / unauthorized

- Production API key with `enable_mcp` and `prediction` scope.

## missing_required_params

| Task | Common miss |
|------|-------------|
| `rankings` | `ranking_type` |
| `order_book` | `venue` and `market_id` |
| `event_detail` / `event_signal` | `event_ref` / `event_id` |
| `market` / `summary` | `market_id` / `market_ref` or `event_ref` |

## Empty search results

- Broaden `query` or remove `venue` filter.
- Try `task: rankings` for discovery instead of keyword search.

## 50301 signal not ready

- `task: event_signal` may return not-ready for new or thin events.
- Fall back to `task: market` for prices only.

## Do not call (planned)

- `task: probability_history`
- `task: volume_delta`

Use `task: market` / `task: summary` / `task: order_book` instead.

## Wrong skill

| Symptom | Route to |
|---------|----------|
| BTC spot price | `gatedata-market-research` |
| News about an event | `gatedata-signals-news` |

## venue values

- Use venue from prior API responses (`metadata` / market detail).
- Do not guess `market_id`; always from search, rankings, or event detail.

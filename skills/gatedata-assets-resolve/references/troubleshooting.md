# Assets Resolve — Troubleshooting

## HTTP 401 / unauthorized

- Production API key with `enable_mcp` and `assets` scope.
- Free plan includes the `assets` domain.

## Ambiguous (not an error)

- HTTP 200 + `resolution_status=ambiguous` + candidates → ask the user.
- Narrow with `context.market` (`us_equity`, `crypto`, …), `context.chain`, or `context.market_type`.

## invalid_task

- `task: universe` is **out of phase-1 public scope** — use `search` / `resolve` / `coverage` instead.

## Empty / not found

- Try `task: search` with a broader `query`.
- For equities, pass StandardMarket; bare tickers may otherwise lean crypto.
- Equity company background / 公司简介 → fundamentals `task: profile`, not assets profile.

## Wrong next skill

| Need after resolve | Skill |
|--------------------|-------|
| Live price / kline | `gatedata-market-research` |
| Financials / earnings | `gatedata-fundamentals-earnings` |
| News / sentiment | `gatedata-signals-news` |
| Prediction odds | `gatedata-prediction-markets` |

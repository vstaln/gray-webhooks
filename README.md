# gray-webhooks

Inbound HTTP becomes agent turns. A tiny HTTP listener on **127.0.0.1**
(never `0.0.0.0`) routes `POST /<path>` to a named webhook; the body lands
as `Webhook <name> fired: <body>` in the session — immediately via
`host/run` when `host.turn` is granted, otherwise queued for the next
`agent/before_start` injection. Original work — the event-trigger half of
the cron pair.

## Usage

```
/webhook add deploy /deploy
curl -X POST http://127.0.0.1:7844/deploy -d 'build green'
/webhook list
/webhook tail deploy
```

## Commands

- `/webhook add <name> <path>` — register a route (names: `[a-zA-Z0-9_-]`,
  paths start with `/`). Replies with the full `curl`-able URL.
- `/webhook list` — routes, listener state, queued count
- `/webhook rm <name>` — remove a route
- `/webhook tail <name>` — last 10 deliveries

## Tool

`webhook_emit {name, body}` — fires a route without HTTP, through the same
delivery path. For self-testing.

## Delivery

One strategy: try `host/run`, fall back to the before_start queue. Once
`host/run` fails it isn't retried — later deliveries go straight to the
queue. Bodies are capped at 8 KiB. Every delivery is appended to
`~/.gray/webhooks/log/<name>.jsonl` (`{ts, body, content_type, via}`).

## Files

- `~/.gray/webhooks/routes.json` — route table (`name → {path, created_at}`)
- `~/.gray/webhooks/config.json` — `{"port": 7844}`
- `~/.gray/webhooks/log/<name>.jsonl` — delivery log

The listener starts when a route exists or `/webhook add` runs; a single
listener thread serves all routes.

## Wire

- claims: `agent/before_start` (queue drain into `{text}`), `tool/call`
  (`webhook_emit`), `command/run` (`/webhook`), `plugin/manifest`,
  `plugin/shutdown`
- sidecar→host: `host/run` (blocking, 30s TTL; capability `host.turn`)
- protocol `2.0`; works degraded (queue-only) without the capability

## Install

```
gray plugin install ~/grayplugins/gray-webhooks
gray plugin capabilities webhooks --all   # enables immediate host/run delivery
```

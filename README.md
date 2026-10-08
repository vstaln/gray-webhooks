<p align="center">
  <img src="assets/gray-logo.svg" alt="gray" width="96">
</p>
<h1 align="center">gray-webhooks</h1>
<p align="center">POST to 127.0.0.1 — inbound HTTP becomes agent turns.</p>
<p align="center">
  <a href="https://github.com/vstaln/gray-webhooks/blob/main/LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
  <img alt="gray plugin" src="https://img.shields.io/badge/gray-plugin-7aa2f7.svg">
  <img alt="rust" src="https://img.shields.io/badge/built%20with-rust-orange.svg">
</p>

Inbound HTTP becomes agent turns. A tiny HTTP listener on **127.0.0.1**
(never `0.0.0.0`) routes `POST /<path>` to a named webhook; the body lands
as `Webhook <name> fired: <body>` in the session — immediately via
`host/run` when `host.turn` is granted, otherwise queued for the next
`agent/before_start` injection.

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
gray plugin install webhooks
gray plugin capabilities webhooks --all   # enables immediate host/run delivery
```

---
Part of the [gray](https://github.com/vstaln/gray) plugin ecosystem —
the open-source AI agent harness. <https://gray.alignment.id>

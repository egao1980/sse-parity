# sse-parity

Interop canary: **[`sse-protocol`](https://github.com/egao1980/sse-protocol)** vs existing **Node** (`eventsource`) and **Python** (`httpx-sse`) servers and clients, both ways.

Lisp owns the harness and assertions. Node/Python peers are the SUT, not refresh scripts.

```
Lisp client  →  Node server
Lisp client  →  Python server
Node client  →  Lisp server (sse-backend-clack)
Python client → Lisp server
```

## Run

```bash
cd peers/node && npm install
cd ../python && uv sync
export SSE_PARITY_PEERS=1
ros -e '(asdf:test-system "sse-parity")' -q
```

Lisp↔Lisp only (no Node/Python):

```bash
export SSE_PARITY_PEERS=0
ros -e '(asdf:test-system "sse-parity")' -q
```

## Matrix

See [MATRIX.md](MATRIX.md).

## Env

| Variable | Default | Meaning |
|----------|---------|---------|
| `SSE_PARITY_PEERS` | on | `0` skips Node/Python peers |
| `SSE_PARITY_LAST_EVENT_ID` | unset | forwarded by foreign clients |

## Gaps this is meant to surface

- Clack emit is a **finite** response body, not a long-lived chunked writer
- No reconnect / `retry` backoff interop yet
- MIME / charset / CORS are HTTP, not framing

## License

MIT

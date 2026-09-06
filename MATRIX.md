# sse-parity matrix

Status: `have` · `partial` · `missing` · `skip`

| Route | Lisp→Lisp | Lisp→Node | Lisp→Python | Node→Lisp | Python→Lisp |
|-------|-----------|-----------|-------------|-----------|-------------|
| `/basic` | have | have | have | have | have |
| `/multiline` | have | have | have | have | have |
| `/typed` | have | have | have | have | have |
| `/id` | have | have | have | have | have |
| `/utf8` | have | have | have | have | have |
| `/comment` | have | have | have | have | have |
| `/last` first | have | have | have | have | have |
| `/last` resume | have | have | have | skip | skip |
| `/retry` | have | have | have | have | have |
| reconnect | have | have | have | skip | skip |
| `/hold` (chunked) | have | have | have | have | have |
| MIME / charset | skip | skip | skip | skip | skip |

`/last` resume and auto-reconnect for foreign clients are skipped: clients would need `SSE_PARITY_LAST_EVENT_ID` plus a second request (or a browser EventSource loop). The Lisp client covers `Last-Event-ID` and `open-sse :reconnect t`.

Long-lived chunked: `sse-backend-clack:make-sse-app` returns a Clack body function. `/hold` writes an event, then a keepalive, then a delayed event on the live stream. Node/Python peers do the same with write/flush/sleep.

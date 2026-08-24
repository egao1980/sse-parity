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
| reconnect / `retry` | missing | missing | missing | missing | missing |
| long-lived chunked | missing | n/a | n/a | missing | missing |
| MIME / charset | skip | skip | skip | skip | skip |

`/last` resume for foreign clients is skipped: clients would need `SSE_PARITY_LAST_EVENT_ID` plus a second request; the Lisp client covers Last-Event-ID.

Long-lived chunked: `sse-backend-clack` currently encodes a finite body (`make-sse-app`). Node/Python servers can hold the socket; the Lisp emit path cannot yet stream keepalives after the handler returns.

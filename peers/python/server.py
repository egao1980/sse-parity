#!/usr/bin/env python3
from __future__ import annotations

import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROUTES = {
    "/basic": "data: hello\n\n",
    "/multiline": "data: one\ndata: two\n\n",
    "/typed": "event: ping\ndata: ok\n\n",
    "/id": "id: 7\ndata: x\n\n",
    "/utf8": "data: αβγ ✔\n\n",
    "/comment": ":keep\ndata: after\n\n",
}


class Server(ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args: object) -> None:
        return

    def do_GET(self) -> None:  # noqa: N802
        path = self.path.split("?", 1)[0]
        if path == "/last":
            last = self.headers.get("Last-Event-ID")
            body = "id: 2\ndata: resume\n\n" if last == "1" else "id: 1\ndata: first\n\n"
        else:
            body = ROUTES.get(path)
        if body is None:
            self.send_error(404, "not found")
            return
        data = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "keep-alive")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main() -> None:
    port = int(sys.argv[1] if len(sys.argv) > 1 else 0)
    server = Server(("127.0.0.1", port), Handler)
    bound = server.server_address[1]
    print(f"SSE_PARITY_LISTEN {bound}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()

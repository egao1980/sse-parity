#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import sys

import httpx
from httpx_sse import connect_sse


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: client.py <url>", file=sys.stderr)
        raise SystemExit(2)
    url = sys.argv[1]
    headers = {}
    last = os.environ.get("SSE_PARITY_LAST_EVENT_ID")
    if last:
        headers["Last-Event-ID"] = last
    with httpx.Client(timeout=5.0) as client:
        with connect_sse(client, "GET", url, headers=headers) as event_source:
            for event in event_source.iter_sse():
                rec = {
                    "id": event.id or None,
                    "event": event.event or "message",
                    "data": event.data,
                }
                print(json.dumps(rec, ensure_ascii=False), flush=True)


if __name__ == "__main__":
    main()

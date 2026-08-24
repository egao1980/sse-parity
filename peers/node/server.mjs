import http from "node:http";

const routes = {
  "/basic": "data: hello\n\n",
  "/multiline": "data: one\ndata: two\n\n",
  "/typed": "event: ping\ndata: ok\n\n",
  "/id": "id: 7\ndata: x\n\n",
  "/utf8": "data: αβγ ✔\n\n",
  "/comment": ":keep\ndata: after\n\n",
};

function bodyFor(req) {
  const url = new URL(req.url, "http://127.0.0.1");
  if (url.pathname === "/last") {
    const last = req.headers["last-event-id"];
    return last === "1" ? "id: 2\ndata: resume\n\n" : "id: 1\ndata: first\n\n";
  }
  return routes[url.pathname] ?? null;
}

const port = Number(process.argv[2] || process.env.SSE_PARITY_PORT || 0);
const server = http.createServer((req, res) => {
  const body = bodyFor(req);
  if (body == null) {
    res.writeHead(404, { "content-type": "text/plain" });
    res.end("not found");
    return;
  }
  res.writeHead(200, {
    "content-type": "text/event-stream; charset=utf-8",
    "cache-control": "no-cache",
    connection: "keep-alive",
  });
  res.end(body);
});

server.listen(port, "127.0.0.1", () => {
  const { port: bound } = server.address();
  process.stdout.write(`SSE_PARITY_LISTEN ${bound}\n`);
});

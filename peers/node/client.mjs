import { EventSource } from "eventsource";

const url = process.argv[2];
if (!url) {
  console.error("usage: node client.mjs <url>");
  process.exit(2);
}

const headers = {};
const last = process.env.SSE_PARITY_LAST_EVENT_ID;
if (last) headers["Last-Event-ID"] = last;

const es = new EventSource(url, { headers });
const seen = [];

function emit(e) {
  const rec = {
    id: e.lastEventId || null,
    event: e.type || "message",
    data: e.data,
  };
  seen.push(rec);
  process.stdout.write(`${JSON.stringify(rec)}\n`);
}

es.addEventListener("message", emit);
es.addEventListener("ping", emit);
es.onerror = () => {
  es.close();
  process.exit(0);
};

setTimeout(() => {
  es.close();
  process.exit(seen.length ? 0 : 1);
}, 4000);

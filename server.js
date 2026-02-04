const express = require("express");
const os = require("os");
const client = require("prom-client");

const app = express();
const PORT = process.env.PORT || 8080;

client.collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
  name: "http_requests_total",
  help: "Total HTTP requests",
  labelNames: ["method", "route", "status"],
});

const httpRequestDurationSeconds = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "HTTP request duration in seconds",
  labelNames: ["method", "route", "status"],
  buckets: [0.01, 0.025, 0.05, 0.1, 0.2, 0.5, 1, 2, 5],
});

app.use((req, res, next) => {
  const end = httpRequestDurationSeconds.startTimer();
  res.on("finish", () => {
    const route = req.route?.path || req.path || "unknown";
    const labels = { method: req.method, route, status: String(res.statusCode) };
    httpRequestsTotal.inc(labels);
    end(labels);
  });
  next();
});

app.get("/", (req, res) => res.send(`ok - hostname=${os.hostname()}\n`));
app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/work", (req, res) => {
  const ms = Math.min(parseInt(req.query.ms || "800", 10), 10000);
  const end = Date.now() + ms;
  while (Date.now() < end) Math.sqrt(Math.random());
  res.json({ worked_ms: ms });
});

app.get("/kill", (req, res) => {
  res.send("bye\n");
  setTimeout(() => process.exit(1), 50);
});

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

/** ✅ 5xx 테스트 라우트: listen 위에 두기 */
app.get("/fail", (req, res) => {
  res.status(500).send("forced 500");
});

// 503 강제 발생(가끔 503이 더 보기 좋음)
app.get("/unavailable", (req, res) => {
  res.status(503).send("forced 503");
});

app.listen(PORT, "0.0.0.0", () => console.log(`listening on :${PORT}`));

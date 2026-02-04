# monitoring

Repository about monitoring.

## Monitoring Stack (Prometheus + Grafana) on AWS EC2 + ASG

This repository contains a monitoring setup to run Prometheus, Grafana, and exporters on AWS EC2 (Ubuntu).
It is verified on a single EC2 first, then extended to work with Auto Scaling Groups (ASG).

---

## What I’m building
- Collect host metrics (CPU, memory, disk, network) using `node_exporter`
- Store and query metrics in Prometheus
- Visualize metrics in Grafana
- Expose application metrics (sample Node.js app `/metrics`) and scrape them from Prometheus
- Keep all configuration files in this repo for version control and future extension (ASG, automation)

---

## Current status (verified)
- Running containers (Docker Compose)
  - Prometheus (:9090)
  - Grafana (:3000)
  - node_exporter (:9100)
  - test Node.js app (:8080)

- Prometheus Targets
  - `prometheus`: **UP (1/1)**
  - `node`: **UP (3/3)** (ASG instances)
  - `nodeapp`: **UP (3/3)** (ASG instances)

- Grafana
  - Prometheus datasource connected
  - Dashboards show per-instance metrics using `instance` label

---

## Quick checks (CLI)
### App metrics
```bash
curl -s http://localhost:8080/metrics | grep http_requests_total | head
## PromQL examples (per-instance)

> 아래 쿼리는 node_exporter 기준이며, 인스턴스 필터는 필요할 때만 추가하세요.
> 예: `{job="node"}` / `{instance="<PRIVATE_IP>:9100"}` / `{instance_name="<TAG_NAME>"}`

### CPU usage (%)
```promql
100 * (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))
Memory usage (%)
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
Network input (bytes/sec)
sum by (instance) (rate(node_network_receive_bytes_total{device!~"lo"}[5m]))
Network output (bytes/sec)
sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo"}[5m]))

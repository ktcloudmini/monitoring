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

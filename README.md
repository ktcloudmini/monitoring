# monitoring

repository about monitoring

# Monitoring Stack (Prometheus + Grafana) on AWS EC2

This repository contains a simple monitoring setup to run Prometheus, Grafana, and exporters on an AWS EC2 (Ubuntu) instance.
The goal is to build and verify the monitoring stack on EC2 first, then extend it to work cleanly with Auto Scaling Groups (ASG) later.

## What I’m building
- Collect host metrics (CPU, memory, disk, network) using an exporter (e.g., node_exporter)
- Store and query metrics in Prometheus
- Visualize metrics in Grafana by connecting Prometheus as a data source
- Expose application metrics (sample Node.js app /metrics) and scrape them from Prometheus
- Keep all configuration files in this repo for easy version control and future migration/extension

## Current progress
- Containers running (Docker):
  - Prometheus (:9090)
  - Grafana (:3000)
  - node_exporter (:9100)
  - test Node.js app (:8080)
- Prometheus Targets shows prometheus, node, and nodeapp as UP
- The sample app exposes HTTP request metrics at test-node-app:8080/metrics (e.g., http_requests_total)

## Planned workflow
1. Prepare the monitoring configuration under this repository (e.g., prometheus/, grafana/).
2. Run the stack on AWS EC2 (Docker Compose).
3. Verify metric collection in Prometheus and dashboards in Grafana.
4. Extend the setup to support Auto Scaling (scrape all instances added by ASG automatically).

## How to verify
- Prometheus Targets page should show exporters/apps as UP
- Grafana should successfully connect to Prometheus as a data source
- Dashboards/Explore should display real-time metrics

## Quick checks (CLI)
- App metrics:
  curl -s http://localhost:8080/metrics | grep http_requests_total | head

- node_exporter metrics:
  curl -s http://localhost:9100/metrics | head

## PromQL examples
- Requests per second (5m rate):
  sum by (instance) (rate(http_requests_total[5m]))

- Requests increase (last 5m):
  sum by (instance) (increase(http_requests_total[5m]))

- Traffic share (%) by instance:
  100 * sum by (instance) (rate(http_requests_total[5m])) / scalar(clamp_min(sum(rate(http_requests_total[5m])), 1e-9))

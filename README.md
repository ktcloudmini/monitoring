# monitoring

repository about monitoring 

# Monitoring Stack (Prometheus + Grafana) on Ubuntu VM

This repository contains a simple monitoring setup to run **Prometheus**, **Grafana**, and exporters on an **Ubuntu VM**.  
The goal is to build the monitoring stack first on a VM, then migrate the same configuration to AWS EC2 later.

## What I’m building
- Collect host metrics (CPU, memory, disk, network) using an exporter (e.g., `node_exporter`)
- Store and query metrics in **Prometheus**
- Visualize metrics in **Grafana** by connecting **Prometheus** as a data source
- Keep all configuration files in this repo for easy version control and future migration

## Planned workflow
1. Prepare the monitoring configuration under this repository (e.g., `prometheus/`, `grafana/`).
2. Run the stack on the Ubuntu VM (Docker Compose recommended).
3. Verify metric collection in Prometheus and dashboards in Grafana.
4. Migrate the same setup to EC2 by reusing the same repo/config.

## How to verify
- Prometheus Targets page should show exporters as **UP**
- Grafana should successfully connect to Prometheus as a data source
- Dashboards should display real-time host metrics


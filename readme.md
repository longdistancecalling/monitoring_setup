# Monitoring Stack

A simple script for installing a monitoring stack with Grafana, Prometheus, and Node-Exporter using Docker Compose.

## Contents
- setup-monitoring-compose.sh — Script that creates a `monitoring-config` directory and places the following files inside it:
  - `prometheus.yml` (scrape configuration)
  - `docker-compose.yml` (Grafana, Prometheus, Node-Exporter)
  and then starts the stack.

## Requirements
- Docker installed
- Docker Compose (either `docker compose` or `docker-compose`)
- On Windows: Run the script using Git Bash or WSL (the script is a Bash script).



log into grafana: <SERVERIP>:3000
initial credentials:
user: admin
pwd:  admin

password change will be required

# Setup Dashboard
- go to: Connections>Data sources
- Connection: http://prometheus:9090
- save and test
- test should be successful
- go to: Dashboards
- New
- Import
- enter 1860 in search field
- name your dashboard e.g. Server Monitoring
- click on import
- Dashboard should be available
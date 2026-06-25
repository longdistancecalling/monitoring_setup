#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#Monitoring stack: Grafana, Prometheus, node-exporter
# Starts the stack via docker-compose.yml in the “monitoring” network.
# Only Grafana exposes a port to the outside (3000).
# Prometheus and node-exporter are accessible exclusively internally
# via their container names.
# ================================z============================

CONFIG_DIR="$(pwd)/monitoring-config"
COMPOSE_FILE="${CONFIG_DIR}/docker-compose.yml"
PROMETHEUS_FILE="${CONFIG_DIR}/prometheus.yml"
GRAFANA_PORT="3000"

echo ">>> Checking if Docker is installed..."
if ! command -v docker > /dev/null 2>&1; then
  echo "Docker is not installed. Please install Docker first."
  exit 1
fi

echo ">>> Checking if Docker Compose is available..."
if docker compose version &> /dev/null; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
  COMPOSE_CMD="docker-compose"
else
  echo "docker compose (or docker-compose) was not found. Please install first."
  exit 1
fi
echo "Using: ${COMPOSE_CMD}"

echo ">>> Creating configuration directory: ${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}"

echo ">>> Creating prometheus.yml (Scrape configuration)..."
cat > "${PROMETHEUS_FILE}" <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]
EOF

echo ">>> Creating docker-compose.yml..."
cat > "${COMPOSE_FILE}" <<EOF
version: "3.9"

networks:
  monitoring:
    name: monitoring
    driver: bridge

volumes:
  grafana-data:
  prometheus-data:

services:

  node-exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    pid: host
    networks:
      - monitoring
    volumes:
      - /:/host:ro,rslave
    command:
      - "--path.rootfs=/host"
    # Kein "ports:" -> nur intern im Netzwerk erreichbar

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    networks:
      - monitoring
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    depends_on:
      - node-exporter
    # Kein "ports:" -> nur intern im Netzwerk erreichbar

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    networks:
      - monitoring
    ports:
      - "${GRAFANA_PORT}:3000"   # einziger nach aussen freigegebener Port
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
EOF

echo ">>> Starting monitoring stack with ${COMPOSE_CMD}..."
cd "${CONFIG_DIR}"
${COMPOSE_CMD} up -d

echo ""
echo "============================================================"
echo "Done!"
echo "Grafana accessible at: http://localhost:${GRAFANA_PORT}"
echo "  Default login: admin / admin (will be changed on first login)"
echo ""
echo "Prometheus is ONLY accessible internally in the 'monitoring' network:"
echo "  http://prometheus:9090"
echo ""
echo "node-exporter is ONLY accessible internally in the 'monitoring' network:"
echo "  http://node-exporter:9100"
echo ""
echo "Note: Enter the following in Grafana as the Prometheus data source:"
echo "  http://prometheus:9090"
echo ""
echo "Configuration is located at: ${CONFIG_DIR}"
echo "Stop the stack with: cd ${CONFIG_DIR} && ${COMPOSE_CMD} down"
echo "============================================================"

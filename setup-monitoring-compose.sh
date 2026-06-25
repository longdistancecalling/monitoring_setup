#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Monitoring-Stack: Grafana, Prometheus, node-exporter
# Startet den Stack ueber docker-compose.yml im Netzwerk "monitoring".
# Nur Grafana veroeffentlicht einen Port nach aussen (3000).
# Prometheus und node-exporter sind ausschliesslich intern
# ueber die Container-Namen erreichbar.
# ================================z============================

CONFIG_DIR="$(pwd)/monitoring-config"
COMPOSE_FILE="${CONFIG_DIR}/docker-compose.yml"
PROMETHEUS_FILE="${CONFIG_DIR}/prometheus.yml"
GRAFANA_PORT="3000"

echo ">>> Pruefe ob Docker installiert ist..."
if ! command -v docker > /dev/null 2>&1; then
  echo "Docker ist nicht installiert. Bitte zuerst Docker installieren."
  exit 1
fi

echo ">>> Pruefe ob docker compose verfuegbar ist..."
if docker compose version &> /dev/null; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
  COMPOSE_CMD="docker-compose"
else
  echo "docker compose (bzw. docker-compose) wurde nicht gefunden. Bitte installieren."
  exit 1
fi
echo "Verwende: ${COMPOSE_CMD}"

echo ">>> Erstelle Konfigurationsverzeichnis: ${CONFIG_DIR}"
mkdir -p "${CONFIG_DIR}"

echo ">>> Erstelle prometheus.yml (Scrape-Konfiguration)..."
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

echo ">>> Erstelle docker-compose.yml..."
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

echo ">>> Starte Monitoring-Stack mit ${COMPOSE_CMD}..."
cd "${CONFIG_DIR}"
${COMPOSE_CMD} up -d

echo ""
echo "============================================================"
echo "Fertig!"
echo "Grafana erreichbar unter: http://localhost:${GRAFANA_PORT}"
echo "  Standard-Login: admin / admin (wird beim ersten Login geaendert)"
echo ""
echo "Prometheus ist NUR intern im Netzwerk 'monitoring' erreichbar:"
echo "  http://prometheus:9090"
echo ""
echo "node-exporter ist NUR intern im Netzwerk 'monitoring' erreichbar:"
echo "  http://node-exporter:9100"
echo ""
echo "Hinweis: In Grafana als Prometheus-Datenquelle eintragen:"
echo "  http://prometheus:9090"
echo ""
echo "Konfiguration liegt unter: ${CONFIG_DIR}"
echo "Stack stoppen mit: cd ${CONFIG_DIR} && ${COMPOSE_CMD} down"
echo "============================================================"

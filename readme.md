# Monitoring-Stack

Kleines Setup zum schnellen Start eines Monitoring-Stacks mit Grafana, Prometheus und node-exporter über Docker Compose.

## Inhalt
- setup-monitoring-compose.sh — Script, das ein Verzeichnis `monitoring-config` erstellt und darin:
  - `prometheus.yml` (Scrape-Konfiguration)
  - `docker-compose.yml` (Grafana, Prometheus, node-exporter)
  anschliessend den Stack startet.

## Voraussetzungen
- Docker installiert
- Docker Compose (entweder `docker compose` oder `docker-compose`)
- Auf Windows: Script mit Git Bash oder WSL ausführen (Script ist ein bash-Skript).


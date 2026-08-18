# Monitoring

Grafana dashboards, Prometheus configuration, sensor exporters, and alerting.

## Stack Overview

```
Sensors / System
    │
    ├── BMP280 (I2C) → bmp280_exporter (:8001) ──┐
    ├── SDS011 (UART) → sds011_exporter (:8000) ──┤
    ├── SMART (USB-SATA) → smartctl_exporter (:8002) ──┤
    └── Node metrics → node_exporter (:9100) ──────┤
                                                    │
                                              Prometheus (:9090)
                                                    │
                                                    ▼
                                              Grafana (:3001)
                                                    │
                                                    ├── Dashboards
                                                    └── Alerts → Gotify (:3006)
```

## Prometheus

### Configuration

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    host: pi-nas

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']

  - job_name: 'sds011'
    scrape_interval: 60s
    static_configs:
      - targets: ['sds011_exporter:8000']

  - job_name: 'bmp280'
    scrape_interval: 60s
    static_configs:
      - targets: ['bmp280_exporter:8001']

  - job_name: 'smartctl'
    scrape_interval: 60s
    static_configs:
      - targets: ['smartctl_exporter:8002']
```

### Data Retention

- **Storage**: 30 days (`--storage.tsdb.retention.time=30d`)
- **Lifecycle API**: Enabled (`--web.enable-lifecycle`) for hot reloading

## Grafana

### Access

- **URL**: `http://<pi-tailnet-ip>:3001`
- **Theme**: Dark
- **Sign-up**: Disabled
- **Default dashboard**: NAS Overview

### Dashboards

| Dashboard | Location | Metrics |
|-----------|----------|---------|
| NAS Overview | `dashboards/overview/nas-overview.json` | System health at a glance |
| System | `dashboards/system/` | CPU, RAM, disk, network |
| Storage | `dashboards/storage/` | Disk usage, I/O, SMART health |
| Sensors | `dashboards/sensors/` | Temperature, humidity, pressure, air quality |

### Alerting

Grafana manages alerting and routing:

- **Alert evaluation**: Grafana (not Prometheus rules)
- **Notification channel**: Gotify push notifications
- **Contact point**: Configured via provisioning with Gotify app token

```
Grafana Alert → Gotify API → Phone Push Notification
```

### Provisioning

Grafana is provisioned via files (not manual UI configuration):

```
monitoring/grafana/provisioning/
├── alerting/      # Alert rules and contact points
├── dashboards/    # Dashboard provisioning config
└── datasources/   # Prometheus datasource config
```

## Sensor Exporters

### BMP280 (Temperature, Humidity, Pressure)

**Hardware**: BMP280 sensor connected via I2C (`/dev/i2c-1`)

**Dockerfile**:
```dockerfile
FROM python:3-slim
RUN pip install --no-cache-dir smbus2
COPY bmp280_exporter.py /app/exporter.py
CMD ["python3", "/app/exporter.py"]
```

**Metrics exposed**:
- `bmp280_temperature_celsius` — Current temperature
- `bmp280_humidity_percent` — Current humidity
- `bmp280_pressure_hpa` — Current barometric pressure

**Scrape interval**: 60 seconds

### SDS011 (Air Quality)

**Hardware**: SDS011 sensor connected via UART (`/dev/ttyS0`)

**Dockerfile**:
```dockerfile
FROM python:3-slim
RUN pip install --no-cache-dir pyserial
COPY sds011_exporter.py /app/exporter.py
CMD ["python", "/app/exporter.py"]
```

**Metrics exposed**:
- `sds011_pm25_ugm3` — PM2.5 concentration (μg/m³)
- `sds011_pm10_ugm3` — PM10 concentration (μg/m³)

**Scrape interval**: 60 seconds

### Smartctl Exporter (HDD Health)

**Hardware**: Seagate ST9500325AS connected via USB-SATA

**Configuration**:
- `SMART_REFRESH_SECONDS=900` — Refresh every 15 minutes
- `smartctl -n standby` — Never wakes sleeping disks
- **Privileged mode**: Required for SMART ioctls over USB

**Metrics exposed**:
- `smartctl_device_healthy` — 1 if healthy, 0 if degraded
- `smartctl_device_temperature` — Current temperature
- `smartctl_device_power_on_hours` — Total power-on hours
- `smartctl_device_reallocated_sector_count` — Bad sectors

**Scrape interval**: 60 seconds (but exporter only refreshes every 15 minutes)

### Node Exporter (System Metrics)

**Standard Prometheus node exporter** running with host PID namespace for full system visibility.

**Metrics exposed**:
- CPU usage, load average
- Memory usage, swap usage
- Disk I/O, filesystem usage
- Network traffic, errors
- System uptime, boot time

**Scrape interval**: 15 seconds

## Gotify (Push Notifications)

Gotify receives Grafana alerts and pushes them to the phone.

- **URL**: `http://<pi-tailnet-ip>:3006`
- **Auth**: Admin user with app tokens for Grafana integration
- **Health check**: `GET /health` every 30 seconds
- **Log rotation**: 10MB max, 3 files

### Setting Up Grafana → Gotify

1. Create an app in Gotify web UI
2. Copy the app token
3. Set `GOTIFY_GRAFANA_TOKEN` in `~/.env`
4. Grafana alerting provisioning uses this token for the Gotify contact point

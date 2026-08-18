# Docker Services

Container inventory, compose files, volumes, and networking for all Docker services.

## Container Inventory

| Container | Image | Port | Network | Purpose |
|-----------|-------|------|---------|---------|
| pihole | pihole/pihole:latest | 53, 80 | host | DNS filtering |
| unbound | unbound-custom | 5335 | host | Recursive DNS |
| grafana | grafana/grafana:latest | 3001 | monitoring, gotify | Dashboards |
| prometheus | prom/prometheus:latest | 9090 | monitoring | Metrics |
| node_exporter | quay.io/prometheus/node-exporter | 9100 | monitoring | System metrics |
| smartctl_exporter | monitoring-smartctl_exporter | 8002 | monitoring | HDD health |
| bmp280_exporter | monitoring-bmp280_exporter | 8001 | monitoring | Temp/humidity/pressure |
| sds011_exporter | monitoring-sds011_exporter | 8000 | monitoring | Air quality |
| nas-samba | crazymax/samba:latest | 445 | host | SMB file share |
| nas-gui | filebrowser/filebrowser:latest | 8080 (localhost) | — | Web file manager |
| gotify | gotify/server:latest | 3006 | gotify | Push notifications |
| uptime-kuma | louislam/uptime-kuma:latest | 3005 | — | Uptime monitoring |
| github-mcp | mcp-services-github-mcp | 3003 | mcp-network | GitHub API |
| search-mcp | mcp-services-search-mcp | 3002 | mcp-network | Web search |
| mediamtx | 0b397348eccf | — | — | Media streaming |

## Docker Compose Files

### Monitoring Stack (`monitoring/docker-compose.yml`)

```yaml
services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    pid: host
    restart: unless-stopped
    ports:
      - "9100:9100"
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - './prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro'
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - './grafana/provisioning:/etc/grafana/provisioning:ro'
      - './grafana/dashboards:/var/lib/grafana/dashboards:ro'
    environment:
      - GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_USERS_DEFAULT_THEME=dark
      - GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH=/var/lib/grafana/dashboards/overview/nas-overview.json
      - GOTIFY_GRAFANA_TOKEN=${GOTIFY_GRAFANA_TOKEN}
      - TZ=Asia/Kolkata
    depends_on:
      - prometheus
    networks:
      - monitoring
      - gotify

  smartctl_exporter:
    build:
      context: .
      dockerfile: Dockerfile.smartctl
    container_name: smartctl_exporter
    restart: unless-stopped
    privileged: true
    volumes:
      - '/dev:/dev:ro'
    environment:
      - SMART_REFRESH_SECONDS=900
    expose:
      - "8002"
    networks:
      - monitoring

  sds011_exporter:
    build:
      context: .
      dockerfile: Dockerfile.sds011
    container_name: sds011_exporter
    restart: unless-stopped
    devices:
      - '/dev/ttyS0:/dev/ttyS0'
    networks:
      - monitoring

  bmp280_exporter:
    build:
      context: .
      dockerfile: Dockerfile.bmp280
    container_name: bmp280_exporter
    restart: unless-stopped
    devices:
      - '/dev/i2c-1:/dev/i2c-1'
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:

networks:
  monitoring:
    driver: bridge
  gotify:
    external: true
    name: gotify_default
```

### NAS (`homelab/nas/docker-compose.yml`)

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: nas-gui
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - /mnt/nas:/srv
      - ./database:/database
      - ./settings.json:/config/settings.json
    environment:
      - PUID=1000
      - PGID=1000

  samba:
    image: crazymax/samba:latest
    container_name: nas-samba
    network_mode: host
    restart: unless-stopped
    volumes:
      - /mnt/nas:/nas
      - ./samba-config:/data
    environment:
      - TZ=Asia/Kolkata
      - SAMBA_HOSTS_ALLOW=127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.0.0.0/8
```

### Pi-hole + Unbound (`docker/unbound/docker-compose.yml`)

```yaml
services:
  unbound:
    image: unbound-custom
    container_name: unbound
    restart: unless-stopped
    network_mode: host

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    network_mode: host
    depends_on:
      - unbound
    environment:
      - TZ=Asia/Kolkata
      - DNSMASQ_USER=pihole
      - FTL_CMD=no-daemon
      - PIHOLE_DNS_=127.0.0.1#5335
      - DNSSEC=true
    volumes:
      - /home/bura/docker/pihole/etc-pihole:/etc/pihole
      - /home/bura/docker/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
```

### Gotify (`gotify/docker-compose.yml`)

```yaml
services:
  gotify:
    image: gotify/server:latest
    container_name: gotify
    restart: unless-stopped
    ports:
      - "3006:80"
    environment:
      - GOTIFY_DEFAULTUSER_NAME=admin
      - GOTIFY_DEFAULTUSER_PASS=${GOTIFY_ADMIN_PASSWORD}
      - GOTIFY_SERVER_PORT=80
      - TZ=UTC
    volumes:
      - gotify_data:/app/data

volumes:
  gotify_data:
```

### Uptime Kuma (`uptime-kuma/docker-compose.yml`)

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3005:3001"
    volumes:
      - uptime_kuma_data:/app/data

volumes:
  uptime_kuma_data:
```

### MCP Services (`mcp-services/docker-compose.yml`)

```yaml
services:
  github-mcp:
    build: ./github-mcp
    container_name: github-mcp
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    ports:
      - "3003:3001"
    restart: unless-stopped
    networks:
      - mcp-network

  search-mcp:
    build: ./search-mcp
    container_name: search-mcp
    ports:
      - "3002:3002"
    restart: unless-stopped
    networks:
      - mcp-network

networks:
  mcp-network:
    driver: bridge
```

## Docker Volumes

Named volumes for persistent data:

| Volume | Container | Purpose |
|--------|-----------|---------|
| `prometheus_data` | prometheus | Metrics database (30d retention) |
| `grafana_data` | grafana | Dashboards, settings, alerting |
| `gotify_data` | gotify | Push notification history |
| `uptime_kuma_data` | uptime-kuma | Uptime check history |
| `pi_airflow_*` | airflow | Airflow project (final year) |

## Docker Networks

| Network | Driver | Containers | Purpose |
|---------|--------|------------|---------|
| monitoring | bridge | prometheus, grafana, exporters | Monitoring stack |
| gotify | bridge (external) | gotify, grafana | Alert delivery |
| mcp-network | bridge | github-mcp, search-mcp | MCP services |
| host | host | pihole, unbound, samba | Direct port binding |

## Resource Usage

Current Docker resource footprint:

- **Containers**: 15 running
- **Images**: ~10 unique images
- **Volumes**: 14 named volumes
- **Networks**: 4 custom bridge networks

## Managing Containers

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs
docker logs -f <container-name>

# Restart a service
docker restart <container-name>

# Update a service
docker compose pull && docker compose up -d

# Check resource usage
docker stats --no-stream
```

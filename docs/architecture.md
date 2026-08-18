# Architecture

System design, data flow, and network topology for the homelab.

## System Overview

The homelab is built around a Raspberry Pi 4 that acts as the central hub. It connects to Xiaomi streaming devices (Mi TV, Mi Box) over a Tailscale mesh network, providing DNS filtering, monitoring, file sharing, and remote management.

### Design Principles

1. **Zero-trust networking** — Tailscale WireGuard mesh, no port forwarding
2. **Ad-blocking at the DNS level** — Pi-hole blocks ads for all devices
3. **Local-first** — All services self-hosted, no cloud dependencies
4. **Phone-managed** — Everything controllable from an Android phone via SSH + opencode
5. **Minimal attack surface** — Only necessary ports exposed, services behind Tailscale

## Data Flow

### DNS Resolution

```
Any device on tailnet
    │
    ▼
Pi-hole (port 53)
    │
    ├── Check against ad-block lists (gravity)
    │   ├── BLOCKED → return 0.0.0.0 (sinkhole)
    │   └── ALLOWED → forward query
    │
    ▼
Unbound (port 5335)
    │
    ├── Recursive resolution
    ├── DNSSEC validation
    ├── Cache results
    │
    ▼
Root DNS servers (direct, no forwarder)
```

### Device Management (Phone → Device)

```
Android Phone
    │
    ├── SSH client (Termux / JuiceSSH / etc.)
    │
    ▼
Raspberry Pi (SSH on port 22)
    │
    ├── opencode CLI
    │
    ▼
ADB over Tailscale (TCP port 5555)
    │
    ├── Mi TV (package management, settings, logs)
    └── Mi Box (package management, settings, logs)
```

### Monitoring Pipeline

```
Sensors / System
    │
    ├── BMP280 (I2C) → bmp280_exporter (:8001) → Prometheus
    ├── SDS011 (UART) → sds011_exporter (:8000) → Prometheus
    ├── SMART (USB-SATA) → smartctl_exporter (:8002) → Prometheus
    └── Node metrics → node_exporter (:9100) → Prometheus
                                              │
                                              ▼
                                        Grafana (:3001)
                                              │
                                              ├── Dashboards
                                              └── Alerts → Gotify (:3006) → Phone push
```

### File Sharing

```
Raspberry Pi
    │
    ├── /mnt/nas (460GB Seagate HDD)
    │   │
    │   ├── Samba (port 445) — SMB access from any device
    │   │   └── Windows/Mac/Linux/Android clients
    │   │
    │   └── FileBrowser (:8080) — Web-based file manager
    │       └── Access via browser on phone/laptop
    │
    └── HDD Power Management
        └── hdparm spindown after 120s idle
```

## Network Architecture

### Local Network (192.168.1.0/24)

```
Router (Gateway)
    │
    ├── Raspberry Pi (Ethernet + WiFi dual-homed)
    │   ├── eth0: 192.168.1.x (primary)
    │   └── wlan0: 192.168.1.x (WiFi backup)
    │
    ├── Mi TV (WiFi)
    ├── Mi Box (WiFi)
    └── Phone (WiFi)
```

### Tailscale Overlay (100.x.x.x)

```
Tailscale Coordination Server
    │
    ├── bura (Pi)           — 100.111.13.58
    ├── living-room-tv (TV) — 100.97.238.24
    ├── mibox4 (Mi Box)     — 100.94.39.98
    ├── s-s22 (Phone)       — 100.72.140.96
    └── ... (other devices)
```

### Firewall Rules

The Pi runs UFW with strict rules:

- **Allowed**: SSH (22), DNS (53), HTTP (80), Tailscale traffic
- **Docker bridges**: Only ports 53 and 5335 allowed through Docker bridges
- **Blocked**: Everything else from external networks
- **Tailscale**: All internal Tailnet traffic allowed

## Docker Network Architecture

Each Docker stack runs on its own bridge network for isolation:

```
Pi Host
    │
    ├── monitoring network (172.x.x.x)
    │   ├── prometheus, grafana, node_exporter, exporters
    │   └── gotify network (cross-linked for alerts)
    │
    ├── pihole/unbound (host networking)
    │   └── Direct port binding for DNS performance
    │
    ├── nas network
    │   ├── samba (host networking for SMB broadcast)
    │   └── filebrowser (localhost only)
    │
    └── mcp-network
        ├── github-mcp
        └── search-mcp
```

## Boot Configuration

The Pi uses a custom `/boot/firmware/config.txt` with:

- **CPU overclock**: 2.0GHz (arm_freq=2000, over_voltage=6)
- **GPU memory**: 76MB (VideoCore VI)
- **SPI display**: Waveshare 3.5" ILI9486 (rotated 90°)
- **HDMI forced**: 1080p60 output
- **64-bit mode**: arm_64bit=1
- **I2C + SPI enabled**: For sensor hardware
- **UART enabled**: For SDS011 air quality sensor
- **DRM VC4**: KMS V3D graphics driver
- **ZRAM swap**: 2GB compressed RAM swap

## Storage Layout

```
/dev/sda (128GB SSD - USB boot)
    ├── /dev/sda1 (512MB) → /boot/firmware
    └── /dev/sda2 (111GB) → / (root filesystem)

/dev/sdb (460GB Seagate HDD - USB)
    └── /dev/sdb1 (458GB) → /mnt/nas (Samba + FileBrowser)

zram0 (2GB) → [SWAP] (compressed RAM swap)
```

### HDD Power Management

The Seagate HDD uses `hdparm` for power management:

- **APM level**: 127 (balanced performance/power)
- **Spindown**: 120 seconds of idle
- **Service**: `hdd-powermanage.service` (runs before NAS services)
- **SMART monitoring**: Smartctl exporter reads disk health every 15 minutes without waking sleeping drives

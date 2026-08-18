# Homelab

A self-hosted home lab built on a Raspberry Pi 4 with Xiaomi device integration, running DNS, monitoring, file sharing, and smart home services — all accessible from a phone via Tailscale mesh networking and `opencode` CLI.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Hardware](#hardware)
- [Network Topology](#network-topology)
- [Services](#services)
- [Documentation](#documentation)
- [Quick Start](#quick-start)
- [License](#license)

---

## Overview

This homelab connects a **Raspberry Pi 4**, a **Xiaomi Mi TV**, and a **Xiaomi Mi Box 4** over a private **Tailscale** mesh network. The Raspberry Pi runs Pi-hole DNS, Prometheus/Grafana monitoring, a Samba file share, and environmental sensors — all managed from an Android phone using `opencode` CLI over SSH.

### What This Covers

| Area | Details |
|------|---------|
| **Device debloating** | 30+ packages disabled on Mi TV and Mi Box (ads, telemetry, spyware) |
| **DNS filtering** | Pi-hole + Unbound recursive DNS, ad-blocking across all devices |
| **Monitoring** | Prometheus + Grafana with CPU, RAM, disk, SMART, temperature, air quality |
| **File sharing** | Samba NAS with 460GB HDD, FileBrowser web UI |
| **Networking** | Tailscale mesh with always-on VPN, ADB over Tailnet |
| **Remote access** | Phone → SSH → opencode → control everything |
| **Performance** | Animation off, GPU rendering, background limits on Mi Box |
| **Power management** | TV phantom power cycling fix (CEC, ARC, idle timers) |

---

## Architecture

```
                              ┌─────────────────┐
                              │     INTERNET     │
                              └────────┬────────┘
                                       │
                         ┌─────────────▼─────────────┐
                         │     Tailscale Tailnet      │
                         │   (encrypted mesh network) │
                         └──┬──────────┬──────────┬──┘
                            │          │          │
                 ┌──────────▼──┐  ┌────▼────┐  ┌──▼──────────┐
                 │ Raspberry Pi │  │  Mi TV  │  │  Mi Box 4   │
                 │   (hub)      │  │         │  │             │
                 └──────┬───────┘  └────┬────┘  └──────┬──────┘
                        │               │               │
           ┌────────────┼───────────────┼───────────────┤
           │            │               │               │
     ┌─────▼─────┐ ┌───▼────┐   ┌─────▼─────┐  ┌─────▼─────┐
     │  Pi-hole  │ │Grafana │   │ SmartTube  │  │ Stremio   │
     │  +DNS     │ │+Prom   │   │(ad-free    │  │ +Torrentio│
     │  :53,:80  │ │:3001   │   │ YouTube)   │  │           │
     └───────────┘ │:9090   │   └───────────┘  └───────────┘
                   └────────┘
           │
     ┌─────▼──────────────────────┐
     │  Docker Services           │
     │  ├── Gotify    (alerts)    │
     │  ├── Uptime Kuma (uptime)  │
     │  ├── Samba NAS (files)     │
     │  ├── FileBrowser (web UI)  │
     │  ├── MCP Services          │
     │  └── Sunshine  (streaming) │
     └────────────────────────────┘

     ┌─────────────────────────────────────────┐
     │  Sensors (I2C / Serial)                 │
     │  ├── BMP280 (temperature, humidity,     │
     │  │         pressure) via I2C            │
     │  ├── SDS011 (PM2.5/PM10 air quality)   │
     │  │         via UART                     │
     │  └── SMART (HDD health via USB-SATA)   │
     └─────────────────────────────────────────┘

     ┌─────────────────────────────────────────┐
     │  Phone (Android)                        │
     │  └── Termux / SSH client                │
     │       └── SSH over Tailscale            │
     │            └── opencode CLI              │
     │                 └── adb connect          │
     │                      (to TV / Mi Box)   │
     └─────────────────────────────────────────┘
```

### How Phone Access Works

```
Phone ──Tailscale──> Raspberry Pi ──Tailscale──> Mi TV / Mi Box
         SSH              │                          │
                          └── opencode CLI            │
                               └── adb shell ────────┘
```

1. SSH into the Raspberry Pi from your phone (via Tailscale or local network)
2. Run `opencode` — an interactive CLI for managing the homelab
3. opencode uses `adb connect <tailnet-ip>:5555` to control Mi TV and Mi Box remotely
4. All commands run from the Pi, all devices reachable over the encrypted mesh

---

## Hardware

### Raspberry Pi 4 Model B

| Spec | Value |
|------|-------|
| Model | Raspberry Pi 4 Model B Rev 1.5 |
| SoC | Broadcom BCM2711 |
| CPU | 4x Cortex-A72 @ 2.0GHz (overclocked) |
| RAM | 8GB LPDDR4 |
| Storage | 128GB SSD (USB-SATA) + 460GB Seagate HDD (USB-SATA) |
| GPU | VideoCore VI, 76MB dedicated |
| Display | Waveshare 3.5" ILI9486 SPI + HDMI (1920x1080) |
| Network | Gigabit Ethernet + WiFi 5GHz (802.11ac) |
| Bluetooth | 5.0 BLE |
| Sensors | BMP280 (I2C), SDS011 (UART) |
| OS | Debian 13 (trixie), arm64 |
| Kernel | 6.18.39+rpt-rpi-v8 |

### Mi TV (MiTV-MOOQ0)

| Spec | Value |
|------|-------|
| SoC | MediaTek MT7632 |
| CPU | 4x Cortex-A55 @ 1.5GHz |
| GPU | Mali-G52 |
| RAM | 2GB |
| Android | 10 |
| Display | 1920x1080 |
| DRM | Widevine CDM (Netflix certified) |

### Mi Box 4 (MIBOX4)

| Spec | Value |
|------|-------|
| SoC | Amlogic S905L |
| CPU | 4x Cortex-A53 @ 1.5GHz |
| GPU | Mali-450 |
| RAM | 2GB |
| Android | 9 |
| Storage | 5GB `/data` (1.2GB `/system`, root needed to free) |
| WiFi | 5GHz (433Mbps) |
| DRM | Widevine CDM (Netflix certified) |

---

## Network Topology

### Local Network

| Device | Interface | Role |
|--------|-----------|------|
| Router | Gateway | DHCP, internet |
| Raspberry Pi | Ethernet + WiFi (dual-homed) | DNS, NAS, monitoring hub |
| Mi TV | WiFi | Streaming |
| Mi Box | WiFi | Streaming |
| Phone | WiFi | Remote control via SSH |

### Tailscale Mesh

All devices join a single Tailscale tailnet under the `burakamal13@` account. Each device gets a stable `100.x.x.x` address that works from anywhere — no port forwarding, no dynamic DNS.

| Node | Type | Tailnet IP | Always-On VPN |
|------|------|------------|---------------|
| Raspberry Pi (`bura`) | Linux | `100.111.13.58` | N/A (always on) |
| Living Room TV | Android 10 | `100.97.238.24` | Yes |
| Mi Box 4 | Android 9 | `100.94.39.98` | Yes |
| Phone (S22) | Android | dynamic | Yes |
| Other devices | Various | Various | Varies |

### DNS Flow

```
Client → Pi-hole (:53) → Unbound (:5335) → Root DNS
              │
              └── Ad blocking (gravity list)
```

- Pi-hole listens on port 53 (DNS) and port 80 (web UI)
- Unbound provides recursive resolution (no upstream dependency)
- All Tailnet devices use Pi-hole as their nameserver via Tailscale DNS settings

---

## Services

### Core Infrastructure

| Service | Port | Description |
|---------|------|-------------|
| Pi-hole | 53, 80 | DNS filtering + web admin |
| Unbound | 5335 | Recursive DNS resolver |
| SSH | 22 | Remote shell access |
| ADB | 5555 | Android device control |

### Monitoring Stack

| Service | Port | Description |
|---------|------|-------------|
| Grafana | 3001 | Dashboards, alerting |
| Prometheus | 9090 | Metrics collection (30d retention) |
| Node Exporter | 9100 | CPU, RAM, disk, network metrics |
| Smartctl Exporter | 8002 | HDD health (SMART data) |
| BMP280 Exporter | 8001 | Temperature, humidity, pressure |
| SDS011 Exporter | 8000 | PM2.5/PM10 air quality |

### File Sharing

| Service | Port | Description |
|---------|------|-------------|
| Samba NAS | 445 | SMB file share (460GB HDD) |
| FileBrowser | 8080 | Web-based file manager |

### Alerting & Uptime

| Service | Port | Description |
|---------|------|-------------|
| Gotify | 3006 | Push notifications (Grafana alerts) |
| Uptime Kuma | 3005 | Service uptime monitoring |

### Remote Access

| Service | Port | Description |
|---------|------|-------------|
| AnyDesk | — | Remote desktop (unattended) |
| VNC | 5999 | Virtual display access |
| xRDP | 3389 | RDP protocol access |
| Sunshine | — | Game streaming (Moonlight client) |

### MCP Services

| Service | Port | Description |
|---------|------|-------------|
| GitHub MCP | 3003 | GitHub API integration |
| Search MCP | 3002 | Web search integration |

---

## Documentation

Detailed documentation is organized in the [`docs/`](docs/) folder:

- **[Architecture](docs/architecture.md)** — System design, data flow, network topology
- **[Raspberry Pi](docs/raspberry-pi.md)** — Hardware, boot config, services, sensors
- **[Networking](docs/networking.md)** — Tailscale setup, DNS, Pi-hole, Unbound
- **[Mi TV Debloat](docs/devices/mi-tv.md)** — Package disabling, SmartTube, power fix
- **[Mi Box Debloat](docs/devices/mi-box.md)** — Package disabling, performance, storage cleanup
- **[Docker Services](docs/docker.md)** — Container inventory, compose files, volumes
- **[Monitoring](docs/monitoring.md)** — Grafana dashboards, Prometheus config, sensors
- **[NAS](docs/nas.md)** — Samba config, FileBrowser, HDD power management
- **[Remote Access](docs/remote-access.md)** — Phone access, SSH, opencode, AnyDesk, VNC, xRDP
- **[Commands Reference](docs/commands.md)** — Quick reference for all ADB, Docker, system commands

---

## Quick Start

### Prerequisites

- Raspberry Pi 4 (8GB recommended)
- Xiaomi Mi TV or Mi Box with ADB enabled
- Tailscale account
- Android phone with SSH client (Termux recommended)

### 1. Flash Raspberry Pi

```bash
# Flash Debian 13 (trixie) arm64 to SSD
# See docs/raspberry-pi.md for boot config
```

### 2. Install Tailscale

```bash
# On Pi
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# On Mi TV / Mi Box (via ADB)
adb connect <device-ip>:5555
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1
```

### 3. Deploy Docker Services

```bash
# Pi-hole + Unbound
cd docker/unbound && docker compose up -d

# Monitoring stack
cd monitoring && docker compose up -d

# NAS
cd homelab/nas && docker compose up -d

# Gotify + Uptime Kuma
cd gotify && docker compose up -d
cd uptime-kuma && docker compose up -d
```

### 4. Connect to Devices

```bash
# From your phone
ssh bura@<pi-tailnet-ip>

# Run opencode
opencode

# Connect to Mi TV
adb connect <tv-tailnet-ip>:5555
```

---

## License

MIT

# Raspberry Pi

Detailed hardware, boot configuration, system services, and sensor setup for the central hub.

## Hardware Specifications

| Component | Details |
|-----------|---------|
| Model | Raspberry Pi 4 Model B Rev 1.5 |
| SoC | Broadcom BCM2711 |
| CPU | 4x ARM Cortex-A72 @ 2.0GHz (overclocked) |
| RAM | 8GB LPDDR4 |
| Boot | 128GB SSD via USB-SATA (SanDisk) |
| Storage | 460GB Seagate ST9500325AS via USB-SATA |
| GPU | VideoCore VI (76MB dedicated) |
| Display | Waveshare 3.5" SPI (ILI9486) + HDMI (1920x1080) |
| Network | Gigabit Ethernet + WiFi 5GHz (802.11ac) |
| Bluetooth | 5.0 BLE |
| Sensors | BMP280 (I2C), SDS011 (UART) |
| OS | Debian 13 (trixie) arm64 |
| Kernel | 6.18.39+rpt-rpi-v8 |

## Boot Configuration

### `/boot/firmware/config.txt`

```ini
# Hardware interfaces
dtparam=i2c_arm=on
dtparam=spi=on
dtparam=audio=on

# Graphics
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Boot
auto_initramfs=1
arm_64bit=1

# Display
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=82
hdmi_drive=2

# Performance
arm_freq=2000
over_voltage=6
force_turbo=0
arm_boost=1

# Waveshare 3.5" SPI display
dtoverlay=fbtft,spi0-0,ili9486,bgr,rotate=90,dc_pin=24,reset_pin=25,led_pin=18,speed=48000000

# UART (for SDS011 sensor)
enable_uart=1
```

### `/boot/firmware/cmdline.txt`

```
console=tty1 root=PARTUUID=3e6d1977-02 rootfstype=ext4 fsck.repair=yes rootwait quiet splash plymouth.ignore-serial-consoles cfg80211.ieee80211_regdom=IN
```

### Key Settings Explained

| Setting | Value | Purpose |
|---------|-------|---------|
| `arm_freq` | 2000 | CPU overclocked from 1.5GHz to 2.0GHz |
| `over_voltage` | 6 | Required for stable overclock |
| `gpu_mem` | 76MB | Dedicated GPU memory for VideoCore VI |
| `arm_64bit` | 1 | 64-bit kernel and userspace |
| `dtoverlay=vc4-kms-v3d` | — | DRM/KMS graphics driver |
| `dtoverlay=fbtft` | — | SPI framebuffer for Waveshare display |
| `enable_uart` | 1 | UART for SDS011 air quality sensor |
| `cfg80211.ieee80211_regdom` | IN | WiFi regulatory domain (India) |

## Storage

### Disk Layout

| Device | Size | Mount | Purpose |
|--------|------|-------|---------|
| `/dev/sda` | 128GB SSD | — | Boot + root |
| `/dev/sda1` | 512MB | `/boot/firmware` | Boot partition |
| `/dev/sda2` | 111GB | `/` | Root filesystem |
| `/dev/sdb` | 460GB HDD | `/mnt/nas` | NAS file share |
| `zram0` | 2GB | `[SWAP]` | Compressed RAM swap |

### Current Usage

```
/          111GB  42GB used  (41%)
/mnt/nas   460GB  18GB used  ( 5%)
```

## System Services

### Running Services

| Service | Type | Description |
|---------|------|-------------|
| `tailscaled` | System | Tailscale mesh VPN agent |
| `docker` | System | Container runtime |
| `ssh` | System | SSH server |
| `bluetooth` | System | Bluetooth stack |
| `NetworkManager` | System | Network management |
| `pihole-FTL` | Docker | DNS server + ad blocking |
| `unbound` | Docker | Recursive DNS resolver |
| `grafana` | Docker | Monitoring dashboards |
| `prometheus` | Docker | Metrics collection |
| `node_exporter` | Docker | System metrics exporter |
| `smartctl_exporter` | Docker | HDD SMART health exporter |
| `bmp280_exporter` | Docker | Temperature/humidity/pressure sensor |
| `sds011_exporter` | Docker | Air quality (PM2.5/PM10) sensor |
| `nas-samba` | Docker | SMB file share |
| `nas-gui` | Docker | FileBrowser web UI |
| `gotify` | Docker | Push notification server |
| `uptime-kuma` | Docker | Uptime monitoring |
| `github-mcp` | Docker | GitHub API MCP server |
| `search-mcp` | Docker | Web search MCP server |
| `systemd-dashboard` | Systemd | Web UI for service management |
| `pi-nas-docs` | Systemd | Documentation HTTP server |
| `anydesk` | System | Remote desktop access |
| `vncserver-virtuald` | System | VNC virtual display |
| `xrdp` | System | RDP protocol access |
| `cups` | System | Print server |
| `avahi-daemon` | System | mDNS/DNS-SD (Bonjour) |
| `smartmontools` | System | Disk health monitoring daemon |

### Custom Systemd Services

#### `systemd-dashboard.service`

Web UI for managing systemd services with smart grouping.

```ini
[Unit]
Description=Systemd Dashboard with Smart Grouping
After=network.target tailscaled.service

[Service]
Type=simple
User=bura
WorkingDirectory=/home/bura/systemd-dashboard
ExecStart=/home/bura/.nvm/versions/node/v22.22.2/bin/node server.js
Restart=always
RestartSec=10
Environment=PORT=3004
Environment=NODE_ENV=production
```

#### `pi-nas-docs.service`

Simple HTTP server for hosting documentation.

```ini
[Unit]
Description=Pi NAS Documentation Server
After=network.target

[Service]
Type=simple
User=bura
WorkingDirectory=/home/bura/docs
ExecStart=/usr/bin/python3 -m http.server 8081 --bind 127.0.0.1
Restart=always
RestartSec=3
```

#### `hdd-powermanage.service`

Manages HDD spin-down for power saving.

```ini
[Unit]
Description=HDD power management for Seagate ST9500325AS
After=local-fs.target
Before=nas-gui.service nas-samba.service

[Service]
Type=oneshot
ExecStartPre=/bin/sh -c 'while [ ! -e /dev/disk/by-id/ata-ST9500325AS_6VEHTME4 ]; do sleep 1; done'
ExecStart=/usr/sbin/hdparm -B 127 -S 120 /dev/disk/by-id/ata-ST9500325AS_6VEHTME4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

## Sensors

### BMP280 (Temperature, Humidity, Pressure)

- **Interface**: I2C (`/dev/i2c-1`)
- **Exporter**: Custom Python container (`bmp280_exporter`)
- **Metrics**: `bmp280_temperature_celsius`, `bmp280_humidity_percent`, `bmp280_pressure_hpa`
- **Scrape interval**: 60 seconds

### SDS011 (Air Quality)

- **Interface**: UART (`/dev/ttyS0`)
- **Exporter**: Custom Python container (`sds011_exporter`)
- **Metrics**: `sds011_pm25_ugm3`, `sds011_pm10_ugm3`
- **Scrape interval**: 60 seconds

### SMART (HDD Health)

- **Interface**: USB-SATA passthrough
- **Exporter**: Custom container (`smartctl_exporter`)
- **Metrics**: `smartctl_device_healthy`, temperature, power-on hours, reallocated sectors
- **Scrape interval**: 900 seconds (15 min) — avoids waking sleeping drives
- **Config**: `SMART_REFRESH_SECONDS=900`, `smartctl -n standby` to skip sleeping disks

## GPIO and Hardware Interfaces

| Interface | Device | Usage |
|-----------|--------|-------|
| I2C-1 | BMP280 sensor | Temperature, humidity, pressure |
| I2C-20 | Available | — |
| I2C-21 | Available | — |
| SPI0 | Waveshare display | 3.5" TFT framebuffer |
| UART0 | SDS011 sensor | Air quality PM2.5/PM10 |
| GPIO | Chip 0, Chip 1 | Available for expansion |

## Temperature

Current CPU temperature: ~42°C (idle)

The Pi runs cool under normal load. The overclock to 2.0GHz is stable with passive cooling. Under sustained load, temperatures may reach 60-70°C — still within safe operating range for the BCM2711.

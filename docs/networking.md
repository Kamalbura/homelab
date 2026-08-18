# Networking

Tailscale mesh networking, DNS resolution, Pi-hole ad-blocking, and Unbound recursive DNS.

## Tailscale

### Overview

Tailscale creates a WireGuard-encrypted mesh network between all devices. Each device gets a stable `100.x.x.x` IP that works from anywhere — no port forwarding, no dynamic DNS, no firewall rules to manage.

### Setup

#### Raspberry Pi

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

#### Android Devices (Mi TV, Mi Box)

1. Install Tailscale from Google Play or sideload APK
2. Sign in with your Tailscale account
3. Enable always-on VPN (see below)

### Always-On VPN (Critical for Boot Auto-Start)

Android 9/10 has a bug where `always_on_vpn_app` alone doesn't work at boot. The `VpnManagerService.startAlwaysOnVpn()` method in AOSP checks `mLockdown` as a gate — without it, the VPN never auto-starts.

```bash
adb connect <device-tailnet-ip>:5555

# Required: Set Tailscale as always-on VPN
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1

# Whitelist from battery optimization
adb shell dumpsys deviceidle whitelist +com.tailscale.ipn
adb shell appops set com.tailscale.ipn RUN_IN_BACKGROUND allow
adb shell appops set com.tailscale.ipn RUN_ANY_IN_BACKGROUND allow
```

**Without `always_on_vpn_lockdown=1`**, the `mLockdown` check in AOSP `VpnManagerService.java:1531` blocks the auto-start at boot. This is confirmed in Android 9 (Pie) and 10 source code.

### Verification

After reboot, verify Tailscale is connected:

```bash
# Check Tailscale status on device
adb shell dumpsys package com.tailscale.ipn | grep -i "always"

# Check from Pi
tailscale status
```

## DNS Architecture

### Pi-hole

Pi-hole acts as the network-wide DNS server, blocking ads and trackers at the DNS level.

| Setting | Value |
|---------|-------|
| Listen port | 53 (DNS), 80 (web UI) |
| Upstream DNS | Unbound (127.0.0.1:5335) |
| DNSSEC | Enabled |
| Blocking mode | Gravity (ad lists) |
| Timezone | Asia/Kolkata |

#### Docker Configuration

```yaml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    network_mode: host
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

#### Using Pi-hole as Tailnet DNS

Set Pi-hole as the nameserver in Tailscale admin console:

1. Go to [Tailscale admin DNS settings](https://login.tailscale.com/admin/dns)
2. Enable "Use Tailscale DNS"
3. Add `<pi-tailnet-ip>` as a nameserver
4. Optionally enable "Override local DNS" to force all devices through Pi-hole

### Unbound

Unbound provides recursive DNS resolution — it queries root servers directly instead of forwarding to a third-party resolver. This improves privacy and eliminates a single point of failure.

| Setting | Value |
|---------|-------|
| Listen port | 5335 |
| Protocol | DNS over UDP/TCP |
| DNSSEC | Enabled |
| Privacy | No forward logging |

#### Docker Configuration

```yaml
services:
  unbound:
    image: unbound-custom
    container_name: unbound
    restart: unless-stopped
    network_mode: host
```

### DNS Resolution Flow

```
Client query (e.g., example.com)
    │
    ▼
Pi-hole (:53)
    ├── Check gravity (ad lists)
    │   ├── Match → return 0.0.0.0 (blocked)
    │   └── No match → forward to upstream
    │
    ▼
Unbound (:5335)
    ├── Check cache
    │   ├── Hit → return cached result
    │   └── Miss → recursive resolution
    │
    ├── Query root servers
    ├── Query TLD servers
    ├── Query authoritative servers
    ├── Validate DNSSEC
    ├── Cache result
    │
    ▼
Return result to client
```

## Firewall (UFW)

The Pi uses UFW with strict rules:

```bash
# Allowed ports
ufw allow 22/tcp      # SSH
ufw allow 53/tcp      # DNS
ufw allow 53/udp      # DNS
ufw allow 80/tcp      # HTTP (Pi-hole web UI)

# Docker bridge access (restricted)
# Only ports 53 and 5335 allowed through Docker bridges

# Tailscale
# All internal Tailnet traffic allowed by default
```

## Port Summary

| Port | Service | Binding | Access |
|------|---------|---------|--------|
| 22 | SSH | 0.0.0.0 | Tailnet + local |
| 53 | Pi-hole DNS | 0.0.0.0 | Tailnet + local |
| 80 | Pi-hole Web UI | 0.0.0.0 | Tailnet + local |
| 445 | Samba NAS | 0.0.0.0 | Local network |
| 3001 | Grafana | 0.0.0.0 | Tailnet + local |
| 3002 | Search MCP | 0.0.0.0 | Tailnet + local |
| 3003 | GitHub MCP | 0.0.0.0 | Tailnet + local |
| 3004 | Systemd Dashboard | 0.0.0.0 | Tailnet + local |
| 3005 | Uptime Kuma | 0.0.0.0 | Tailnet + local |
| 3006 | Gotify | 0.0.0.0 | Tailnet + local |
| 3389 | xRDP | 0.0.0.0 | Tailnet + local |
| 5335 | Unbound | 0.0.0.0 | Tailnet + local |
| 5555 | ADB | 127.0.0.1 | Local only |
| 5999 | VNC | 0.0.0.0 | Tailnet + local |
| 8080 | FileBrowser | 127.0.0.1 | Local only |
| 8081 | Pi-NAS-Docs | 127.0.0.1 | Local only |
| 9090 | Prometheus | 0.0.0.0 | Tailnet + local |
| 9100 | Node Exporter | 0.0.0.0 | Tailnet + local |

# Remote Access

Phone access via SSH + opencode, AnyDesk, VNC, xRDP, and Sunshine game streaming.

## Phone Access (Primary Method)

### How It Works

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

### Setup

#### Step 1: Install SSH Client on Phone

Recommended: **Termux** (F-Droid/Play Store)

```bash
# In Termux
pkg install openssh
```

#### Step 2: SSH into Raspberry Pi

```bash
# From Termux
ssh bura@<pi-tailnet-ip>

# Or via local network
ssh bura@<pi-local-ip>
```

#### Step 3: Run opencode

```bash
opencode
```

opencode gives you an interactive CLI to manage the homelab — debloating devices, checking logs, managing Docker, etc.

#### Step 4: Connect to Android Devices

```bash
# From within opencode or directly
adb connect <tv-tailnet-ip>:5555
adb connect <mibox-tailnet-ip>:5555

# Verify
adb devices
```

### What You Can Do from Phone

- **Debloat devices**: Disable/enable packages, clear data
- **Manage settings**: Animation scales, idle timers, VPN config
- **View logs**: Logcat, dumpsys, system logs
- **Docker management**: Start/stop containers, view logs
- **Monitor**: Check Grafana, Prometheus, disk health
- **File management**: Access NAS via FileBrowser
- **DNS management**: Pi-hole admin, block/unblock domains

## AnyDesk

AnyDesk provides unattended remote desktop access to the Pi.

- **Service**: `anydesk.service` (runs as root)
- **Access**: Install AnyDesk on any device, enter the Pi's AnyDesk address
- **Use case**: Full desktop access when SSH isn't enough

### Usage

1. Install AnyDesk on your phone/laptop
2. Enter the Pi's AnyDesk address (shown in `anydesk --get-id`)
3. Accept the connection on the Pi (first time only)

## VNC

VNC provides virtual display access.

- **Service**: `vncserver-virtuald.service`
- **Port**: 5999
- **Type**: Virtual mode (no physical display required)

### Usage

```bash
# Connect from any VNC client
vnc://<pi-tailnet-ip>:5999
```

## xRDP

xRDP provides RDP protocol access (compatible with Microsoft Remote Desktop).

- **Service**: `xrdp.service` + `xrdp-sesman.service`
- **Port**: 3389
- **Protocol**: RDP (compatible with all RDP clients)

### Usage

1. Install Microsoft Remote Desktop (or any RDP client) on your phone/laptop
2. Connect to `<pi-tailnet-ip>:3389`
3. Login with Pi credentials

## Sunshine (Game Streaming)

Sunshine is a game streaming server compatible with Moonlight clients.

- **Container**: Built from `homelab/sunshine/`
- **Network**: Host mode
- **Devices**: `/dev/dri` (GPU), `/dev/uinput` (input)
- **Display**: Uses X11 display `:0`

### Usage

1. Install Moonlight on your phone/game console
2. Connect to `<pi-tailnet-ip>`
3. Stream desktop or games

### Requirements

- GPU access (`/dev/dri`)
- X11 display running (LightDM)
- Moonlight client app

## Remote Access Comparison

| Method | Protocol | Port | Use Case | Latency |
|--------|----------|------|----------|---------|
| SSH + opencode | SSH | 22 | CLI management, ADB | Low |
| AnyDesk | Proprietary | — | Full desktop access | Medium |
| VNC | RFB | 5999 | Virtual desktop | Medium |
| xRDP | RDP | 3389 | Windows-compatible remote desktop | Medium |
| Sunshine | HTTPS + Video | — | Game streaming | Low |

## Security Notes

- **SSH**: Key-based auth recommended, disable password auth
- **Tailscale**: All traffic encrypted via WireGuard
- **AnyDesk**: Unattended access — ensure strong password
- **VNC/xRDP**: Only accessible via Tailscale (not exposed to internet)
- **ADB**: Only listens on localhost (accessed via SSH tunnel)

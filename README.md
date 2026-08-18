# Homelab

Xiaomi device debloating, Tailscale mesh networking, Raspberry Pi home lab with Pi-hole DNS, Docker services, and remote phone access via opencode.

## Architecture

```
                        ┌─────────────────────────────────┐
                        │         INTERNET                 │
                        └──────────┬──────────────────────┘
                                   │
                        ┌──────────▼──────────────────────┐
                        │    Tailscale Tailnet (100.x.x)  │
                        │    burakamal13@                 │
                        └──┬───────────┬──────────┬──────┘
                           │           │          │
              ┌────────────▼──┐  ┌─────▼─────┐  ┌▼──────────────┐
              │  Raspberry Pi │  │   Mi TV    │  │   Mi Box 4    │
              │  (bura)       │  │ (MiTV-     │  │  (MIBOX4)     │
              │  100.111.13.58│  │  MOOQ0)    │  │  100.97.238.24│
              │               │  │ 100.97.    │  │               │
              │  linux/arm64  │  │  238.24    │  │  android 9    │
              └───────┬───────┘  └─────┬─────┘  └───────┬───────┘
                      │                │                 │
         ┌────────────┼────────────────┼─────────────────┤
         │            │                │                 │
    ┌────▼────┐  ┌────▼────┐   ┌──────▼──────┐  ┌──────▼──────┐
    │ Pi-hole │  │Unbound  │   │ SmartTube   │  │ Stremio     │
    │ :53/:80 │  │ :5335   │   │ (ad-free    │  │ +Torrentio  │
    │         │  │         │   │  YouTube)   │  │             │
    └─────────┘  └─────────┘   └─────────────┘  └─────────────┘
         │
    ┌────▼────────────────────────────┐
    │  Docker                         │
    │  ├── Grafana    (:3000)         │
    │  ├── Prometheus (:9090)         │
    │  └── Samba NAS  (:445)          │
    └─────────────────────────────────┘

    Phone (Android)
    └── opencode CLI ──SSH/Tailscale──> Raspberry Pi
                                        (controls all devices via ADB over Tailscale)
```

## Devices

| Device | Model | CPU | RAM | Android | Tailnet IP | Role |
|--------|-------|-----|-----|---------|------------|------|
| Raspberry Pi | Model B | ARM64 | 4GB | Linux (Debian) | `100.111.13.58` | DNS, monitoring, NAS, ADB hub |
| Mi TV | MiTV-MOOQ0 | MediaTek MT7632 (4x A55@1.5GHz) | 2GB | Android 10 | `100.97.238.24` | Streaming, SmartTube |
| Mi Box 4 | MIBOX4 | Amlogic S905L (4x A53@1.5GHz) | 2GB | Android 9 | dynamic | Streaming, Stremio, Netflix |

## Phone Access (opencode)

Everything is controlled from an Android phone via `opencode` CLI running on the Raspberry Pi.

### How it works

```
Phone (Android)
  └── Termux / SSH client
       └── SSH ──Tailscale──> Raspberry Pi (100.111.13.58)
            └── opencode CLI
                 └── adb shell ──Tailscale──> Mi TV / Mi Box
```

1. Install **opencode** on the Raspberry Pi
2. SSH into the Pi from your phone (via Tailscale or local network)
3. Run `opencode` — it gives you an interactive CLI to manage everything
4. opencode uses `adb connect <tailnet-ip>:5555` to control Mi TV and Mi Box remotely
5. All commands run from the Pi, all devices reachable over Tailscale mesh

### Quick connect from phone

```bash
# From Termux or any SSH client on your phone:
ssh bura@100.111.13.58

# Then run opencode:
opencode

# Connect to devices:
adb connect 100.97.238.24:5555    # Mi TV
adb connect 100.97.238.24:5555    # Mi Box (check tailnet IP)
```

## Tailscale Setup

### Install on Raspberry Pi

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### Install on Mi TV / Mi Box

1. Install Tailscale from Google Play or sideload APK
2. Sign in with your Tailscale account (`burakamal13@`)
3. Enable always-on VPN (critical for auto-start on boot):

```bash
# Connect via ADB
adb connect <device-ip>:5555

# Set Tailscale as always-on VPN
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1

# Whitelist from battery optimization
adb shell dumpsys deviceidle whitelist +com.tailscale.ipn
adb shell appops set com.tailscale.ipn RUN_IN_BACKGROUND allow
adb shell appops set com.tailscale.ipn RUN_ANY_IN_BACKGROUND allow
```

### Why `always_on_vpn_lockdown=1` is required

Android 9/10 has a bug where `always_on_vpn_app` alone doesn't work at boot. The `VpnManagerService.startAlwaysOnVpn()` method checks `mLockdown` as a gate — without it, the VPN never auto-starts on boot. This is confirmed in AOSP source code.

### ADB over Tailscale

```bash
# Enable TCP/IP ADB on devices (one-time, via USB or already connected)
adb tcpip 5555

# Connect from Pi over Tailscale
adb connect 100.97.238.24:5555

# Verify
adb devices
```

## Mi TV Debloat (MiTV-MOOQ0)

### Packages disabled

```bash
# PatchWall (Xiaomi launcher/ads)
adb shell pm disable-user --user 0 com.mitv.tvhome.atv
adb shell pm disable-user --user 0 com.mitv.tvhome.michannel

# Xiaomi telemetry & analytics
adb shell pm disable-user --user 0 com.miui.tv.analytics
adb shell pm disable-user --user 0 com.xiaomi.statistic
adb shell pm disable-user --user 0 com.xiaomi.mitv.updateservice

# Region-specific apps (India)
adb shell pm disable-user --user 0 com.haier.haierhtv
adb shell pm disable-user --user 0 com.airtel.stb.live
adb shell pm disable-user --user 0 com.sonyliv.mitv
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 in.yuvaa.hungama.mitv
adb shell pm disable-user --user 0 tv.zee5/mitv
adb shell pm disable-user --user 0 com.jio.hotspot
adb shell pm disable-user --user 0 com.aha.ntv
adb shell pm disable-user --user 0 com.dth.sunnxt

# Google bloat
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos

# Other
adb shell pm disable-user --user 0 com.mediatek.tvlauncher
```

### SmartTube installed

```bash
# Sideload SmartTube (ad-free YouTube for Android TV)
adb install SmartTube32.10_armeabi-v7a.apk
# Package: org.smarttube.stable
```

## Mi Box 4 Debloat (MIBOX4)

### Packages disabled

```bash
# PatchWall
adb shell pm disable-user --user 0 com.mitv.tvhome.atv
adb shell pm disable-user --user 0 com.mitv.tvhome.michannel

# Xiaomi telemetry
adb shell pm disable-user --user 0 com.miui.tv.analytics
adb shell pm disable-user --user 0 com.xiaomi.statistic
adb shell pm disable-user --user 0 com.xiaomi.mitv.updateservice

# Alphonso ACR spyware (audio recording)
adb shell pm disable-user --user 0 tv.alphonso.alphonso_eula

# Region apps
adb shell pm disable-user --user 0 in.jio.jiotvplay
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 com.dth.sunnxt

# Google bloat
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos

# Additional packages (19 more)
# See full list in this repo: mibox-debloat.txt
```

### Bulk clear + uninstall disabled apps

```bash
# Clear data from all disabled apps
for pkg in $(pm list packages -d | sed 's/package://'); do pm clear "$pkg" 2>/dev/null; done

# Uninstall disabled apps for current user (frees storage)
for pkg in $(pm list packages -d | sed 's/package://'); do pm uninstall -k --user 0 "$pkg" 2>/dev/null; done

# Trim caches
pm trim-caches 5G
```

**Result**: Freed **1.1GB** on `/data` (862MB → 1.9GB free, 86% → 62% used)

### Mi Box Performance Tweaks

```bash
# Disable all animations
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0

# GPU rendering
adb shell setprop debug.hwui.renderer skia
adb shell setprop debug.egl.hw 1
adb shell setprop debug.sf.hw 1

# Background process limit
adb shell settings put global background_process_limit 2

# Disable Doze
adb shell dumpsys deviceidle disable all

# Screen timeout max + stay on
adb shell settings put system screen_off_timeout 2147483647
adb shell svc power stayon true

# WiFi sleep policy never
adb shell settings put global wifi_sleep_policy 2

# Developer options
adb shell settings put global development_settings_enabled 1
```

## Mi Box Storage Cleanup

The Mi Box 4 has only 5GB `/data` and 1.2GB `/system` (root required to free system). Without root:

```bash
# Check storage
adb shell df -h /data
adb shell df -h /

# Clear app caches
adb shell pm trim-caches 5G

# Clear disabled app data
for pkg in $(pm list packages -d | sed 's/package://'); do
  pm clear "$pkg" 2>/dev/null
done

# Uninstall disabled apps for user
for pkg in $(pm list packages -d | sed 's/package://'); do
  pm uninstall -k --user 0 "$pkg" 2>/dev/null
done
```

## TV Power Cycling Fix

The TV was turning off/on randomly with no HDMI device connected. Root cause: phantom HDMI audio events + aggressive idle timer + Chromecast CEC standby cycling.

### Fixes applied

```bash
# Disable ARC control (was generating phantom audio events)
adb shell settings put global hdmi_arc_control_enabled 0

# Disable CEC auto-off and auto-wakeup
adb shell settings put global hdmi_control_auto_device_off_enabled 0
adb shell settings put global hdmi_control_auto_wakeup_enabled 0

# Disable power button sleep
adb shell settings put global power_off_put_device_to_sleep 0

# Extend idle timer (was: inactive=10min, idle_after=1sec!)
adb shell settings put global device_idle_constants 'inactive_to=1800000,idle_after_inactive_to=600000,locating_to=1000,idle_to=28800000,max_idle_to=86400000,idle_factor=2,light_after_inactive_to=1800000'

# Disable sleep timer
adb shell settings put global tv_timer_sleep_timer_entry_values 0
adb shell settings put global sleep_timer_remain_time 0

# Disable PatchWall
adb shell settings put global patchwall_enable false
adb shell settings put global set_patchwall_default 0

# Screen timeout 10 minutes
adb shell settings put system screen_off_timeout 600000

# Force stop Chromecast (stops CEC standby cycling)
adb shell am force-stop com.google.android.apps.mediashell
```

### Why this happened

- `idle_after_inactive_to=1000` meant the TV went idle **1 second** after last activity
- Chromecast was generating `CecStandby.OnToStandby` / `StandbyToOn` events in a loop
- HDMI audio subsystem reported phantom TX connect/disconnect even with no device connected
- `power_off_put_device_to_sleep=1` meant the power button put the TV to deep sleep

## Raspberry Pi Services

### Pi-hole + Unbound (DNS)

```
Pi-hole (:53, :80) → Unbound (:5335) → Root DNS servers
```

- Pi-hole blocks ads network-wide
- Unbound provides recursive DNS (no upstream dependency)
- All devices on tailnet use Pi-hole as DNS

### Docker Services

```bash
# Grafana (monitoring dashboards)
docker run -d -p 3000:3000 grafana/grafana

# Prometheus (metrics collection)
docker run -d -p 9090:9090 prom/prometheus

# Samba NAS (file sharing)
docker run -d -p 445:445 dperson/samba
```

## Commands Reference

### ADB Device Management

```bash
# List connected devices
adb devices

# Connect over network
adb connect <ip>:5555

# Disconnect
adb disconnect <ip>:5555

# Reboot device
adb -s <ip>:5555 reboot

# Shell into device
adb -s <ip>:5555 shell
```

### Package Management

```bash
# List all packages
adb shell pm list packages

# List disabled packages
adb shell pm list packages -d

# Disable a package (user level, reversible)
adb shell pm disable-user --user 0 <package>

# Enable a package
adb shell pm enable <package>

# Clear app data
adb shell pm clear <package>

# Uninstall for current user (frees storage)
adb shell pm uninstall -k --user 0 <package>
```

### Settings

```bash
# List all settings
adb shell settings list global
adb shell settings list system
adb shell settings list secure

# Get a setting
adb shell settings get global <key>

# Set a setting
adb shell settings put global <key> <value>
```

### Diagnostics

```bash
# Logcat (device logs)
adb shell logcat -d | grep <pattern>

# Dumpsys (service info)
adb shell dumpsys power
adb shell dumpsys display
adb shell dumpsys audio
adb shell dumpsys battery
adb shell dumpsys package <package>

# Process info
adb shell top -b -n 1
adb shell ps -A | grep <process>

# Storage
adb shell df -h
```

## License

MIT

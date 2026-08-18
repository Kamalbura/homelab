# Mi Box Debloat (MIBOX4)

Debloating, performance optimization, and storage cleanup for the Xiaomi Mi Box 4.

## Device Specs

| Spec | Value |
|------|-------|
| Model | MIBOX4 |
| SoC | Amlogic S905L |
| CPU | 4x Cortex-A53 @ 1.5GHz |
| GPU | Mali-450 |
| RAM | 2GB |
| Android | 9 |
| Storage | 5GB `/data` (1.2GB `/system`, root needed to free) |
| Architecture | armeabi-v7a |
| WiFi | 5GHz (433Mbps, despite some specs saying 2.4GHz only) |
| DRM | Widevine CDM (Netflix certified) |

## Packages Disabled

### PatchWall (Xiaomi Launcher/Ads)

```bash
adb shell pm disable-user --user 0 com.mitv.tvhome.atv
adb shell pm disable-user --user 0 com.mitv.tvhome.michannel
```

### Xiaomi Telemetry

```bash
adb shell pm disable-user --user 0 com.miui.tv.analytics
adb shell pm disable-user --user 0 com.xiaomi.statistic
adb shell pm disable-user --user 0 com.xiaomi.mitv.updateservice
```

### Alphonso ACR Spyware

Alphonso is an audio recording SDK that listens through the device microphone for TV content recognition. This is invasive spyware.

```bash
adb shell pm disable-user --user 0 tv.alphonso.alphonso_eula
```

### Region-Specific Apps

```bash
adb shell pm disable-user --user 0 in.jio.jiotvplay
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 com.dth.sunnxt
```

### Google Bloat

```bash
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos
```

### Additional Packages (19 more)

See `scripts/mibox-debloat.sh` for the complete list.

## Storage Cleanup

The Mi Box has very limited storage (5GB `/data`). Without root, the only way to free space is clearing disabled app data and uninstalling for the current user.

### Step 1: Trim Caches

```bash
adb shell pm trim-caches 5G
```

**Freed ~500MB** of cached data.

### Step 2: Clear Disabled App Data

```bash
for pkg in $(adb shell pm list packages -d | sed 's/package://'); do
  adb shell pm clear "$pkg" 2>/dev/null
done
```

### Step 3: Uninstall Disabled Apps for Current User

```bash
for pkg in $(adb shell pm list packages -d | sed 's/package://'); do
  adb shell pm uninstall -k --user 0 "$pkg" 2>/dev/null
done
```

**Result**: Freed **1.1GB** on `/data` (862MB free → 1.9GB free, 86% → 62% used)

### Storage Status

| Partition | Before | After | Change |
|-----------|--------|-------|--------|
| `/data` (5GB) | 862MB free (86% used) | 1.9GB free (62% used) | +1.1GB freed |

### Root-Only Optimization

The `/system` partition is 96% full (only 60MB free). Without root, this cannot be freed. With root:

```bash
# WARNING: Requires root. Can brick device if done wrong.
adb root
mount -o remount,rw /system
# Remove unwanted system apps
rm /system/app/SomeBloatware.apk
mount -o remount,ro /system
```

## Performance Tweaks

### Disable All Animations

```bash
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0
```

### GPU Rendering

```bash
adb shell setprop debug.hwui.renderer skia
adb shell setprop debug.egl.hw 1
adb shell setprop debug.sf.hw 1
```

### Background Process Limit

```bash
adb shell settings put global background_process_limit 2
```

### Disable Doze

```bash
adb shell dumpsys deviceidle disable all
```

### Screen & Power

```bash
# Screen timeout max (never auto-off)
adb shell settings put system screen_off_timeout 2147483647

# Stay on while plugged in
adb shell svc power stayon true

# WiFi sleep policy: never
adb shell settings put global wifi_sleep_policy 2
```

### Developer Options

```bash
adb shell settings put global development_settings_enabled 1
```

## Tailscale Always-On VPN

```bash
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1
adb shell dumpsys deviceidle whitelist +com.tailscale.ipn
adb shell appops set com.tailscale.ipn RUN_IN_BACKGROUND allow
adb shell appops set com.tailscale.ipn RUN_ANY_IN_BACKGROUND allow
```

## Stremio Setup

The Mi Box runs Stremio with the Torrentio addon for streaming.

### Important Notes

- **No debrid service** — streams via P2P (public torrents)
- **Local content** is the fallback if streaming fails
- **Cache was cleared** during debloating — user needs to re-login and reinstall addons
- **DRM**: Widevine CDM is active, Netflix certified

### Reinstalling Addons

After clearing Stremio data:

1. Open Stremio
2. Log in with your account
3. Go to Addons → Community → Search "Torrentio"
4. Install Torrentio addon
5. Configure debrid service (optional, recommended for better performance)

## WiFi Verification

Despite some spec sheets claiming 2.4GHz only, the Mi Box 4 supports 5GHz WiFi:

```
Frequency: 5220MHz (5GHz)
Link Speed: 433Mbps
```

5GHz is preferred for streaming — less interference, higher throughput.

## Netflix DRM

The Mi Box 4 has active Widevine CDM for Netflix HD streaming:

```
DRM: Widevine CDM
Security Level: L1
Netflix: Certified (NFANDROID2-PRV-TARZAN-XIAOMMITV-MOOQ0)
```

This means the device can stream Netflix in HD/HDR. Do NOT disable the Widevine CDM package if you want Netflix support.

## Re-enabling Packages

```bash
# Re-enable a package
adb shell pm enable <package-name>

# Example: re-enable PatchWall
adb shell pm enable com.mitv.tvhome.atv
```

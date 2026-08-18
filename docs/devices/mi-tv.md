# Mi TV Debloat (MiTV-MOOQ0)

Debloating, SmartTube installation, and power cycling fix for the Xiaomi Mi TV.

## Device Specs

| Spec | Value |
|------|-------|
| Model | MiTV-MOOQ0 |
| SoC | MediaTek MT7632 |
| CPU | 4x Cortex-A55 @ 1.5GHz |
| GPU | Mali-G52 |
| RAM | 2GB |
| Android | 10 |
| Architecture | armeabi-v7a |
| Display | 1920x1080 |
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

### Region-Specific Apps (India)

```bash
adb shell pm disable-user --user 0 com.haier.haierhtv
adb shell pm disable-user --user 0 com.airtel.stb.live
adb shell pm disable-user --user 0 com.sonyliv.mitv
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 in.yuvaa.hungama.mitv
adb shell pm disable-user --user 0 tv.zee5.mitv
adb shell pm disable-user --user 0 com.jio.hotspot
adb shell pm disable-user --user 0 com.aha.ntv
adb shell pm disable-user --user 0 com.dth.sunnxt
```

### Google Bloat

```bash
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos
```

### Other

```bash
adb shell pm disable-user --user 0 com.mediatek.tvlauncher
```

## SmartTube Installation

SmartTube is an ad-free YouTube client for Android TV.

```bash
adb install SmartTube32.10_armeabi-v7a.apk
# Package: org.smarttube.stable
```

### Features
- Ad-free YouTube playback
- SponsorBlock integration
- Background audio
- 4K/HDR support
- Voice search

## Power Cycling Fix

The TV was turning off/on randomly with no HDMI device connected. The root cause was a combination of:

1. **Phantom HDMI audio events** — The TV's HDMI hardware generated false hotplug events even with nothing connected
2. **Aggressive idle timer** — `idle_after_inactive_to=1000` (1 second!) put the TV to sleep almost immediately
3. **Chromecast CEC cycling** — Built-in Chromecast generated `CecStandby.OnToStandby` / `StandbyToOn` events in a loop
4. **ARC interference** — HDMI ARC was enabled, generating phantom audio events

### Fixes Applied

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

### What Each Fix Does

| Setting | Before | After | Effect |
|---------|--------|-------|--------|
| `hdmi_arc_control_enabled` | 1 | 0 | Stops phantom ARC audio events |
| `hdmi_control_auto_device_off_enabled` | 0 | 0 | Already off (CEC auto-off) |
| `hdmi_control_auto_wakeup_enabled` | 0 | 0 | Already off (CEC auto-wake) |
| `power_off_put_device_to_sleep` | 1 | 0 | Power button no longer triggers deep sleep |
| `device_idle_constants` | inactive=10min, idle_after=1sec | inactive=30min, idle_after=10min | Much less aggressive idle |
| `tv_timer_sleep_timer_entry_values` | 0 | 0 | Sleep timer disabled |
| `patchwall_enable` | true | false | PatchWall launcher disabled |
| `screen_off_timeout` | 300000 | 600000 | 5 min → 10 min screen timeout |

### HDMI Audio Phantom Events

Even with no device connected, the TV reported HDMI audio TX connect/disconnect events:

```
18:58:21 HDMI_TX + ARC disconnected
18:58:25 HDMI_TX + ARC reconnected
18:58:53 HDMI_TX + ARC disconnected
18:59:01 HDMI_TX + ARC reconnected
18:59:09 HDMI_TX + ARC disconnected (3rd time in 50s)
```

This appears to be a firmware-level issue in the MediaTek HDMI driver. Disabling ARC control stops the audio subsystem from reacting to these phantom events.

## Bluetooth Remote Issues

The Xiaomi RC Bluetooth remote kept disconnecting/reconnecting throughout the day:

```
09:59:33 — Xiaomi RC unavailable
10:02:23 — Xiaomi RC available
11:07:13 — unavailable
11:07:15 — available (2 seconds later!)
14:46:27 — unavailable
14:46:29 — available (2 seconds later!)
```

This could be Bluetooth interference or weak remote battery. Not directly related to the power cycling issue, but contributes to instability.

## Re-enabling Packages

If you need to re-enable any package:

```bash
# Re-enable a package
adb shell pm enable <package-name>

# Example: re-enable PatchWall
adb shell pm enable com.mitv.tvhome.atv
```

#!/bin/bash
# Mi TV (MiTV-MOOQ0) Debloat Script
# Run from Raspberry Pi with ADB connected to the TV

set -e

TV_IP="${1:-}"

if [ -z "$TV_IP" ]; then
    echo "Usage: $0 <tv-tailnet-ip>"
    echo "Example: $0 100.97.238.24"
    exit 1
fi

echo "=== Connecting to Mi TV at $TV_IP ==="
adb connect "$TV_IP:5555"

echo ""
echo "=== Disabling PatchWall ==="
adb shell pm disable-user --user 0 com.mitv.tvhome.atv
adb shell pm disable-user --user 0 com.mitv.tvhome.michannel

echo ""
echo "=== Disabling Xiaomi Telemetry ==="
adb shell pm disable-user --user 0 com.miui.tv.analytics
adb shell pm disable-user --user 0 com.xiaomi.statistic
adb shell pm disable-user --user 0 com.xiaomi.mitv.updateservice

echo ""
echo "=== Disabling Region Apps (India) ==="
adb shell pm disable-user --user 0 com.haier.haierhtv
adb shell pm disable-user --user 0 com.airtel.stb.live
adb shell pm disable-user --user 0 com.sonyliv.mitv
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 in.yuvaa.hungama.mitv
adb shell pm disable-user --user 0 tv.zee5.mitv
adb shell pm disable-user --user 0 com.jio.hotspot
adb shell pm disable-user --user 0 com.aha.ntv
adb shell pm disable-user --user 0 com.dth.sunnxt

echo ""
echo "=== Disabling Google Bloat ==="
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos

echo ""
echo "=== Disabling Other ==="
adb shell pm disable-user --user 0 com.mediatek.tvlauncher

echo ""
echo "=== Installing SmartTube ==="
if [ -f SmartTube32.10_armeabi-v7a.apk ]; then
    adb install SmartTube32.10_armeabi-v7a.apk
    echo "SmartTube installed (org.smarttube.stable)"
else
    echo "SmartTube APK not found — skipping install"
fi

echo ""
echo "=== Done! $TV_IP debloated ==="
adb disconnect "$TV_IP:5555"

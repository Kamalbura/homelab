#!/bin/bash
# Mi Box 4 (MIBOX4) Debloat Script
# Run from Raspberry Pi with ADB connected to the Mi Box

set -e

MIBOX_IP="${1:-}"

if [ -z "$MIBOX_IP" ]; then
    echo "Usage: $0 <mibox-tailnet-ip>"
    echo "Example: $0 100.94.39.98"
    exit 1
fi

echo "=== Connecting to Mi Box at $MIBOX_IP ==="
adb connect "$MIBOX_IP:5555"

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
echo "=== Disabling Alphonso ACR Spyware ==="
adb shell pm disable-user --user 0 tv.alphonso.alphonso_eula

echo ""
echo "=== Disabling Region Apps ==="
adb shell pm disable-user --user 0 in.jio.jiotvplay
adb shell pm disable-user --user 0 com.hotstar.mitv
adb shell pm disable-user --user 0 com.dth.sunnxt

echo ""
echo "=== Disabling Google Bloat ==="
adb shell pm disable-user --user 0 com.android.chrome
adb shell pm disable-user --user 0 com.google.android.playgames
adb shell pm disable-user --user 0 com.google.android.apps.youtube.music
adb shell pm disable-user --user 0 com.google.android.videos

echo ""
echo "=== Clearing Disabled App Data ==="
for pkg in $(adb shell pm list packages -d | sed 's/package://'); do
    echo "  Clearing: $pkg"
    adb shell pm clear "$pkg" 2>/dev/null || true
done

echo ""
echo "=== Uninstalling Disabled Apps (user 0) ==="
for pkg in $(adb shell pm list packages -d | sed 's/package://'); do
    echo "  Uninstalling: $pkg"
    adb shell pm uninstall -k --user 0 "$pkg" 2>/dev/null || true
done

echo ""
echo "=== Trimming Caches ==="
adb shell pm trim-caches 5G

echo ""
echo "=== Storage Status ==="
adb shell df -h /data

echo ""
echo "=== Done! $MIBOX_IP debloated ==="
adb disconnect "$MIBOX_IP:5555"

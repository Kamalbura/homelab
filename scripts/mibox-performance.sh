#!/bin/bash
# Mi Box 4 Performance Tweaks
# Run from Raspberry Pi with ADB connected to the Mi Box

set -e

MIBOX_IP="${1:-}"

if [ -z "$MIBOX_IP" ]; then
    echo "Usage: $0 <mibox-tailnet-ip>"
    exit 1
fi

echo "=== Connecting to Mi Box at $MIBOX_IP ==="
adb connect "$MIBOX_IP:5555"

echo ""
echo "=== Disabling Animations ==="
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0
echo "  All animation scales set to 0.0"

echo ""
echo "=== Enabling GPU Rendering ==="
adb shell setprop debug.hwui.renderer skia
adb shell setprop debug.egl.hw 1
adb shell setprop debug.sf.hw 1
echo "  Skia renderer, EGL, SF HW enabled"

echo ""
echo "=== Setting Background Process Limit ==="
adb shell settings put global background_process_limit 2
echo "  Background limit: 2 processes"

echo ""
echo "=== Disabling Doze ==="
adb shell dumpsys deviceidle disable all
echo "  Doze disabled"

echo ""
echo "=== Setting Screen Timeout (max) ==="
adb shell settings put system screen_off_timeout 2147483647
echo "  Screen timeout: max (never auto-off)"

echo ""
echo "=== Setting Power Stay On ==="
adb shell svc power stayon true
echo "  Stay on while plugged in"

echo ""
echo "=== Setting WiFi Sleep Policy ==="
adb shell settings put global wifi_sleep_policy 2
echo "  WiFi sleep: never"

echo ""
echo "=== Enabling Developer Options ==="
adb shell settings put global development_settings_enabled 1
echo "  Developer options enabled"

echo ""
echo "=== Setting Tailscale Always-On VPN ==="
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1
adb shell dumpsys deviceidle whitelist +com.tailscale.ipn
adb shell appops set com.tailscale.ipn RUN_IN_BACKGROUND allow
adb shell appops set com.tailscale.ipn RUN_ANY_IN_BACKGROUND allow
echo "  Tailscale always-on VPN configured"

echo ""
echo "=== Done! $MIBOX_IP optimized ==="
adb disconnect "$MIBOX_IP:5555"

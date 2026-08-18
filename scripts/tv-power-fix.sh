#!/bin/bash
# Mi TV Power Cycling Fix
# Fixes phantom HDMI events, aggressive idle timers, and Chromecast CEC cycling

set -e

TV_IP="${1:-}"

if [ -z "$TV_IP" ]; then
    echo "Usage: $0 <tv-tailnet-ip>"
    exit 1
fi

echo "=== Connecting to Mi TV at $TV_IP ==="
adb connect "$TV_IP:5555"

echo ""
echo "=== Disabling ARC Control ==="
adb shell settings put global hdmi_arc_control_enabled 0
echo "  hdmi_arc_control_enabled = 0"

echo ""
echo "=== Disabling CEC Auto-Off/Auto-Wake ==="
adb shell settings put global hdmi_control_auto_device_off_enabled 0
adb shell settings put global hdmi_control_auto_wakeup_enabled 0
echo "  hdmi_control_auto_device_off_enabled = 0"
echo "  hdmi_control_auto_wakeup_enabled = 0"

echo ""
echo "=== Disabling Power Button Sleep ==="
adb shell settings put global power_off_put_device_to_sleep 0
echo "  power_off_put_device_to_sleep = 0"

echo ""
echo "=== Extending Idle Timer ==="
adb shell settings put global device_idle_constants 'inactive_to=1800000,idle_after_inactive_to=600000,locating_to=1000,idle_to=28800000,max_idle_to=86400000,idle_factor=2,light_after_inactive_to=1800000'
echo "  inactive=30min, idle_after=10min (was: inactive=10min, idle_after=1sec!)"

echo ""
echo "=== Disabling Sleep Timer ==="
adb shell settings put global tv_timer_sleep_timer_entry_values 0
adb shell settings put global sleep_timer_remain_time 0
echo "  Sleep timer disabled"

echo ""
echo "=== Disabling PatchWall ==="
adb shell settings put global patchwall_enable false
adb shell settings put global set_patchwall_default 0
echo "  patchwall_enable = false"

echo ""
echo "=== Setting Screen Timeout (10 min) ==="
adb shell settings put system screen_off_timeout 600000
echo "  screen_off_timeout = 600000 (10 min)"

echo ""
echo "=== Force-Stopping Chromecast ==="
adb shell am force-stop com.google.android.apps.mediashell
echo "  Chromecast (mediashell) force-stopped"

echo ""
echo "=== Verifying Settings ==="
echo "  hdmi_arc_control_enabled       = $(adb shell settings get global hdmi_arc_control_enabled)"
echo "  hdmi_control_auto_device_off   = $(adb shell settings get global hdmi_control_auto_device_off_enabled)"
echo "  hdmi_control_auto_wakeup       = $(adb shell settings get global hdmi_control_auto_wakeup_enabled)"
echo "  power_off_put_device_to_sleep  = $(adb shell settings get global power_off_put_device_to_sleep)"
echo "  patchwall_enable               = $(adb shell settings get global patchwall_enable)"
echo "  screen_off_timeout             = $(adb shell settings get system screen_off_timeout)"

echo ""
echo "=== Done! $TV_IP power cycling fix applied ==="
echo "Monitor for 24 hours to verify stability."
adb disconnect "$TV_IP:5555"

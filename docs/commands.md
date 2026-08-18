# Commands Reference

Quick reference for ADB, Docker, system, and networking commands used in this homelab.

## ADB Device Management

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

# Pull a file from device
adb pull <device-path> <local-path>

# Push a file to device
adb push <local-path> <device-path>

# Install APK
adb install <apk-file>

# Sideload OTA
adb sideload <ota-file>
```

## ADB Package Management

```bash
# List all packages
adb shell pm list packages

# List disabled packages
adb shell pm list packages -d

# List enabled packages
adb shell pm list packages -e

# Search for a package
adb shell pm list packages | grep <keyword>

# Disable a package (user level, reversible)
adb shell pm disable-user --user 0 <package>

# Enable a package
adb shell pm enable <package>

# Clear app data
adb shell pm clear <package>

# Uninstall for current user (frees storage)
adb shell pm uninstall -k --user 0 <package>

# Show package info
adb shell dumpsys package <package> | head -30
```

## ADB Settings

```bash
# List all settings
adb shell settings list global
adb shell settings list system
adb shell settings list secure

# Get a setting
adb shell settings get global <key>

# Set a setting
adb shell settings put global <key> <value>

# Common settings
adb shell settings put global window_animation_scale 0.0
adb shell settings put global transition_animation_scale 0.0
adb shell settings put global animator_duration_scale 0.0
adb shell settings put system screen_off_timeout 600000
adb shell settings put global background_process_limit 2
```

## ADB Diagnostics

```bash
# Logcat (device logs)
adb shell logcat -d | grep <pattern>

# Logcat with timestamp
adb shell logcat -d -v time | grep <pattern>

# Logcat specific tag
adb shell logcat -d -s <tag>

# Dumpsys (service info)
adb shell dumpsys power
adb shell dumpsys display
adb shell dumpsys audio
adb shell dumpsys battery
adb shell dumpsys package <package>
adb shell dumpsys activity services
adb shell dumpsys deviceidle

# Process info
adb shell top -b -n 1
adb shell ps -A | grep <process>

# Storage
adb shell df -h
adb shell df -h /data

# Network
adb shell ifconfig
adb shell ping -c 3 <ip>

# Bluetooth
adb shell settings list secure | grep bluetooth

# WiFi
adb shell dumpsys wifi | head -20
```

## ADB Tailscale Setup

```bash
# Set always-on VPN
adb shell settings put global always_on_vpn_app com.tailscale.ipn
adb shell settings put global always_on_vpn_lockdown 1

# Battery whitelist
adb shell dumpsys deviceidle whitelist +com.tailscale.ipn
adb shell appops set com.tailscale.ipn RUN_IN_BACKGROUND allow
adb shell appops set com.tailscale.ipn RUN_ANY_IN_BACKGROUND allow
```

## Docker

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# View logs
docker logs -f <container>

# Restart container
docker restart <container>

# Execute command in container
docker exec -it <container> <command>

# Pull latest image
docker pull <image>

# Docker compose
docker compose up -d
docker compose down
docker compose pull
docker compose logs -f

# Resource usage
docker stats --no-stream

# Clean up
docker system prune -f
docker volume prune -f
```

## System Monitoring

```bash
# CPU temperature
cat /sys/class/thermal/thermal_zone0/temp
vcgencmd measure_temp

# Memory
free -h

# Disk
df -h
lsblk

# Processes
htop
top -b -n 1 | head -20

# Network
ss -tlnp
ip addr show
iwconfig

# Logs
journalctl -u <service> -f
journalctl --since "1 hour ago"
```

## Tailscale

```bash
# Status
tailscale status

# IP address
tailscale ip

# Ping a peer
tailscale ping <hostname>

# SSH into a peer
tailscale ssh <hostname>

# Check connection
tailscale status | grep <hostname>
```

## Pi-hole

```bash
# Enable blocking
pihole enable

# Disable blocking
pihole disable

# Query a domain
pihole query <domain>

# Update gravity (ad lists)
pihole -g

# Status
pihole status

# Web interface
# http://<pi-ip>/admin
```

## SSH

```bash
# Connect
ssh <user>@<ip>

# Connect with key
ssh -i ~/.ssh/key <user>@<ip>

# SSH tunnel (forward remote port to local)
ssh -L 8080:localhost:8080 <user>@<pi-ip>

# SCP file to remote
scp <file> <user>@<pi-ip>:<remote-path>

# SCP file from remote
scp <user>@<pi-ip>:<remote-path> <local-path>
```

## Git

```bash
# Clone repo
git clone <url>

# Add changes
git add .

# Commit
git commit -m "message"

# Push
git push origin main

# Pull
git pull origin main

# Status
git status

# Log
git log --oneline -10
```

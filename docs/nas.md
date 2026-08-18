# NAS

Samba file sharing, FileBrowser web UI, and HDD power management.

## Storage

### Hardware

| Device | Size | Type | Mount | Purpose |
|--------|------|------|-------|---------|
| Seagate ST9500325AS | 460GB | HDD (USB-SATA) | `/mnt/nas` | NAS file share |

### Current Usage

```
/mnt/nas  460GB  18GB used  (5%)
```

## Samba

Samba provides SMB/CIFS file sharing accessible from any device on the network.

### Configuration

- **Container**: `crazymax/samba:latest`
- **Network**: Host mode (required for SMB broadcast)
- **Port**: 445 (SMB)
- **Allowed networks**: `127.0.0.0/8`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.0.0.0/8`

### Accessing from Clients

#### Windows
```
\\<pi-ip>\nas
```

#### macOS
```
smb://<pi-ip>/nas
```

#### Linux
```bash
smbclient //<pi-ip>/nas -U <username>
# Or mount permanently:
sudo mount -t cifs //<pi-ip>/nas /mnt/nas -o username=<username>
```

#### Android (SMB file managers)
Use apps like CX File Explorer or Solid Explorer to connect via SMB.

## FileBrowser

FileBrowser provides a web-based file manager for the NAS.

- **URL**: `http://localhost:8080` (localhost only — access via SSH tunnel or Tailscale)
- **Root directory**: `/mnt/nas`
- **Authentication**: Username/password
- **Features**: Upload, download, preview, edit, share

### Accessing FileBrowser

Since FileBrowser binds to localhost only, access it via:

```bash
# SSH tunnel from your phone/laptop
ssh -L 8080:localhost:8080 bura@<pi-tailnet-ip>

# Then open http://localhost:8080 in browser
```

## HDD Power Management

The Seagate HDD spins down after 120 seconds of idle to save power and extend lifespan.

### Configuration

The `hdd-powermanage.service` systemd unit runs before NAS services:

```bash
hdparm -B 127 -S 120 /dev/disk/by-id/ata-ST9500325AS_6VEHTME4
```

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `-B 127` | APM level 127 | Balanced performance/power |
| `-S 120` | Spindown 120 | 120 × 5 seconds = 10 minutes (or 120 seconds depending on drive) |

### SMART Monitoring

The smartctl exporter monitors HDD health without waking sleeping disks:

- Uses `smartctl -n standby` to skip sleeping drives
- Refreshes every 15 minutes
- Reports: temperature, power-on hours, reallocated sectors, health status

### Backup Strategy

The NAS is used for file sharing, not backup. Important data should be backed up separately. Consider:

- Cloud backup (encrypted)
- Second HDD in RAID configuration
- rsync to another machine on the tailnet

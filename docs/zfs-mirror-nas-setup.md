# ZFS mirror NAS — setup, sharing, and client access

A practical walkthrough for turning a Debian/Proxmox host with two large
HDDs into a small home NAS using a **two-disk ZFS mirror** and **Samba**
for SMB access from Linux, macOS, and Windows clients.

The result is a pool with one dataset per "tenant" (e.g. one for you, one
for your partner, one shared family pool), exposed over SMB so any client
on the LAN can mount and use it.

> Aimed at a single-host home NAS scenario where simplicity beats squeezing
> the last bit of performance. A two-disk mirror gives you a tolerance of
> one disk failure and easy recovery — at the cost of using half your raw
> capacity. RAIDZ is a different tradeoff and out of scope here.

---

## Hardware assumptions

- Two identical (or near-identical) HDDs you're willing to dedicate to
  the pool. They will be wiped.
- Drives are addressed by their stable `/dev/disk/by-id/...` names — never
  by `/dev/sdX`, which can change across reboots.
- 4K-sector ("Advanced Format") disks. ZFS calls this `ashift=12`. Almost
  every drive newer than ~2011 fits this.

---

## Setup

### 1. Identify the disks

```sh
ls -l /dev/disk/by-id/ | grep -v part | grep -v wwn
```

You're looking for two `ata-MODEL_SERIAL` entries that map to the two
drives you intend to mirror. Note the full names — you'll use them in the
next step. Example output (made-up):

```
ata-WDC_WD120XXXX-XXXX_WD-AAAAAAAAA -> ../../sda
ata-WDC_WD120XXXX-XXXX_WD-BBBBBBBBB -> ../../sdb
```

Stable names like these survive controller reorderings; `/dev/sdX` does
not.

### 2. Install ZFS

On Proxmox VE, ZFS is already there. On plain Debian:

```sh
apt update
apt install -y zfsutils-linux
```

### 3. Create the pool

```sh
zpool create -o ashift=12 \
    -O compression=lz4 \
    -O atime=on -O relatime=on \
    -O xattr=sa -O acltype=posix \
    -O dnodesize=auto \
    -m /POOLNAME \
    POOLNAME mirror \
    /dev/disk/by-id/ata-MODEL_SERIAL_A \
    /dev/disk/by-id/ata-MODEL_SERIAL_B
```

What each piece does:

- `-o ashift=12` — 4K sector alignment. Set at pool creation; you cannot
  change it later. Wrong value = silent performance penalty.
- `-O compression=lz4` — transparent fast compression. Effectively free on
  modern CPUs, often a slight performance gain because less data hits
  disk. Use `zstd` if you want better ratios at higher CPU cost.
- `-O atime=on -O relatime=on` — keep access-time tracking but throttled
  (`relatime`-style) so it doesn't write on every read. If you don't care
  about access times at all, set `-O atime=off` for a tiny extra win.
- `-O xattr=sa` — store extended attributes inside inodes instead of
  separate hidden objects. Required for sane Samba ACL behaviour and a
  measurable speedup.
- `-O acltype=posix` — POSIX ACLs (the kind Samba expects). Without this,
  Samba ACL features quietly don't work.
- `-O dnodesize=auto` — pairs with `xattr=sa`, lets ZFS pick a better
  dnode size.
- `-m /POOLNAME` — mountpoint of the pool root.
- `mirror DISK1 DISK2` — vdev type and members. The pool's failure
  tolerance is "lose any one disk" because it's a 2-way mirror.

Verify:

```sh
zpool status
zfs list
```

### 4. Create per-tenant datasets

A dataset in ZFS is a child filesystem with its own properties, snapshots,
and quota. Treating each "tenant" (yourself, your partner, shared family
storage) as its own dataset makes per-user snapshots, sharing, and
backup-tier policies trivial.

```sh
zfs create POOLNAME/share         # shared family/household data
zfs create POOLNAME/me            # your own personal data
zfs create POOLNAME/partner       # your partner's personal data
```

Each dataset inherits the pool's properties. You can override per-dataset
later — e.g. larger `recordsize` on a dataset that holds video editing
projects.

### 5. Set ownership and permissions

Decide who owns what before any data lands. Get this wrong now and fixing
it later is a `chown -R` over terabytes.

Create users and groups first:

```sh
adduser me
adduser partner
groupadd family               # shared group for everyone in the household
gpasswd -a me family
gpasswd -a partner family
```

Then set up the directories:

```sh
chown    me:me       /POOLNAME/me
chmod    700         /POOLNAME/me

chown    partner:partner   /POOLNAME/partner
chmod    700               /POOLNAME/partner

chown    root:family       /POOLNAME/share
chmod    2775              /POOLNAME/share
# 2 = setgid (new files inherit the `family` group)
# 775 = owner+group rwx, others r-x
```

The setgid bit (`2`) on the shared directory is the key trick — every new
file inside will be group-owned by `family`, regardless of who created it,
so household members can edit each other's files.

### 6. Tune dataset properties for the workload

Sensible default `recordsize` is `128K`, fine for general mixed data. Tune
when a dataset's workload is clearly skewed:

```sh
# Large sequential files (movies, recordings, video projects):
zfs set recordsize=1M POOLNAME/share

# Lots of small files (source code, mail spool, sqlite databases):
zfs set recordsize=16K POOLNAME/some-other-dataset
```

`recordsize` is the *maximum* block size; smaller files use smaller
blocks. Changing it only affects newly-written data.

### 7. Schedule a scrub

A scrub re-reads every block and checksums it, repairing any silent
corruption from its mirror copy. Don't skip this — it's the whole point of
running ZFS.

The Debian package ships a monthly scrub timer:

```sh
systemctl enable --now zfs-scrub-monthly@POOLNAME.timer
systemctl list-timers zfs-scrub*
```

You can fire one off manually with `zpool scrub POOLNAME` and check
progress with `zpool status`.

### 8. (Optional but recommended) Snapshots

See the companion doc `encrypted-backup-to-hetzner-storage-box.md` for a
full sanoid-based snapshot policy. Short version:

```sh
apt install -y sanoid
mkdir -p /etc/sanoid
$EDITOR /etc/sanoid/sanoid.conf       # define datasets and templates
systemctl enable --now sanoid.timer
```

Snapshots are practically free until something changes, and they save
you from "I just deleted the wrong directory" without any restore-from-
backup ceremony. Highly recommended.

---

## Sharing the pool over SMB (Samba)

SMB works on every modern OS, including Windows out of the box. NFS is an
alternative if you only have Linux clients and want lower overhead — not
covered here.

### 1. Install Samba

```sh
apt install -y samba
```

### 2. Configure shares — `/etc/samba/smb.conf`

Replace the shipped file with something like:

```ini
[global]
   workgroup = WORKGROUP
   server string = home NAS
   security = user
   map to guest = never
   server min protocol = SMB2
   client min protocol = SMB2
   # macOS clients work better with these:
   vfs objects = catia fruit streams_xattr
   fruit:metadata = stream
   fruit:resource = stream
   fruit:posix_rename = yes
   # Per-share log files:
   log file = /var/log/samba/log.%m
   max log size = 50

[share]
   path = /POOLNAME/share
   valid users = @family
   read only = no
   create mask = 0664
   directory mask = 2775
   force group = family
   inherit permissions = yes

[me]
   path = /POOLNAME/me
   valid users = me
   read only = no
   create mask = 0600
   directory mask = 0700

[partner]
   path = /POOLNAME/partner
   valid users = partner
   read only = no
   create mask = 0600
   directory mask = 0700
```

What the per-share knobs do:

- `valid users` — who can authenticate to this share. Use `@groupname`
  for whole-group access.
- `force group = family` on the shared share — combined with the setgid
  directory bit from earlier, this guarantees every file ends up
  group-owned by `family`, even if the SMB client created it.
- `create mask` / `directory mask` — clamp the permissions of created
  files. `0664` gives owner+group write, others read-only — appropriate
  for a shared family share.
- Personal shares use `0600` / `0700` so only the owner can ever read
  their own files, regardless of what happens at the filesystem level.

Validate the config:

```sh
testparm
```

`testparm` parses `smb.conf` the way Samba would and prints what it
understood. Use it to catch typos before reloading.

### 3. Create Samba passwords

Samba has its own user database (separate from Linux passwords). Each
user must be both a Linux user and a Samba user.

```sh
smbpasswd -a me                # prompts for a password
smbpasswd -a partner
```

These are the credentials clients will type when mounting.

### 4. Restart and verify

```sh
systemctl restart smbd nmbd
systemctl enable smbd nmbd

# From the NAS itself:
smbclient -L //localhost -U me

# Should list the [share], [me], [partner] shares.
```

### 5. Open the firewall (if any)

If you run `ufw` or have firewall rules, allow Samba traffic on the LAN:

```sh
# UFW example — only allow from your LAN, not the whole internet:
ufw allow from 192.168.0.0/16 to any app Samba
```

---

## Mounting from clients

### Linux (CIFS, persistent in `/etc/fstab`)

```sh
apt install -y cifs-utils
mkdir -p /mnt/nas-share /mnt/nas-me
```

Store credentials in a root-only file so they don't appear in `ps` or
`/etc/fstab`:

```sh
cat > /root/.smbcredentials <<'EOF'
username=me
password=YOUR-SMB-PASSWORD
EOF
chmod 600 /root/.smbcredentials
```

Add to `/etc/fstab`:

```
//nas.local/share  /mnt/nas-share  cifs  credentials=/root/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,vers=3.0,_netdev,nofail  0 0
//nas.local/me     /mnt/nas-me     cifs  credentials=/root/.smbcredentials,uid=1000,gid=1000,iocharset=utf8,vers=3.0,_netdev,nofail  0 0
```

Replace `nas.local` with your NAS's hostname or IP. Notable mount options:

- `credentials=` — keeps creds out of `/etc/fstab`.
- `uid=` / `gid=` — owner of the mount inside the client. Use *your local
  user's* IDs (`id -u`, `id -g`) so the files appear owned by you.
- `vers=3.0` — modern SMB. Avoid `vers=1.0` (insecure SMB1).
- `_netdev` — wait for the network before mounting at boot.
- `nofail` — boot will not hang if the NAS is down.

```sh
mount -a
ls /mnt/nas-share
```

### Linux (one-off, no fstab)

```sh
mount -t cifs //nas.local/share /mnt/nas-share \
    -o user=me,vers=3.0,uid=$(id -u),gid=$(id -g)
# It will prompt for the SMB password.
```

### macOS (GUI)

Finder → `Cmd-K` → `smb://nas.local/share` → enter SMB username and
password. Tick "Remember this password in my keychain" for persistence.

To auto-mount at login: System Settings → Users & Groups → Login Items →
add the mounted volume after it's connected once.

### Windows (GUI)

File Explorer → "This PC" → "Map network drive" → choose a drive letter →
folder `\\nas.local\share` → tick "Reconnect at sign-in" and "Connect
using different credentials" → enter the SMB username and password.

### Windows (PowerShell, persistent)

```powershell
New-PSDrive -Name "S" -PSProvider FileSystem `
    -Root "\\nas.local\share" `
    -Credential (Get-Credential) `
    -Persist
```

(`S:` will reappear after reboot if you tick "Save credentials" when
prompted.)

### Hostname resolution

If `nas.local` doesn't resolve, you have a few options:

- **Best:** give the NAS a static DHCP reservation in your router and an
  A record in your local DNS (Pi-hole, Unbound, OPNsense, your router's
  built-in DNS, whatever you use).
- Avahi/mDNS — install `avahi-daemon` on the NAS and most clients can
  reach it as `<hostname>.local` automatically.
- Last resort: hardcode the IP in client `/etc/hosts` or the Windows
  equivalent.

---

## Browsing snapshots from clients

ZFS exposes snapshots at the hidden path `<dataset-mountpoint>/.zfs/snapshot/<name>/`.
The directory is invisible by default; you have to type the path
explicitly. Once enabled in Samba's config (it normally is by default in
recent versions), the same path is visible from SMB clients via the
"Previous Versions" tab on Windows and `ls .zfs/snapshot/` on Linux.

To enable Windows "Previous Versions" support, add to each share in
`smb.conf`:

```ini
   vfs objects = shadow_copy2 catia fruit streams_xattr
   shadow:snapdir = .zfs/snapshot
   shadow:sort = desc
   shadow:format = autosnap_%Y-%m-%d_%H:%M:%S_%S
   shadow:snapprefix = ^autosnap
   shadow:delimiter = _
```

The `shadow:format` here matches the snapshot names sanoid creates
(`autosnap_2026-05-01_13:30:23_daily`). Adjust if you use a different
snapshot scheme.

Restart Samba after editing.

---

## Maintenance

### Health check

```sh
zpool status -v
zpool list
zfs list -t all -o name,used,available,referenced,mountpoint
```

Run `zpool status` whenever you suspect trouble. A healthy pool says
"errors: No known data errors" and all vdevs `ONLINE`.

### Scrubs

```sh
zpool scrub POOLNAME           # start
zpool scrub -p POOLNAME        # pause
zpool status                   # progress
```

A monthly scrub via the systemd timer is enough for home use. On a
healthy 12 TB mirror with mostly idle disks, a scrub takes 8–24 hours
depending on fill level.

### Disk replacement

When (not if) a disk fails:

```sh
# 1. Identify the failed disk:
zpool status

# 2. Physically swap it. Find the new disk's by-id path:
ls -l /dev/disk/by-id/

# 3. Replace within the pool:
zpool replace POOLNAME /dev/disk/by-id/OLD-DISK /dev/disk/by-id/NEW-DISK

# 4. Watch resilver progress:
zpool status
```

Resilver speed depends on the amount of data, not pool size — a
half-full mirror resilvers in roughly half the time of a full one.

### Capacity expansion

To grow a mirror to bigger disks, replace each disk in turn (one at a
time, waiting for full resilver between), then:

```sh
zpool set autoexpand=on POOLNAME
zpool online -e POOLNAME /dev/disk/by-id/NEW-DISK
```

The pool jumps to the new larger size.

### Sending a dataset to another machine

ZFS's killer feature for backup and migration:

```sh
# Take a snapshot to ship:
zfs snapshot POOLNAME/me@migration

# Send it (over SSH, into a receiving pool on the other machine):
zfs send POOLNAME/me@migration | ssh other-host \
    "zfs receive otherpool/me"

# Subsequent incremental sends only ship changed blocks:
zfs snapshot POOLNAME/me@migration2
zfs send -i POOLNAME/me@migration POOLNAME/me@migration2 \
    | ssh other-host "zfs receive otherpool/me"
```

The receiving side must be ZFS — you can't `zfs receive` into LVM, ext4,
or anything else. For replicating to non-ZFS targets, see the restic doc.

---

## Common questions

### Why a mirror instead of RAIDZ?

Mirrors:
- Resilver fast (only one disk's worth of data to copy).
- Tolerate one disk failure per vdev.
- Easier to expand: replace one disk at a time, the pool grows when both
  are upgraded.

RAIDZ:
- Better usable-capacity ratio (RAIDZ1 with 4 disks ≈ 75% capacity vs
  50% for a mirror).
- Slower random IOPS.
- Harder to expand (until very recent ZFS versions).

For two disks, mirror is the only sensible option. For 4+ disks, the
trade-off opens up.

### Why not native ZFS encryption?

Native encryption is great when:
- You don't trust the physical disks (off-site, second-hand, decommission).
- You want to ship encrypted streams elsewhere (`zfs send --raw`).

It costs you:
- A passphrase to load on every boot/import.
- Slightly higher CPU on read/write.
- More moving parts when you'd rather just have files.

For a home NAS where the disks live in your home and the off-site backup
is encrypted at the *backup* layer (restic), native ZFS encryption is
optional. Skip it unless you have a specific reason.

### What's the failure mode if both disks fail?

Total pool loss. That's what the off-site backup is for. Never treat RAID
or a mirror as a backup; it isn't. It's an availability feature.

### How big a recordsize should I use?

128 KB is fine for almost everything. Override per-dataset only when:
- A workload is mostly sequential huge files → `1M`.
- A workload is mostly small random I/O (databases, large mailboxes) →
  match the block size of the application (often 16K or 64K).

### Do I need a SLOG / L2ARC?

For a home NAS with HDDs, almost never. SLOG only helps synchronous
writes (NFS, databases). L2ARC only helps if your hot working set
exceeds RAM and is small enough to fit on a fast SSD. For media + photos
+ documents, neither is worth the complexity.

---

## TL;DR cheat sheet

```sh
zpool status                          # health
zpool list                            # capacity
zfs list -o name,used,avail           # per-dataset usage
zfs snapshot POOLNAME/me@manual       # one-off snapshot
zfs rollback POOLNAME/me@manual       # undo to that snapshot
zpool scrub POOLNAME                  # start a scrub
ls /POOLNAME/me/.zfs/snapshot/        # browse snapshots from inside a dataset
testparm                              # validate smb.conf
smbpasswd -a username                 # add an SMB user
```

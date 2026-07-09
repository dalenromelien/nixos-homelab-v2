# NixOS Homelab Installation Guide

This guide walks you through building and installing your NixOS homelab from the multi-host flake configuration.

## Prerequisites

- A Linux machine with Nix installed (to build the ISO)
- A bootable USB drive (at least 2GB)
- Target hardware for homelab installation (x86_64 architecture)
- Network access on target hardware

## Step 1: Build the ISO

On your development machine (e.g., nanopi):

```bash
cd /path/to/nixos-homelab-v2
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

This creates an ISO image at `result/iso/nixos-*.iso`

## Step 2: Write ISO to USB Drive

```bash
# Find your USB device
lsblk

# Write ISO (replace sdX with your USB device, e.g., sdb)
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Eject safely
sudo eject /dev/sdX
```

⚠️ **Warning:** Double-check device name before running `dd` to avoid data loss!

## Step 3: Boot from USB

1. Insert USB drive into target hardware
2. Power on and enter boot menu (usually F12, Del, or Esc during startup)
3. Select USB drive from boot options
4. Wait for NixOS installer to boot (minimal ISO, no GUI)

## Step 4: Identify Disks and Configure Disko

Once booted from ISO, you'll have a bash shell with `disko`, `git`, and `helix` pre-installed. The ISO is intentionally minimal and does not bake disk templates or a customer flake into `/etc/nixos`.

Create a customer-specific feature branch with the correct disk IDs in `hosts/iso/disko/*.nix`, then clone that branch into the installer environment before running `disko`.

For example:
```bash
git clone --branch customer/<name> https://github.com/dalenromelien/nixos-homelab-v2.git /root/homelab
cd /root/homelab
```

Clone the customer feature branch or customer template repo containing pre-populated `hosts/iso/disko/*.nix` files and device IDs, then run `disko` from that checkout.

**For detailed disk identification instructions, see [DISK_IDENTIFICATION.md](DISK_IDENTIFICATION.md)**

### Step 4a: List Your Disks

```bash
# List all disks with stable identifiers
ls -la /dev/disk/by-id/

# You'll see output like:
# ata-SAMSUNG_870_EVO_256GB_S123456789 -> ../../sda
# ata-SEAGATE_BARRACUDA_PRO_3TB_S987654321 -> ../../sdb
# (etc.)
```

**Important:** Use these `/dev/disk/by-id/` names, not `/dev/sdX` — they're stable across reboots and hardware changes.

### Step 4b: Edit Disko Configuration

Edit the appropriate disko config for your hardware setup in the customer branch checkout. The templates are available in the repo under `hosts/iso/disko/`.

**For RAID1 (2-disk):**
```bash
# Clone the customer repo branch and edit the file there:
cd /root/homelab
helix hosts/iso/disko/raid1.nix
```

**For RAID10 (4-disk):**
```bash
cd /root/homelab
helix hosts/iso/disko/raid10.nix
```

Replace these placeholders with your actual disk IDs from Step 4a. For example:
```nix
boot = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SAMSUNG_870_EVO_256GB_S123456789";
```

### Example Edit

Original (disko-raid10.nix):
```nix
boot = {
  type = "disk";
  device = "/dev/disk/by-id/ata-CHANGE_ME_BOOT_SERIAL";
```

After edit (with your actual disk):
```nix
boot = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SAMSUNG_870_EVO_256GB_S123456789";
```

Do this for all `CHANGE_ME_*` placeholders. Save the file when complete.

## Step 5: Partition Disks with Disko

Now run disko to partition the disks according to your edited configuration from the cloned customer repo:

```bash
cd /root/homelab
# For RAID1 configuration
sudo disko -m disko -c hosts/iso/disko/raid1.nix

# or for RAID10 configuration
sudo disko -m disko -c hosts/iso/disko/raid10.nix
```

**What disko does:**
- Partitions your boot drive (SSD)
- Creates RAID1 or RAID10 array across data drives
- Formats filesystems
- Mounts at `/mnt` ready for NixOS installation

⚠️ **This is destructive** — it will erase the selected disks. Verify disk IDs in the config file before proceeding.

## Step 6: Run NixOS Installer

Once disko completes successfully, install NixOS to the prepared disks from the cloned customer repo. **Important:** The flake target you choose MUST match the disko config you used:

### Option A: RAID1 (2-Disk Setup)

```bash
cd /root/homelab
sudo nixos-install --flake .#homelab-raid1
```

Use this if you edited and ran `hosts/iso/disko/raid1.nix` in the cloned customer repo checkout.

### Option B: RAID10 (4-Disk Setup)

```bash
cd /root/homelab
sudo nixos-install --flake .#homelab-raid10
```

Use this if you edited and ran `hosts/iso/disko/raid10.nix` in the cloned customer repo checkout.

**What nixos-install does:**
- Downloads and builds NixOS with your homelab services (Immich, Nextcloud, AdGuard, Netbird, etc.)
- Sets up auto-update service (runs Sunday 3am weekly)
- Integrates your chosen RAID configuration
- Installs GRUB bootloader
- Generates `/etc/nixos/hardware-configuration.nix` for your specific hardware
- Asks for root password during installation

## Step 7: Reboot

```bash
sudo reboot
```

Remove USB drive when prompted. The machine will boot into your new NixOS homelab with all services running.

## Step 8: Verify Installation

Once booted:

```bash
# Check auto-update timer
systemctl list-timers nixos-autoupgrade

# Check services are running
systemctl status immich
systemctl status adguardhome
systemctl status nextcloud
systemctl status caddy

# Access services (if networking is configured)
# immich.home
# adguard.home
# nextcloud.home
```

## Step 9: Optional Customization

Your homelab comes with sensible defaults tracked from the GitHub repository. If you want to customize it locally (disable auto-updates, add packages, change firewall rules, etc.), create a `/etc/nixos/configuration.nix` file.

A template is available at `/etc/nixos/configuration.nix.template` on the ISO. After installation, copy it to the installed system:

```bash
# On the installed system
sudo cp /etc/nixos/configuration.nix.template /etc/nixos/configuration.nix
sudo helix /etc/nixos/configuration.nix

# Apply your customizations
sudo nixos-rebuild switch

# Important: If you add a configuration.nix, auto-updates will stop
# You'll need to run: sudo nixos-rebuild switch --flake /etc/nixos#homelab-raid1
```

**Warning:** If you add a `/etc/nixos/configuration.nix`, auto-updates will no longer run automatically. You'll need to manually rebuild after updates.

## Step 10: Test Auto-Update (Optional)

To test auto-update without waiting a week:

```bash
sudo systemctl start nixos-autoupgrade.service

# Watch progress
journalctl -u nixos-autoupgrade -f
```

Auto-update will:
1. Pull latest from `github:dalenromelien/nixos-homelab-v2`
2. Rebuild NixOS with the new configuration
3. Switch to the new generation (automatic rollback if build fails)

## Troubleshooting

### No network during installation
- Ensure NIC is connected
- Manually configure with: `ip addr add 192.168.1.X/24 dev eth0`
- Set gateway: `ip route add default via 192.168.1.1`

### Installation fails
- Check disk space: `df -h`
- Check Nix builds: `journalctl -xe`
- Try rebuilding ISO with: `nix build --no-substitute`

### Services not starting after reboot
- Check logs: `journalctl -u service-name -n 50`
- Verify `flake.nix` is available in the customer repo checkout you used for install
- Rebuild manually: `sudo nixos-rebuild switch --flake /etc/nixos`

### Auto-update not running
- Verify timer: `systemctl list-timers nixos-autoupgrade`
- Check timer is active: `systemctl status nixos-autoupgrade.timer`
- Manual test: `sudo systemctl start nixos-autoupgrade.service`

## Next Steps

After successful installation:

1. **Configure networking** — edit `/etc/nixos/flake.nix` to change IP/hostname
2. **Set initial passwords** — change Nextcloud admin, AdGuard settings
3. **Backup flake.lock** — save to safe location for disaster recovery
4. **Monitor auto-updates** — watch `/var/log/syslog` for update progress

## Questions?

Refer to the NixOS Ultimate Homelab Guide in `docs/nixos-ultimate-guide.md` for deeper explanations of services and configuration options.

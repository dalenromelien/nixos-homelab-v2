# Disk Identification Guide

This guide explains how to identify your hardware disks and configure the disko setup for your homelab installation.

## Why /dev/disk/by-id/?

NixOS disko uses `/dev/disk/by-id/` instead of `/dev/sdX` because:

- **Stable:** Disk IDs don't change after reboots or hardware reorders
- **Reproducible:** Same disks always map to the same configuration
- **Hardware-independent:** Works on any system with the same drives

## Finding Your Disk IDs

Boot the NixOS ISO and identify your disks:

```bash
# List all disks with stable identifiers
ls -la /dev/disk/by-id/

# Sample output:
# ata-SAMSUNG_870_EVO_256GB_S1234567890ABCDEF -> ../../sda
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456789 -> ../../sdb
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456790 -> ../../sdc
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456791 -> ../../sdd
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456792 -> ../../sde
```

### Alternative: Using lsblk with Model Info

```bash
# Get detailed disk info
lsblk -d -o NAME,SIZE,MODEL,SERIAL

# Sample output:
# NAME   SIZE MODEL                      SERIAL
# sda    256G Samsung SSD 870 EVO 256GB  S1234567890ABCDEF
# sdb    3.0T SEAGATE Barracuda Pro      ZM123456789
# sdc    3.0T SEAGATE Barracuda Pro      ZM123456790
# sdd    3.0T SEAGATE Barracuda Pro      ZM123456791
# sde    3.0T SEAGATE Barracuda Pro      ZM123456792
```

### Alternative: Using smartctl (if installed)

```bash
# Query disk serials with smartctl
sudo smartctl -a /dev/sda | grep -i serial
sudo smartctl -a /dev/sdb | grep -i serial
# (etc. for each disk)
```

---

## Matching Hardware to Configuration

### For RAID1 (2-Disk Setup)

You need:
- 1x SSD (256GB boot drive)
- 2x HDDs (2TB each for RAID1 data array)

```bash
# Example from ls -la /dev/disk/by-id/:
# ata-SAMSUNG_870_EVO_256GB_S1234567890ABCDEF  <- Boot SSD
# ata-SEAGATE_BARRACUDA_2TB_ZM123456789        <- RAID1 Drive 1
# ata-SEAGATE_BARRACUDA_2TB_ZM123456790        <- RAID1 Drive 2
```

In `modules/disko/raid1.nix`:
```nix
boot = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SAMSUNG_870_EVO_256GB_S1234567890ABCDEF";
  ...
};

raid-1 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_2TB_ZM123456789";
  ...
};

raid-2 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_2TB_ZM123456790";
  ...
};
```

### For RAID10 (4-Disk Setup)

You need:
- 1x SSD (256GB boot drive)
- 4x HDDs (3TB each for RAID10 data array)

```bash
# Example from ls -la /dev/disk/by-id/:
# ata-SAMSUNG_870_EVO_256GB_S1234567890ABCDEF  <- Boot SSD
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456789    <- RAID10 Drive 1
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456790    <- RAID10 Drive 2
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456791    <- RAID10 Drive 3
# ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456792    <- RAID10 Drive 4
```

In `modules/disko/raid10.nix`:
```nix
boot = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SAMSUNG_870_EVO_256GB_S1234567890ABCDEF";
  ...
};

raid-1 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456789";
  ...
};

raid-2 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456790";
  ...
};

raid-3 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456791";
  ...
};

raid-4 = {
  type = "disk";
  device = "/dev/disk/by-id/ata-SEAGATE_BARRACUDA_PRO_3TB_ZM123456792";
  ...
};
```

---

## What If Disks Have Long Names?

Some disk IDs can be very long with model numbers, serials, and part numbers. That's OK:

```bash
# This is fine:
device = "/dev/disk/by-id/ata-SAMSUNG_SSD_870_EVO_256GB_S1234567890ABCDEF_LONG_MODEL_NAME";

# You can verify it points to the right disk:
ls -la /dev/disk/by-id/ata-SAMSUNG_SSD_870_EVO_256GB_S1234567890ABCDEF_LONG_MODEL_NAME
# Should output: ... -> ../../sda (or your correct device)
```

---

## Installation Workflow Summary

1. **Boot ISO** on target hardware
2. **Run:** `ls -la /dev/disk/by-id/` to see all disks
3. **Clone repo:** `git clone https://github.com/dalenromelien/nixos-homelab-v2.git`
4. **Edit disko config:**
   - `modules/disko/raid1.nix` (for RAID1) or
   - `modules/disko/raid10.nix` (for RAID10)
5. **Replace** all `CHANGE_ME_*` placeholders with your actual disk IDs
6. **Run disko:** `sudo disko -m disko -c flake.nix#homelab-raid1` (or raid10)
7. **Run installer:** `sudo nixos-install --flake .#homelab-raid1` (or raid10)
8. **Reboot**

---

## Troubleshooting

**Q: I don't see my disks in /dev/disk/by-id/**
A: They might use a different prefix. Try:
```bash
ls -la /dev/disk/by-id/nvme-*  # for NVMe SSDs
ls -la /dev/disk/by-path/      # for all disks by path
```

**Q: My disk IDs are very short (e.g., sda, sdb)**
A: This suggests the ISO can't read disk metadata. Try:
```bash
# Some systems use shorter names; that's OK, use them
device = "/dev/disk/by-id/ata-SomeModel_Serial123";
# Verify with:
ls -l /dev/disk/by-id/ata-SomeModel_Serial123
```

**Q: Disko fails saying "device not found"**
A: Double-check:
- Device name is spelled correctly (case-sensitive)
- Device path is correct: `ls -la /dev/disk/by-id/ata-YOUR-ID`
- All disks are powered on and detected by BIOS

**Q: I want to use a mix of SSDs and HDDs with different capacities**
A: That's fine! Disko works with any mix. Just ensure:
- Boot drive is distinct from data drives
- You have enough capacity for your RAID level
- You correctly identify each disk by its serial number

---

## Notes for Future Reference

After installation, your disk configuration is stored in:
```bash
/etc/nixos/hardware-configuration.nix
```

This file is generated during installation and contains your specific disk setup. It's **not** managed by auto-update — only your local machine.

If you ever change disks or upgrade drives, you'll need to update this file manually before running `sudo nixos-rebuild switch`.

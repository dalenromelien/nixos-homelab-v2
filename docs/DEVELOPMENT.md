# Development Guide

This guide explains how to work with the multi-host flake configuration locally and for development purposes.

## Repository Structure

```
nixos-homelab-v2/
├── flake.nix                           # Entry point - defines all 4 configurations
├── flake.lock                          # Pinned dependency versions (commit this!)
│
├── hosts/                              # Host-specific configurations
│   ├── common/
│   │   └── default.nix                 # Shared base config (all hosts)
│   ├── nanopi/
│   │   └── default.nix                 # ARM dev/test target (aarch64-linux)
│   ├── iso/
│   │   ├── default.nix                 # Bootable installer ISO
│   │   └── flake-customer.nix          # Flake baked into ISO
│   ├── homelab-raid1/
│   │   └── default.nix                 # 2-disk RAID1 configuration
│   └── homelab-raid10/
│       └── default.nix                 # 4-disk RAID10 configuration
│
├── modules/                            # Reusable configuration modules
│   ├── base.nix                        # Common base config (users, SSH, nix settings)
│   ├── disko/
│   │   ├── raid1.nix                   # 2-disk RAID1 partition scheme
│   │   └── raid10.nix                  # 4-disk RAID10 partition scheme
│   └── services/
│       ├── auto-update.nix             # Systemd timer for auto-updates
│       ├── networking.nix              # Caddy reverse proxy, networking
│       ├── apps.nix                    # Services: Immich, Nextcloud, AdGuard, etc.
│       └── utils/
│           ├── ports.nix               # Service port definitions
│           └── adguard-filters.nix     # AdGuard filter URLs
│
└── docs/
    ├── INSTALLATION.md                 # Step-by-step setup guide
    ├── DISK_IDENTIFICATION.md          # How to find and configure disk IDs
    ├── DEVELOPMENT.md                  # This file
    └── nixos-ultimate-guide.md         # Detailed reference
```

## Available Configurations

### 1. Nanopi (aarch64-linux)

**Purpose:** Development and testing on ARM hardware.

**Build:**
```bash
sudo nixos-rebuild switch --flake .#nanopi
```

**Use case:**
- Test changes before deploying to homelab
- Lightweight dev environment
- No auto-update (you rebuild manually)

### 2. ISO (x86_64-linux)

**Purpose:** Bootable installer for new machines.

**Build:**
```bash
nix build .#nixosConfigurations.iso.config.system.build.isoImage
```

**Result:** `result/iso/nixos-*.iso`

**Use case:**
- Pre-configured with auto-update enabled
- Points to your GitHub repo for updates
- User picks homelab-raid1 or homelab-raid10 during install

### 3. Homelab-raid1 (x86_64-linux)

**Purpose:** Production homelab with 2-disk RAID1 setup.

**Disk layout:**
- `/dev/sda` — 256GB SSD (boot + root)
- `/dev/sdb`, `/dev/sdc` — 2x 2TB HDDs in RAID1 (`/data` mount)

**Build (on target hardware):**
```bash
sudo nixos-install --flake github:dalenromelien/nixos-homelab-v2#homelab-raid1
```

### 4. Homelab-raid10 (x86_64-linux)

**Purpose:** Production homelab with 4-disk RAID10 setup.

**Disk layout:**
- `/dev/sda` — 256GB SSD (boot + root)
- `/dev/sdb`, `/dev/sdc`, `/dev/sdd`, `/dev/sde` — 4x 3TB HDDs in RAID10 (`/data` mount)

**Build (on target hardware):**
```bash
sudo nixos-install --flake github:dalenromelien/nixos-homelab-v2#homelab-raid10
```

## Development Workflow

### Making Changes to Nanopi

1. **Edit a module or host config:**
   ```bash
   $EDITOR hosts/nanopi/default.nix
   # or
   $EDITOR modules/services/apps.nix
   ```

2. **Test locally:**
   ```bash
   # Dry-run to check for errors
   sudo nixos-rebuild switch --flake .#nanopi --show-trace

   # Full rebuild if happy
   sudo nixos-rebuild switch --flake .#nanopi
   ```

3. **Rollback if needed:**
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

### Making Changes to Homelab Configuration

Changes to `modules/`, `hosts/common/`, or `hosts/homelab-*` will apply to homelab machines via auto-update.

1. **Test locally on nanopi first** (different architecture but same module structure)
2. **Commit changes** to your GitHub repo on `main` branch
3. **Auto-update timer** runs Sunday 3am on all homelab machines
4. **Or trigger manually:**
   ```bash
   # On homelab machine
   sudo systemctl start nixos-autoupgrade.service
   ```

### Testing ISO Changes

1. **Edit ISO config:**
   ```bash
   $EDITOR hosts/iso/default.nix
   ```

2. **Rebuild ISO:**
   ```bash
   nix build --no-substitute .#nixosConfigurations.iso.config.system.build.isoImage
   ```

3. **Test on USB drive** (see INSTALLATION.md)

### Adding a New Service

1. **Create module:** `modules/services/my-service.nix`
   ```nix
   { config, lib, pkgs, ... }:
   let
     cfg = config.homelab.services;
   in
   {
     options.homelab.services.myService = {
       enable = lib.mkEnableOption "my new service";
     };

     config = lib.mkIf cfg.myService.enable {
       # service configuration here
     };
   }
   ```

2. **Import in host:** `hosts/homelab-raid10/default.nix`
   ```nix
   imports = [
     ../../modules/services/my-service.nix
   ];

   homelab.services.myService.enable = true;
   ```

3. **Rebuild and test:**
   ```bash
   sudo nixos-rebuild switch --flake .#homelab-raid10
   ```

## Flake Commands Reference

```bash
# Show all available configurations
nix flake show

# Update all inputs to latest versions
nix flake update

# Build a specific host (dry-run)
nix build .#nixosConfigurations.nanopi.config.system.build.toplevel --dry-run

# Build ISO
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Evaluate without building
nix flake check
```

## Debugging

### Check what changed between generations
```bash
sudo nix profile diff-closures /run/current-system $(nix build .#nixosConfigurations.homelab-raid10.config.system.build.toplevel --no-link --print-out-paths)
```

### View systemd unit logs
```bash
journalctl -u immich -n 50 -f        # Follow logs for immich service
journalctl -u nixos-autoupgrade -f   # Follow auto-update service
```

### Test auto-update locally
```bash
# On target machine
sudo nix flake update /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos
```

### Check what will be built before applying
```bash
sudo nixos-rebuild test --flake .#homelab-raid10
# Changes are applied but NOT made default boot target
# Reboot to test, or use --rollback after test
```

## Common Tasks

### Update to latest main branch
```bash
# On homelab machine
git -C /etc/nixos pull origin main
nix flake update /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos
```

### Rollback to previous generation
```bash
sudo nixos-rebuild switch --rollback
```

### Check current generation
```bash
sudo nixos-rebuild list-generations --flake .#nanopi
```

### Pin a specific input version
In `flake.nix`, update the URL:
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";  # Pin to specific version
```

Then:
```bash
nix flake lock
git add flake.lock
git commit -m "pin nixpkgs to 24.11"
```

## Tips

- **Always commit `flake.lock`** — it pins exact versions for reproducibility
- **Test on nanopi before pushing** — catch errors early
- **Use `--show-trace` for detailed errors** — helps debug module issues
- **Check `systemctl status` before rebuilding** — understand current state
- **Keep backups of working `flake.lock`** — for quick rollback

## Questions?

See `docs/nixos-ultimate-guide.md` for deeper NixOS concepts and troubleshooting.

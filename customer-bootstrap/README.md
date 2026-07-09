Customer bootstrap — quick start

This repo is a thin wrapper that delegates to the upstream homelab flake and applies local `configuration.nix` overrides.

Files
- `flake.nix` — re-exports upstream `home-server`, `nanopi`, and `iso` configurations, but merges your local `configuration.nix` on top of `home-server` so local overrides apply.
- `configuration.nix` — local overrides (hostname, extra packages, disable upstream services, etc.).
- `hosts/iso/disko/raid1.nix`, `raid10.nix`, `simple-raid10.nix` — disko templates; fill in your actual device IDs before install.

How to use on the installer ISO

1. On your build machine, create a customer branch from this repo.
2. Edit `hosts/iso/disko/raid1.nix` or `hosts/iso/disko/raid10.nix` with the actual disk IDs.
3. (Optional) Customize `configuration.nix` with local hostname/packages/settings.
4. Build a custom ISO from your main nixos-homelab-v2 repo with this branch, or use the generic ISO.

On the installer (booted from ISO):

```bash
# Clone this customer branch into the running installer environment
git clone --branch customer/<name> https://github.com/<you>/<your-repo>.git /root/homelab
cd /root/homelab

# Verify disko config is correct
cat hosts/iso/disko/raid1.nix

# Run the disko partitioner (choose the file that matches your layout)
sudo disko -m disko -c hosts/iso/disko/raid1.nix
# or
sudo disko -m disko -c hosts/iso/disko/raid10.nix

# Install NixOS using this flake (which wraps and extends the upstream flake)
sudo nixos-install --flake .#home-server

# Reboot when finished
sudo reboot
```

After install
- Auto-update timer will run every Sunday 3am.
- It rebuilds using `.#home-server` from this repo, which includes your local `configuration.nix` overrides.
- Push changes to this customer branch and the auto-update will pick them up on the next cycle.

Notes
- Keep all disk-specific IDs only in the customer branch; never commit `/etc/nixos/hardware-configuration.nix`.
- Local `configuration.nix` is optional; leave it empty if you just want the upstream defaults.

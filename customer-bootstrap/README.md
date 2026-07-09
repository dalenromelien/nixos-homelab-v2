Customer bootstrap — quick start

This repo is a minimal customer bootstrap that delegates to the upstream homelab flake.

How to use on the installer ISO

1. On your build machine, create a customer branch with pre-filled disk IDs in `hosts/iso/disko/`.
2. Build a custom ISO (optional) or use the generic ISO.

On the installer (booted from ISO):

```bash
# Clone this customer branch into the running installer environment
git clone --branch customer/<name> https://github.com/<you>/customer-repo.git /root/homelab
cd /root/homelab

# Inspect and edit disko templates if needed
helix hosts/iso/disko/raid1.nix
helix hosts/iso/disko/raid10.nix

# Run the disko partitioner (choose the file that matches your layout)
sudo disko -m disko -c hosts/iso/disko/raid1.nix
# or
sudo disko -m disko -c hosts/iso/disko/raid10.nix

# Install NixOS using the flake in this repo (delegates to your upstream flake)
sudo nixos-install --flake .#home-server

# Reboot when finished
sudo reboot
```

Notes
- Keep all disk-specific IDs only in the customer branch; do not commit hardware-configuration.nix back to upstream.
- Auto-update on the installed machine will rebuild using `.#home-server` from this repo — make sure the `flake.lock` points to the upstream flake you want tracked.

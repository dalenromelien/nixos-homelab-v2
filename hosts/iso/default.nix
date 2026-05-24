{ pkgs, modulesPath, ... }:
{
  imports = [
    ../common/default.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Bake config files into the ISO for easy access during installation
  # Users can reference these files with nixos-anywhere or manual installation
  environment.etc."nixos/flake.nix".source = ./flake-customer.nix;
  
  # Disko partitioning configurations - available on the ISO for reference/editing
  # Use with: nix run github:nix-community/nixos-anywhere -- --flake .#homelab-raid1 root@target
  environment.etc."nixos/disko/raid1.nix".source = ./disko/raid1.nix;
  environment.etc."nixos/disko/raid10.nix".source = ./disko/raid10.nix;
  environment.etc."nixos/disko/simple-raid10.nix".source = ./disko/simple-raid10.nix;
  
  # Installation README
  environment.etc."nixos/INSTALL.md".source = pkgs.writeText "INSTALL.md" ''
    # NixOS Homelab Installation

    Available configurations on this ISO:
    - /etc/nixos/flake.nix            # Customer auto-update flake
    - /etc/nixos/disko/raid1.nix      # 2-disk RAID1 (2x 2TB)
    - /etc/nixos/disko/raid10.nix     # 4-disk RAID10 (4x 3TB)
    - /etc/nixos/disko/simple-raid10.nix # 4-disk RAID10 (generic device names)

    ## Installation via nixos-anywhere

    From your main machine:
    ```
    # For RAID1 config
    nix run github:nix-community/nixos-anywhere -- \
      --flake github:dalenromelien/nixos-homelab-v2#homelab-raid1 \
      root@192.168.1.100

    # For RAID10 config
    nix run github:nix-community/nixos-anywhere -- \
      --flake github:dalenromelien/nixos-homelab-v2#homelab-raid10 \
      root@192.168.1.100
    ```

    ## Before installation

    Edit the disko config to match your disk serial numbers:
    ```
    cat /etc/nixos/disko/raid10.nix | less
    # Look for: ata-CHANGE_ME_* and replace with actual serial from:
    # lsblk -S or: ls -la /dev/disk/by-id/
    ```
  '';
}

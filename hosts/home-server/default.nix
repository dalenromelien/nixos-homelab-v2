{ pkgs, ... }:
{
  imports = [
    ../common/default.nix
    ../common/services.nix
    ../../disk-config.nix
    ../../modules/services/nixflix.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # auto pull from my flake everyday in event of new releases
  system.autoUpgrade = {
    enable = true;
    flake = "github:dalenromelien/nixos-homelab-v2#home-server";
    dates = "daily"; # or any systemd calendar spec
    randomizedDelaySec = "45min";
  };

   # Shared group just for "can create things in /data"
  users.groups.storage = {};

  users.users.immich.extraGroups = [ "storage" ];
  # users.users.nextcloud.extraGroups = [ "storage" ];
  # users.users.adguardhome.extraGroups = [ "storage" ];

  systemd.tmpfiles.rules = [
    "d /data 1775 root storage - -"
  ];

  sops.age.keyFile = "/root/.config/sops/age/keys.txt";
}

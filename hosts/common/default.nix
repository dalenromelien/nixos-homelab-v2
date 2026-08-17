{ config, pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

   # Shared group just for "can create things in /data"
  users.groups.storage = {};

  users.users.immich.extraGroups = [ "storage" ];
  # users.users.nextcloud.extraGroups = [ "storage" ];
  # users.users.adguardhome.extraGroups = [ "storage" ];

  systemd.tmpfiles.rules = [
    "d /data 1775 root storage - -"
  ];

  boot.loader.grub.enable = false;

  services.netbird.enable = true;

  users.users.root.initialPassword = "nix";

  security.sudo.wheelNeedsPassword = false;

  # auto pull from my flake everyday in event of new releases
  system.autoUpgrade = {
    enable = true;
    flake = "github:dalenromelien/nixos-homelab-v2#home-server";
    dates = "daily"; # or any systemd calendar spec
    randomizedDelaySec = "45min";
  };

  # created this user to fix phpfpm-nextloud module
  users.users.nginx = {
    isSystemUser = true;
    group = "nginx";
  };
  users.groups.nginx = {};

  environment.systemPackages = with pkgs; [
    helix
    curl
    wget
    git
    disko
    nssTools
  ];

  system.stateVersion = "26.05";
}
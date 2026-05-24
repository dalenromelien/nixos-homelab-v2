{ config, pkgs, lib, ... }:
{
  imports = [
    ../common/default.nix
    ../../modules/services/auto-update.nix
  ];

  homelab.services.autoUpdate.enable = false;

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS";
    fsType = "ext4";
  };

  networking.hostName = "nanopi-r5s";
  networking.useDHCP = lib.mkDefault true;

  boot.binfmt.emulatedSystems = ["x86_64-linux"];
}

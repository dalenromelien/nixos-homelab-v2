{ config, pkgs, lib, ... }:
{
  imports = [
    ../common/default.nix
    ../../modules/disko/raid1.nix
    ../../modules/services/auto-update.nix
    ../../modules/services/networking.nix
    ../../modules/services/apps.nix
  ];

  homelab.services.autoUpdate.enable = true;

  fileSystems."/data" = {
    device = "/dev/md/raid1";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  boot.supportedFilesystems = [ "ext4" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-homelab";
}

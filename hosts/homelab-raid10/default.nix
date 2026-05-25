{ config, pkgs, lib, ... }:
{
  imports = [
    ../common/default.nix
    ../iso/disko/raid10.nix
    ../../modules/services/auto-update.nix
    ../../modules/services/networking.nix
    ../../modules/services/apps.nix
  ];

  homelab.services.autoUpdate.enable = true;

  fileSystems."/data" = {
    device = "/dev/md/raid10";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  boot.supportedFilesystems = [ "ext4" ];
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/disk/by-id/CHANGE_ME_BOOT_DISK";
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-homelab";


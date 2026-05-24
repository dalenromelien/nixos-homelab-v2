{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/base.nix
  ];

  boot.loader.grub.enable = false;
}

{ pkgs, ... }:

{
  # Local configuration overrides go here.
  # This module is merged on top of the upstream homelab configuration,
  # so any settings defined here will override upstream defaults.

  # Example: customize the hostname
  networking.hostName = "home-server";

  # Example: add local packages that override upstream
  environment.systemPackages = with pkgs; [
    vim
    htop
  ];

  # Example: disable a service that's enabled upstream (if needed)
  # services.immich.enable = false;

  # Keep all other upstream services and settings as-is
}

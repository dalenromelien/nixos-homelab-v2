{ ... }:
{
  imports = [
    ../../modules/services/auto-update.nix
    ../../modules/services/apps.nix
    ../../modules/services/networking.nix
  ];

  # Enable auto-update for the home-server configuration
  homelab.services.autoUpdate.enable = true;
}

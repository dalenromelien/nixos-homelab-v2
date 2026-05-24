# Consumer setup:
# 1. Copy this repo's flake.nix to /etc/nixos
# 2. Run: nix flake update (generates flake.lock)
# 3. systemd timer handles updates automatically

{ config, lib, pkgs, ... }:

{
  # ============================================================================
  # AUTO-UPDATE: nix flake update + nixos-rebuild (daily at 3am)
  # ============================================================================

  systemd.services.nixos-autoupdate = {
    description = "Update NixOS from flake";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      WorkingDirectory = "/etc/nixos";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '${pkgs.nix}/bin/nix flake update && ${pkgs.nixos-rebuild}/bin/nixos-rebuild switch --flake .#homelab'
      '';
    };
  };

  systemd.timers.nixos-autoupdate = {
    description = "Auto-update NixOS daily at 3am";
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # ============================================================================
  # GARBAGE COLLECTION (weekly at 4am)
  # ============================================================================

  nix.gc = {
    automatic = true;
    dates = "*-*-* 04:00:00";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  # ============================================================================
  # ROLLBACK SUPPORT: keep 5 generations
  # ============================================================================

  boot.loader.systemd-boot.configurationLimit = 5;
}

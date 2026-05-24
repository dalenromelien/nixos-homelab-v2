{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.services;
in
{
  options.homelab.services = {
    autoUpdate.enable = lib.mkEnableOption "automatic NixOS updates from flake";
  };

  config = lib.mkIf cfg.autoUpdate.enable {
    systemd.services.nixos-autoupdate = {
      description = "Update NixOS from flake";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
      path = [ pkgs.nix ];
      script = ''
        cd /etc/nixos
        nix flake update
        nixos-rebuild switch --flake .
      '';
    };

    systemd.timers.nixos-autoupdate = {
      description = "Auto-update NixOS on schedule";
      timerConfig = {
        OnCalendar = "Sun *-*-* 03:00:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
      wantedBy = [ "timers.target" ];
    };

    nix.gc = {
      automatic = true;
      dates = "Sun *-*-* 04:00:00";
      options = "--delete-older-than 30d";
    };

    nix.settings.auto-optimise-store = true;

    boot.loader.systemd-boot.configurationLimit = 5;
  };
}

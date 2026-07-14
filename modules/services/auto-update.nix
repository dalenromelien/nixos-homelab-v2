{ config, lib, pkgs, ... }:
let
  cfg = config.homelab.services;
in
{
  options.homelab.services = {
    autoUpdate.enable = lib.mkEnableOption "automatic NixOS updates from flake";
    autoUpdate.remoteFlake = lib.mkOption {
      type = lib.types.str;
      default = "github:dalenromelien/nixos-homelab-v2";
      description = "Remote flake URL to use for auto-update rebuilds. By default it points at the upstream repo.";
    };
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
        if [ -n "${cfg.autoUpdate.remoteFlake}" ]; then
          nixos-rebuild switch --flake ${cfg.autoUpdate.remoteFlake}#home-server
        else
          nix flake update
          nixos-rebuild switch --flake .#home-server
        fi
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

    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
  };
}

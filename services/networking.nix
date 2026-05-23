{config, pkgs, lib, ...}:

let
  serverIP = "192.168.1.100";
  ports = import ./utils/ports.nix;
in
{
  services.caddy.enable = true;

  networking.hostName = "nanopi-r5s";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [22 80 443];

  services.caddy.virtualHosts = {
    "immich.home".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString ports.immich}
      tls internal
    '';

    "adguard.home".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString ports.adguard}
      tls internal
    '';

    "nextcloud.home".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString ports.nextcloud}
      tls internal
    '';
  };

  # Let nginx serve Nextcloud locally on 127.0.0.1:8080; Caddy will reverse-proxy to it.
  services.nginx.virtualHosts = {
    "${config.services.nextcloud.hostName}" = {
      listen = [ { addr = "127.0.0.1"; port = ports.nextcloud; } ];
    };
  };

  services.adguard.settings.filtering.rewrites = [
    { domain = "immich.home"; answer = serverIP; }
    { domain = "adguard.home"; answer = serverIP; }
    { domain = "nextcloud.home"; answer = serverIP; }
  ];
}

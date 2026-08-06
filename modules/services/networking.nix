{config, pkgs, lib, ...}:

let
  serverIP = "192.168.1.100";
  ports = import ./utils/ports.nix;
in
{
  services.caddy.enable = true;

  # need to disable nginx to let caddy run
  services.nginx.enable = false;

  # need to disable port 53 services to make room for adguard
  services.dnsmasq.enable = false;
  services.systemd.resolved.enable = false;

  networking.hostName = "nixos-homelab";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [22 53 80 443];
  networking.firewall.allowedUDPPorts = [53];

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

  services.adguardhome.settings.filtering.rewrites = [
    { domain = "immich.home"; answer = serverIP; }
    { domain = "adguard.home"; answer = serverIP; }
    { domain = "nextcloud.home"; answer = serverIP; }
  ];
}

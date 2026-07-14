{config, pkgs, lib, ...}:

let
  serverIP = "192.168.1.100";
  ports = import ./utils/ports.nix;
in
{
  services.caddy.enable = true;

  networking.hostName = "nixos-homelab";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [22 80 443];

  services.caddy.virtualHosts = {
    "immich-server.home".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString ports.immichServer}
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

    "immich-ui.home".extraConfig = ''
      reverse_proxy http://127.0.0.1:${toString ports.immichUi}
      tls internal
    '';
  };

  services.adguardhome.settings.filtering.rewrites = [
    { domain = "immich-server.home"; answer = serverIP; }
    { domain = "immich-ui.home"; answer = serverIP; }
    { domain = "adguard.home"; answer = serverIP; }
    { domain = "nextcloud.home"; answer = serverIP; }
  ];
}

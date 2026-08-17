{config, pkgs, lib, ...}:

let
  serverIP = "192.168.1.100";
  ports = import ./utils/ports.nix;
in
{
  services.caddy.enable = true;

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

  # This is needed so NGINX doesn't bind to 80/443 and nextcloud can run.
  services.nginx = {
    enable = true;
    virtualHosts."nextcloud.home" = {
      listen = [{ addr = "127.0.0.1"; port = 8080; }];
      # module injects the rest into this same vhost block
    };
  };

  services.adguardhome.settings.filtering.rewrites = [
    { domain = "immich.home"; answer = serverIP; }
    { domain = "adguard.home"; answer = serverIP; }
    { domain = "nextcloud.home"; answer = serverIP; }
  ];
}

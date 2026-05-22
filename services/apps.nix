{config, pkgs, lib, ...}:

{
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
  };

  services.caddy.virtualHosts."immich.home".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString config.services.immich.port}
    tls internal
  '';
    
}

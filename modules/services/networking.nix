{ config, pkgs, lib, ... }:

let
  serverIP  = "192.168.1.64";
  routerIP  = "192.168.1.1";      # your router's real LAN IP
  netbirdIP = "100.64.0.10";      # placeholder: the server's actual Netbird IP
  ports = import ./utils/ports.nix;

  lanDomain = "lan.home.arpa";    # used at home    -> serverIP
  vpnDomain = "vpn.home.arpa";    # used via Netbird -> netbirdIP

  # service name -> local port
  services = {
    immich    = ports.immich;
    adguard   = ports.adguard;
    nextcloud = ports.nextcloud;
  };

  # "immich.lan.home.arpa, immich.vpn.home.arpa" = { ... }
  mkVhost = name: port: lib.nameValuePair
    "${name}.${lanDomain}, ${name}.${vpnDomain}"
    {
      extraConfig = ''
        tls internal
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };
in
{
  networking.hostName = "home-server";

  # Static addressing: this box is the DHCP server, so it can't be a DHCP client
  networking.useDHCP = false;
  networking.interfaces.eno1 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = serverIP;
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = routerIP;
  networking.nameservers = [ "9.9.9.9" "1.1.1.1" ];  # not 127.0.0.1

  networking.firewall = {
    allowedTCPPorts = [ 22 53 80 443 ];
    allowedUDPPorts = [ 53 67 ];   # 67 = DHCP server
  };

  services.caddy = {
    enable = true;
    virtualHosts = lib.mapAttrs' mkVhost services;
  };

  # Keeps nginx off 80/443 so Caddy can have them (Nextcloud needs nginx)
  services.nginx = {
    enable = true;
    virtualHosts.${config.services.nextcloud.hostName} = {
      listen = [{ addr = "127.0.0.1"; port = ports.nextcloud; }];
    };
  };

  services.adguardhome.settings.filtering.rewrites = [
    { domain = "*.${lanDomain}"; answer = serverIP; }
    { domain = "*.${vpnDomain}"; answer = netbirdIP; }
  ];
}
{ config, lib, ... }:

let
  serverIP = "192.168.1.2";
  routerIP = "192.168.1.254";
  ports = import ./utils/ports.nix;

  lanDomain = "home";

  services = {
    immich    = ports.immich;
    adguard   = ports.adguard;
    nextcloud = ports.nextcloud;
  };

  mkVhost = name: port: lib.nameValuePair
    "${name}.${lanDomain}"
    {
      extraConfig = ''
        tls internal
        reverse_proxy http://127.0.0.1:${toString port}
      '';
    };
in
{
  networking.hostName = "home-server";

  networking.useDHCP = false;
  networking.interfaces.eno1 = {
    useDHCP = false;
    ipv4.addresses = [{
      address = serverIP;
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = routerIP;
  networking.nameservers = [ "127.0.0.1" ];

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  networking.firewall.interfaces.eno1 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 67 ];
  };
  networking.firewall.interfaces."nb-w0" = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
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

  services.adguardhome.settings = {
    filtering.rewrites = [
      { domain = "*.${lanDomain}"; answer = serverIP; enabled = true; }
    ];

    dhcp = {
      enabled = true;
      interface_name = "eno1";
      dhcpv4 = {
        gateway_ip = routerIP;
        subnet_mask = "255.255.255.0";
        range_start = "192.168.1.64";
        range_end = "192.168.1.200";
        lease_duration = 86400;
        icmp_timeout_msec = 0;
      };
      local_domain_name = "home";
    };

    dns = {
      bind_hosts = [ "0.0.0.0" ];
      upstream_dns = [
        "tls://dns.quad9.net"
        "tls://one.one.one.one"
      ];
      bootstrap_dns = [ "9.9.9.10" "149.112.112.10" "1.1.1.1" ];
    };
  };
}
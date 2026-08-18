{ config, lib, pkgs, ... }:

let
  ports = import ./utils/ports.nix;
in
{
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = ports.adguard;
    mutableSettings = true;
    settings = {
      dhcp = {
        enabled = true;
        interface_name = "eno1";
        dhcpv4 = {
          gateway_ip = "192.168.1.1";
          subnet_mask = "255.255.255.0";
          range_start = "192.168.1.101";
          range_end = "192.168.1.200";
          lease_duration = 86400;
          icmp_timeout_msec = 0;
        };
        local_domain_name = "home";
      };

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        upstream_dns = [
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
          "1.1.1.1"
        ];
      };

      filtering = {
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safe_search.enabled = false;
      };

      filters = map (url: { enabled = true; url = url; }) (import ./utils/adguard-filters.nix);
    };
  };
}

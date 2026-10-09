{ config, lib, pkgs, ... }:

let
  ports = import ./utils/ports.nix;
in
{
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = ports.adguard;
    mutableSettings = false;
    settings = {
      dhcp = {
        enabled = true;
        interface_name = "eno1";
        dhcpv4 = {
          gateway_ip = "192.168.1.254";
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

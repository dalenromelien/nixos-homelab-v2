{config, pkgs, lib, ...}:

let
  adguardFilterUrls = import ./utils/adguard-filters.nix;
  ports = import ./utils/ports.nix;
in
{
  services.immich = {
    enable = true;
    port = ports.immich;
    host = "127.0.0.1";
    mediaLocation = "/data/immich";
    environment.IMMICH_LOG_LEVEL = "warn";
  };

  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    port = ports.adguard;
    mutableSettings = true;
    # settings = {
    #   dhcp = {
    #     enabled = true;
    #     interface_name = "eno1";
    #     dhcpv4 = {
    #       gateway_ip = "192.168.1.1";
    #       range_start = "192.168.1.101";
    #       range_end = "192.168.1.200";
    #       lease_duration = 86400;
    #     };
    #     local_domain_name = "home";
    #   };

    #   dns = {
    #     bind_hosts = ["0.0.0.0"];
    #     upstream_dns = [
    #       "9.9.9.9#dns.quad9.net"
    #       "149.112.112.112#dns.quad9.net"
    #       "1.1.1.1"
    #     ];
    #   };

    #   filtering = {
    #     protection_enabled = true;
    #     filtering_enabled = true;
    #     parental_enabled = false;
    #     safe_search.enabled = false;
    #   };

    #   filters = map (url: { enabled = true; url = url; }) adguardFilterUrls;
    # };
  };

  # Nextcloud database (required for multi-service reliability)
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };

  environment.etc."nextcloud-admin-pass".text = "changeme";

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.home";
    datadir = "/data/nextcloud";
    database.createLocally = true;

    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "pgsql";
    };

    settings = {
      trusted_domains = [ "nextcloud.home" ];
      mail_smtpmode = "sendmail";
      mail_sendmailmode = "pipe";
    };

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks;
    };

    extraAppsEnable = true;
    https = true;
    autoUpdateApps.enable = true;
  };
}

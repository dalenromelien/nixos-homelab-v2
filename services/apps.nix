{config, pkgs, lib, ...}:

let
  adguardFilterUrls = import ./utils/adguard-filters.nix;
  ports = import ./utils/ports.nix;
in
{
  
  services.netbird.enable = true;

  services.immich = {
    enable = true;
    port = ports.immich;
    host = "0.0.0.0";
    openFirewall = true;
  };

  services.adguard = {
    enable  = true;
    host = "0.0.0.0";
    port = ports.adguard;
    mutableSettings = true;
    settings = {
      dhcp.enabled = true;

      dns = {
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

      filters = map (url: { enabled = true; url = url; }) adguardFilterUrls;
    };
  };

  environment.etc."nextcloud-admin-pass".text = "changeme";

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.home";
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";

    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) news contacts calendar tasks;
    };

    extraAppsEnable = true;

    https = true;
  };

  extraOptions = {
    mail_smtpmode = "sendmail";
    mail_sendmailmode = "pipe";
  };
    
}

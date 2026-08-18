{ config, pkgs, lib, ... }:
{
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

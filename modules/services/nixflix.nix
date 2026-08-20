{ config, lib, inputs, ... }:
{
  imports = [
    inputs.nixflix.nixosModules.default
  ];

  nixflix = {
    enable = true;
    mediaDir = "/data/media";
    stateDir = "/data/.state";
    mediaUsers = [ "root" ];

    caddy = {
      enable = true;
      tls.internal = true;
    };
    postgres.enable = true;

    flaresolverr.enable = true;

    sonarr = {
      enable = true;
      config = {
        apiKey._secret = config.sops.secrets."sonarr/api_key".path;
        hostConfig.password._secret = config.sops.secrets."sonarr/password".path;
      };
    };

    radarr = {
      enable = true;
      config = {
        apiKey._secret = config.sops.secrets."radarr/api_key".path;
        hostConfig.password._secret = config.sops.secrets."radarr/password".path;
      };
    };

    lidarr = {
      enable = true;
      config = {
        apiKey._secret = config.sops.secrets."lidarr/api_key".path;
        hostConfig.password._secret = config.sops.secrets."lidarr/password".path;
      };
    };

    prowlarr = {
      enable = true;
      config = {
        apiKey._secret = config.sops.secrets."prowlarr/api_key".path;
        hostConfig.password._secret = config.sops.secrets."prowlarr/password".path;
        indexers = [
          {name = "1337x";}
          {name = "The Pirate Bay";}
          {name = "AnimeTosho";}
          {name = "LimeTorrents";}
        ];
      };
    };

    # sabnzbd = {
    #   enable = true;
    #   settings = {
    #     misc = {
    #       api_key._secret = config.sops.secrets."sabnzbd/api_key".path;
    #       nzb_key._secret = config.sops.secrets."sabnzbd/nzb_key".path;
    #       username._secret = config.sops.secrets."sabnzbd/username".path;
    #       password._secret = config.sops.secrets."sabnzbd/password".path;
    #     };
    #   };
    # };

    jellyfin = {
      enable = true;
      apiKey._secret = config.sops.secrets."jellyfin/api_key".path;
      users.admin = {
        policy.isAdministrator = true;
        password._secret = config.sops.secrets."jellyfin/admin_password".path;
      };
    };

    seerr = {
      enable = true;
      apiKey._secret = config.sops.secrets."seerr/api_key".path;
    };
    
    vpn = {
      enable = true;
      wgConfFile = config.sops.secrets."wireguard-conf".path;
      accessibleFrom = ["192.168.1.0/24"];
    };

    # Explicitly keep the Starr apps off the VPN
    prowlarr.vpn.enable = false;
    sonarr.vpn.enable = false;
    radarr.vpn.enable = false;
    lidarr.vpn.enable = false;
  };

  sops.secrets = {
    "sonarr/api_key" = {};
    "sonarr/password" = {};
    "radarr/api_key" = {};
    "radarr/password" = {};
    "lidarr/api_key" = {};
    "lidarr/password" = {};
    "prowlarr/api_key" = {};
    "prowlarr/password" = {};
    # "sabnzbd/api_key" = {};
    # "sabnzbd/nzb_key" = {};
    # "sabnzbd/username" = {};
    # "sabnzbd/password" = {};
    "jellyfin/admin_password" = {};
    "jellyfin/api_key" = {};
    "seerr/api_key" = {};
    "wireguard-conf" = {
      sopsFile = ../../secrets/wg0.conf;   # explicit override — this IS a separate file
      format = "binary";
    };
  };
}

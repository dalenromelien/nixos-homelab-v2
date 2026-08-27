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
    };
    
    postgres.enable = true;

    flaresolverr.enable = true;

    theme = {
      enable = true;
      name = "overseerr";
    };

    torrentClients.qbittorrent = {
      enable = true;
      password = {
        _secret = config.sops.secrets."qbittorrent/password".path;
      };
      serverConfig = {
        Preferences = {
          WebUI = {
            Username = "admin";
            Password_PBKDF2 = "@ByteArray(gsfKcIQ8G4OnbODb+dkkCA==:cvgBTXZx60A+dPUKBt7zmCbqLqxBblBzUpHgDKiUuaGbOiQA3Eez/OCT58BbvZ0n84BfsmCUyr1u4PKQUHuXTQ==)";
          };
        };
      };
    };

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
          {name = "The Pirate Bay";}
          {name = "AnimeTosho";}
          {name = "LimeTorrents";}
        ];
      };
    };

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
    "jellyfin/admin_password" = {};
    "jellyfin/api_key" = {};
    "qbittorrent/password" = {};
    "seerr/api_key" = {};
    "wireguard-conf" = {
      sopsFile = ../../secrets/wg0.conf;   # explicit override — this IS a separate file
      format = "binary";
    };
  };
}

{ config, lib, pkgs, ... }:

let
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
}

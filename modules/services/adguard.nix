{ ... }:

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

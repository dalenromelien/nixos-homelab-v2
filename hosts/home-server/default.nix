{ ... }:
{
  imports = [
    ../common/default.nix
    ../common/services.nix
    ../../disk-config.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}

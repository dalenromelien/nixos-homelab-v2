{ ... }:
{
  imports = [
    ../common/default.nix
    ../common/services.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}

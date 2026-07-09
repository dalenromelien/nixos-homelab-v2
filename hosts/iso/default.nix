{ pkgs, modulesPath, ... }:
{
  imports = [
    ../common/default.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}

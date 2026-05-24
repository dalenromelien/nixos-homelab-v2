{ pkgs, modulesPath, ... }:
{
  imports = [
    ../common/default.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Bake the customer flake into the ISO
  environment.etc."nixos/flake.nix".source = ./flake-customer.nix;
  # insert disko raid1 and raid10 into environment etc for editing on the image.
}

{ pkgs, modulesPath, ... }:
{
  imports = [
    ../common/default.nix
    ../common/services.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Make necessary tools available on the ISO
  environment.systemPackages = with pkgs; [
    disko
    git
    helix
  ];

  # Add mutable template files to /etc/nixos/ on the ISO
  # These are regular editable files (not Nix store symlinks)
  isoImage.contents = [
    { source = ./disko/raid1.nix; target = "/etc/nixos/disko-raid1.nix"; }
    { source = ./disko/raid10.nix; target = "/etc/nixos/disko-raid10.nix"; }
    { source = ./flake-customer.nix; target = "/etc/nixos/flake.nix"; }
    { source = ../../configuration.nix.template; target = "/etc/nixos/configuration.nix.template"; }
  ];
}

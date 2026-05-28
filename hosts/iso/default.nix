{ pkgs, modulesPath, ... }:
{
  imports = [
    ../common/default.nix
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
    { source = pkgs.writeText "disko-raid1.nix" (builtins.readFile ./disko/raid1.nix); target = "/etc/nixos/disko-raid1.nix"; }
    { source = pkgs.writeText "disko-raid10.nix" (builtins.readFile ./disko/raid10.nix); target = "/etc/nixos/disko-raid10.nix"; }
    { source = pkgs.writeText "disko-simple-raid10.nix" (builtins.readFile ./disko/simple-raid10.nix); target = "/etc/nixos/disko-simple-raid10.nix"; }
    { source = pkgs.writeText "flake.nix" (builtins.readFile ./flake-customer.nix); target = "/etc/nixos/flake.nix"; }
  ];
}

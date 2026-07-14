{
  description = "NixOS Homelab Flake - Reproducible multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = { nixpkgs, disko, ... } @ inputs:
  let
    lib = nixpkgs.lib;
    hasFacterJson = builtins.pathExists ./facter.json;
    mkHost = { hostname, system, modules, description }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [ disko.nixosModules.disko ] ++ modules;
      };
  in
  {
    nixosConfigurations = {
      nanopi = mkHost {
        hostname = "nanopi";
        system = "aarch64-linux";
        description = "Nanopi R5S - Development/Test Target";
        modules = [
          ./hosts/nanopi/default.nix
        ];
      };

      home-server = mkHost {
        hostname = "home-server";
        system = "x86_64-linux";
        description = "Home Server - Central homelab service hub";
        modules = lib.concatLists [
          [
            disko.nixosModules.disko
            ./hosts/home-server/default.nix
          ]
          (if hasFacterJson then [ { hardware.facter.reportPath = ./facter.json; } ] else [])
        ];
      };

      iso = mkHost {
        hostname = "iso";
        system = "x86_64-linux";
        description = "NixOS Bootable Installer ISO";
        modules = [
          ./hosts/iso/default.nix
        ];
      };
    };
  };
}

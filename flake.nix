{
  description = "NixOS Homelab Flake - Reproducible multi-host configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, disko, ... } @ inputs:
  let
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
        modules = [
          ./hosts/home-server/default.nix
        ];
      };
    };
  };
}

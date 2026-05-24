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

      iso = mkHost {
        hostname = "iso";
        system = "x86_64-linux";
        description = "NixOS Bootable Installer ISO";
        modules = [
          ./hosts/iso/default.nix
        ];
      };

      homelab-raid1 = mkHost {
        hostname = "homelab-raid1";
        system = "x86_64-linux";
        description = "Homelab Server - 2-Disk RAID1 Configuration";
        modules = [
          ./hosts/homelab-raid1/default.nix
        ];
      };

      homelab-raid10 = mkHost {
        hostname = "homelab-raid10";
        system = "x86_64-linux";
        description = "Homelab Server - 4-Disk RAID10 Configuration";
        modules = [
          ./hosts/homelab-raid10/default.nix
        ];
      };
    };
  };
}

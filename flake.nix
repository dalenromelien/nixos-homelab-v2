{
  description = "NixOS Homelab Flake - Reproducible multi-host configuration";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
  };

  outputs = { nixpkgs, disko, sops-nix, nixflix, ... } @ inputs:
  let
    lib = nixpkgs.lib;
    hasFacterJson = builtins.pathExists ./facter.json;
    mkHost = { hostname, system, modules, description }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
        ] ++ modules;
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
            nixflix.nixosModules.default
            {
              nixpkgs.overlays = [
                (final: prev: {
                  caddy = prev.caddy.overrideAttrs (old: {
                    # temporary workaround: upstream nixflix is building a stale Caddy source hash
                    hash = "sha256-G4JUGEB6ptAu82noB6vayv32stOnZkUn7uGXq+I7vrQ=";
                  });
                })
              ];
            }
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

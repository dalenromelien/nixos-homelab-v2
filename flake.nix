i{
  
  description = "NixOS Flake for Beta home servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    inputs.disko.url = "github:nix-community/disko/latest";
  };

  outputs = { nixpkgs, ... }: @ inputs {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      system = "aarch64-linux";
      # use system = "x86_64-linux"; fror x86 and most normal machines.
      modules = [
        ./configuration.nix
        disko.nixosModules.disko
      ];
    };
  };
  
}

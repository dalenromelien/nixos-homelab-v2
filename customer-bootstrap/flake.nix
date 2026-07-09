{
  description = "Customer bootstrap flake — delegates to upstream homelab flake with local configuration override.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    homelab.url = "github:dalenromelien/nixos-homelab-v2";
    homelab.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, homelab, ... } @ inputs:
    {
      nixosConfigurations = {
        # Wrap the upstream home-server to include local configuration.nix
        home-server = homelab.nixosConfigurations.home-server.extendModules {
          modules = [ ./configuration.nix ];
        };

        # Re-export other upstream configurations if you prefer them
        nanopi = homelab.nixosConfigurations.nanopi;
        iso = homelab.nixosConfigurations.iso;
      };
    };
}

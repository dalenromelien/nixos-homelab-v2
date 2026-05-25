{
  description = "Homelab configuration - tracks dalenromelien/nixos-homelab-v2";
  
  inputs = {
    homelab.url = "github:dalenromelien/nixos-homelab-v2";
    nixpkgs.follows = "homelab/nixpkgs";
  };
  
  outputs = { homelab, ... }: {
    nixosConfigurations = homelab.nixosConfigurations;
  };
}

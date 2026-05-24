{
  description = "Homelab auto-update from dalenromelien/nixos-homelab-v2";
  
  inputs = {
    homelab-config.url = "github:dalenromelien/nixos-homelab-v2";
    homelab-config.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  
  outputs = { homelab-config, nixpkgs, ... }: {
    nixosConfigurations.homelab-raid1 = homelab-config.nixosConfigurations.homelab-raid1;
    nixosConfigurations.homelab-raid10 = homelab-config.nixosConfigurations.homelab-raid10;
  };
}

{
  description = "Customer bootstrap flake — thin wrapper delegating to upstream homelab flake.";

  inputs = {
    # Change this to your upstream repo if different
    homelab.url = "github:dalenromelien/nixos-homelab-v2";
  };

  outputs = { homelab, ... }:
    {
      # Re-export the upstream nixosConfigurations so installers can run:
      #   sudo nixos-install --flake .#home-server
      # or choose homelab-raid1 / homelab-raid10 if you prefer.
      nixosConfigurations = homelab.nixosConfigurations;
    };
}

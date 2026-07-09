{
  # Minimal local configuration file for customer repo.
  # This is an example; when using the wrapper flake that delegates to
  # the upstream homelab flake, the upstream configuration is used.
  # If you prefer to use local overrides, replace the flake outputs to
  # include this module in the modules list.

  imports = [];

  networking.hostName = "home-server";

  # Enable SSH so you can log in after install
  services.openssh.enable = true;
  users.users.root.initialPassword = "nix";

  # Basic packages available on the installer/remnant system
  environment.systemPackages = with pkgs; [ vim git curl ];

  system.stateVersion = "25.11";
}

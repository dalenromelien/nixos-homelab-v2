{ config, pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  boot.loader.grub.enable = false;

  services.netbird.enable = true;

  users.users.root.initialPassword = "nix";

  services.caddy.package = lib.mkForce (pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddyserver/replace-response@v0.0.0-20250618171559-80962887e4c6" ];
    hash = "sha256-G4JUGEB6ptAu82noB6vayv32stOnZkUn7uGXq+I7vrQ=";
  });

  security.sudo.wheelNeedsPassword = false;

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
  };

  # created this user to fix phpfpm-nextloud module
  users.users.nginx = {
    isSystemUser = true;
    group = "nginx";
  };
  users.groups.nginx = {};

  environment.systemPackages = with pkgs; [
    helix
    curl
    wget
    git
    disko
    nssTools
    age
    sops
    jq
  ];

  system.stateVersion = "26.05";
}
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
  ];

  system.stateVersion = "26.05";
}
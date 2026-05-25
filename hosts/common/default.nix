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

  environment.systemPackages = with pkgs; [
    helix
    curl
    wget
    git
  ];

  system.stateVersion = "25.11";
}
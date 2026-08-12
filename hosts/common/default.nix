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

  systemd.tmpfiles.rules = [
    # d  path       mode  user  group    age
    "d  /data       2775  root  storage  -"
  ];

  boot.loader.grub.enable = false;

  services.netbird.enable = true;

  users.users.root.initialPassword = "nix";

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    helix
    curl
    wget
    git
    disko
    nssTools
  ];

  system.stateVersion = "26.05";
}
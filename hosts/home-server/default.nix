{ pkgs, ... }:
{
  imports = [
    ../common/default.nix
    ../common/services.nix
    ../../disk-config.nix
    ../../modules/services/nixflix.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  environment.systemPackages = with pkgs; [
    age
    sops
  ];
}

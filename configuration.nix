{ config, pkgs, lib, ... }:

{
    imports = [
      ./services/disko.nix
      ./services/auto-update.nix
      ./services/networking.nix
      ./services/apps.nix
    ];
    
    nixpkgs.config.allowUnfree = true;

    fileSystems."/" = {
    	device = "/dev/disk/by-label/NIXOS";
	    fsType = "ext4";
    };

    # Mount RAID 10 array for app data
    fileSystems."/data" = {
      device = "/dev/md/raid10";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    services.openssh = {
        enable = true;
        settings = {
	        PermitRootLogin = "yes";
	        PasswordAuthentication = true;
        };
    };

    users.users.root.initialPassword = "nix";

    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = with pkgs; [
    	helix
     	curl
    	wget
    ];
    
    boot.loader.grub.enable = false;

    system.stateVersion = "25.11";
}

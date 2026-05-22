{ config, pkgs, lib, ... }:

{
    imports = [
      ./services/networking.nix
      ./services/apps.nix
    ];
    nixpkgs.config.allowUnfree = true;
    networking.hostName = "nanopi-r5s";
    networking.useDHCP = lib.mkDefault true;
    networking.firewall.allowedTCPPorts = [22];

    fileSystems."/" = {
    	device = "/dev/disk/by-label/NIXOS";
	    fsType = "ext4";
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    
    services.openssh = {
        enable = true;
        settings = {
	        PermitRootLogin = "yes";
	        PasswordAuthentication = true;
        };
    };

    services.netbird.enable = true;

    users.users.dalen = {
    	isNormalUser = true;
    	extraGroups = ["wheel"];
     	initialPassword = "nix";
    };

    users.users.root.initialPassword = "nix";

    security.sudo.wheelNeedsPassword = false;

    environment.systemPackages = with pkgs; [
    	helix
     	curl
    	wget
    	git
    ];
    
    boot.loader.grub.enable = false;

    system.stateVersion = "25.11";
}

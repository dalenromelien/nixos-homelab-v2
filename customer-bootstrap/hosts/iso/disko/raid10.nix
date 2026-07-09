{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_BOOT_SERIAL";
        content = {
          type = "gpt";
          partitions = {
            BOOT = { size = "1M"; type = "EF02"; };
            ESP = {
              size = "500M"; type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; mountOptions = [ "umask=0077" ]; };
            };
            root = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; }; };
          };
        };
      };

      raid-1 = { type = "disk"; device = "/dev/disk/by-id/ata-CHANGE_ME_RAID1_SERIAL"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-2 = { type = "disk"; device = "/dev/disk/by-id/ata-CHANGE_ME_RAID2_SERIAL"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-3 = { type = "disk"; device = "/dev/disk/by-id/ata-CHANGE_ME_RAID3_SERIAL"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-4 = { type = "disk"; device = "/dev/disk/by-id/ata-CHANGE_ME_RAID4_SERIAL"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
    };

    mdadm = {
      raid10 = {
        type = "mdadm";
        level = 10;
        metadata = "1.0";
        content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/data"; }; }; }; };
      };
    };
  };
}

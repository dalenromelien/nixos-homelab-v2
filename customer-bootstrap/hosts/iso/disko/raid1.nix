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

      raid-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID1_SERIAL";
        content = { type = "gpt"; partitions = { raid1 = { size = "100%"; content = { type = "mdraid"; name = "raid1"; }; }; }; };
      };

      raid-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID2_SERIAL";
        content = { type = "gpt"; partitions = { raid1 = { size = "100%"; content = { type = "mdraid"; name = "raid1"; }; }; }; };
      };
    };

    mdadm = {
      raid1 = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/data"; }; }; }; };
      };
    };
  };
}

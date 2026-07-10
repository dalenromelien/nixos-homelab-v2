{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/ata-GIGASTONE_SSD_256GB_GSTGGJACVE25191336";
        content = {
          type = "gpt";
          partitions = {
            boot = { size = "1M"; type = "EF02"; };
            ESP = {
              size = "500M"; type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; mountOptions = [ "umask=0077" ]; };
            };
            root = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; }; };
          };
        };
      };

      raid-1 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00DC0B0_WD-WMC1T0065232"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-2 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00DC0B0_WD-WMC1T0939118"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-3 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00DC0B0_WD-WMC1T1884750"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      raid-4 = { type = "disk"; device = "/dev/disk/by-id/ata-WDC_WD30EZRX-00SPEB0_WD-WCC4E5XL64P0"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
    };

    mdadm = {
      raid10 = {
        type = "mdadm";
        level = 10;
        content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/data"; }; }; }; };
      };
    };
  };
}

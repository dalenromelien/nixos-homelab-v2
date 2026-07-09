{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            BOOT = { size = "1M"; type = "EF02"; };
            ESP = { size = "500M"; type = "EF00"; content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; mountOptions = [ "umask=0077" ]; }; };
            root = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; }; };
          };
        };
      };

      one = { type = "disk"; device = "/dev/sdb"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      two = { type = "disk"; device = "/dev/sdc"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      three = { type = "disk"; device = "/dev/sdd"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
      four = { type = "disk"; device = "/dev/sde"; content = { type = "gpt"; partitions = { raid10 = { size = "100%"; content = { type = "mdraid"; name = "raid10"; }; }; }; }; };
    };

    mdadm = {
      raid10 = { type = "mdadm"; level = 10; metadata = "1.0"; content = { type = "gpt"; partitions = { data = { size = "100%"; content = { type = "filesystem"; format = "ext4"; mountpoint = "/data"; }; }; }; }; };
    };
  };
}

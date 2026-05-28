{
  disko.devices = {
    disk = {
      # 256GB SSD - Boot drive only (no RAID)
      ssd = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            BOOT = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      # 3TB HDD 1 - Data RAID 10
      one = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            raid10 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid10";
              };
            };
          };
        };
      };

      # 3TB HDD 2 - Data RAID 10
      two = {
        type = "disk";
        device = "/dev/sdc";
        content = {
          type = "gpt";
          partitions = {
            raid10 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid10";
              };
            };
          };
        };
      };

      # 3TB HDD 3 - Data RAID 10
      three = {
        type = "disk";
        device = "/dev/sdd";
        content = {
          type = "gpt";
          partitions = {
            raid10 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid10";
              };
            };
          };
        };
      };

      # 3TB HDD 4 - Data RAID 10
      four = {
        type = "disk";
        device = "/dev/sde";
        content = {
          type = "gpt";
          partitions = {
            raid10 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid10";
              };
            };
          };
        };
      };
    };

    mdadm = {
      # RAID 10 across 4x 3TB HDDs
      raid10 = {
        type = "mdadm";
        level = 10;
        metadata = "1.0";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/data";
              };
            };
          };
        };
      };
    };
  };
}

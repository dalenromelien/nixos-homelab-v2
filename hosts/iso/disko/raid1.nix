{
  disko.devices = {
    disk = {
      # Boot drive (256GB SSD) - STABLE ID
      # Find with: ls -la /dev/disk/by-id/ | grep -i ata
      # Example: ata-SAMSUNG_870_EVO_256GB_S123456789
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_BOOT_SERIAL";
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

      # Data drive 1 (2TB HDD) - RAID 1
      # Find with: ls -la /dev/disk/by-id/ | grep -i ata | grep -i 2TB
      # Example: ata-SEAGATE_BARRACUDA_2TB_S123456789
      raid-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID1_SERIAL";
        content = {
          type = "gpt";
          partitions = {
            raid1 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };

      # Data drive 2 (2TB HDD) - RAID 1
      raid-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID2_SERIAL";
        content = {
          type = "gpt";
          partitions = {
            raid1 = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
    };

    mdadm = {
      # RAID 1 across 2x 2TB HDDs
      raid1 = {
        type = "mdadm";
        level = 1;
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

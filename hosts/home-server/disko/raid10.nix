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

      # Data drive 1 (3TB HDD) - RAID 10
      # Find with: ls -la /dev/disk/by-id/ | grep -i ata | grep -i 3TB
      # Example: ata-SEAGATE_BARRACUDA_PRO_3TB_S987654321
      raid-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID1_SERIAL";
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

      # Data drive 2 (3TB HDD) - RAID 10
      raid-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID2_SERIAL";
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

      # Data drive 3 (3TB HDD) - RAID 10
      raid-3 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID3_SERIAL";
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

      # Data drive 4 (3TB HDD) - RAID 10
      raid-4 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-CHANGE_ME_RAID4_SERIAL";
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

{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-TOSHIBA_19LPA970PNWP";
        content = {
          type = "gpt";
          partitions = {
            boot = { size = "1M"; type = "EF02"; };
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

      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-T-FORCE_T253TY001T";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/DATA/.media/SSD-Storage";
              };
            };
          };
        };
      };

      raid-1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-ST4000NM0033-9ZM_1";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = { type = "mdraid"; name = "raid1"; };
            };
          };
        };
      };

      raid-2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD42PURZ-85B4YY0";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
              content = { type = "mdraid"; name = "raid1"; };
            };
          };
        };
      };
    };

    mdadm = {
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

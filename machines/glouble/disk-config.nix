# Example to create a bios compatible gpt partition
{ lib, ... }:
{
  disko.devices = {
    disk = {
      nvme1 = {
        # samsung
        device = lib.mkDefault "/dev/disk/by-id/nvme-eui.0025385751a00c5d";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              name = "ESP";
              size = "32G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efi";
                mountOptions = [
                  "defaults"
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "ssd.ssd1";
                extraFormatArgs = [
                  "--durability=1"
                  # "--discard"
                  # "--data_allowed=user"
                ];
              };
            };
          };
        };
      };
      nvme2 = {
        # lexar
        device = lib.mkDefault "/dev/disk/by-id/nvme-eui.0000000625094324caf25b036e000385";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "ssd.ssd2";
                extraFormatArgs = [
                  "--durability=1"
                  # "--discard"
                  # "--data_allowed=user"
                ];
              };
            };
          };
        };
      };
      alpha = {
        device = "/dev/disk/by-id/ata-OOS14000G_000AB2EC";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hdda.alpha";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
      beta = {
        device = "/dev/disk/by-id/ata-OOS14000G_000AEPBK";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hddb.beta";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
      gamma = {
        device = "/dev/disk/by-id/ata-OOS14000G_000EMSFT";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hddb.gamma";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
      delta = {
        device = "/dev/disk/by-id/ata-OOS14000G_000B0BLM";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hdda.delta";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
      epsilon = {
        device = "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJ8SEK";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hdda.epsilon";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
      zeta = {
        device = "/dev/disk/by-id/ata-WDC_WD140EDGZ-11B1PA0_7LGJAD7K";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            storage = {
              name = "storage";
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "mainfs";
                label = "hddb.zeta";
                extraFormatArgs = [
                  "--durability=1"
                  "--rotational"
                ];
              };
            };
          };
        };
      };
    };

    bcachefs_filesystems = {
      mainfs = {
        type = "bcachefs_filesystem";
        extraFormatArgs = [
          "--block_size=4k"
          "--errors=ro"
          "--data_replicas=2"
          "--metadata_replicas=2"
          "--data_checksum=crc32c"
          "--metadata_checksum=crc32c"
          "--compression=none"
          "--background_compression=none"
          "--journal_flush_delay=1000" # The default. Works when using hd-idle
          "--scrub_journal_max_rewind_secs=10" # To align with journal_flush_delay
          "--prjquota=1"

          "--promote_target=ssd"
          "--metadata_target=ssd"
          "--foreground_target=ssd"
          "--background_target=ssd"
        ];
        mountOptions = [
          "defaults"
          "verbose"

          # "degraded"
          # "continue"
          "x-systemd.device-timeout=300s"
          "x-systemd.mount-timeout=300s"
          "fsck"
          "fix_errors"
        ];
        passwordFile = "/tmp/bcachefs_password";
        mountpoint = "/";
        subvolumes = {
          "home" = { };
          "nix/store" = {
            inodeOptions = [
              "--data_replicas=1"
            ];
          };
          "tmp" = {
            inodeOptions = [
              "--data_replicas=1"
              "--data_checksum=none"
            ];
          };
          "root" = { };
          "var" = { };
          "storage/tier0" = {
            inodeOptions = [
              "--background_target=ssd"
              "--foreground_target=ssd"
              "--promote_target=ssd"
            ];
          };
          "storage/tier1" = {
            inodeOptions = [
              "--background_target=hdda"
              "--foreground_target=hdda"
              "--promote_target=ssd"
              "--erasure_code=1"
            ];
          };
          "storage/tier2" = {
            inodeOptions = [
              "--background_target=hddb"
              "--foreground_target=hddb"
              "--promote_target=ssd"
              "--erasure_code=1"
            ];
          };
        };
      };
    };
  };
}

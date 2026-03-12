# Example to create a bios compatible gpt partition
{ lib, ... }:
{
  disko.devices = {
    disk = {
      disk1 = {
        device = lib.mkDefault "/dev/nvme0n1";
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
              size = "3T";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  # Root volume
                  "/rootfs" = {
                    mountpoint = "/";
                  };
                  # tmp is not a tmpfs, so it is a bit more persistent across reboots.
                  "/tmp" = {
                    mountpoint = "/tmp";
                  };
                  "/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  "/nix" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/nix";
                  };
                };
              };
            };
            empty = {
              size = "100%";
            };
            ssd_alpha = {
              size = "140G";
              content = {
                type = "bcachefs";
                filesystem = "alpha";
                label = "ssd.ssd1";
              };
            };
            ssd_beta = {
              size = "140G";
              content = {
                type = "bcachefs";
                filesystem = "beta";
                label = "ssd.ssd1";
              };
            };
            ssd_gamma = {
              size = "140G";
              content = {
                type = "bcachefs";
                filesystem = "gamma";
                label = "ssd.ssd1";
              };
            };
            ssd_delta = {
              size = "140G";
              content = {
                type = "bcachefs";
                filesystem = "delta";
                label = "ssd.ssd1";
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
                filesystem = "alpha";
                label = "hdd.hdd1";
                extraFormatArgs = [
                  "--discard"
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
                filesystem = "beta";
                label = "hdd.hdd1";
                extraFormatArgs = [
                  "--discard"
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
                filesystem = "gamma";
                label = "hdd.hdd1";
                extraFormatArgs = [
                  "--discard"
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
                filesystem = "delta";
                label = "hdd.hdd1";
                extraFormatArgs = [
                  "--discard"
                ];
              };
            };
          };
        };
      };
    };

    bcachefs_filesystems =
      let
        template = {
          type = "bcachefs_filesystem";
          extraFormatArgs = [
            "--block_size=4k"
            "--errors=ro"
            "--data_replicas=1"
            "--metadata_replicas=1"
            "--data_checksum=crc32c"
            "--metadata_checksum=crc32c"
            "--compression=none"
            "--background_compression=none"
            "--journal_flush_delay=65000" # 65 seconds, because this must be longer than the suspend timeout because the drives otherwise don't spin down.
            "--promote_target=ssd"
            "--metadata_target=ssd"
            "--foreground_target=hdd"
            "--background_target=hdd"
          ];
          mountOptions = [
            "defaults"
            "verbose"
            # "fsck"
            # "fix errors"
            # "degraded"
            # "very_degraded"
            "continue"
            "x-systemd.device-timeout=300s"
            "x-systemd.mount-timeout=300s"
            # "version_upgrade=compatible"
          ];
        };
      in
      {
        # Example showing mounted subvolumes in a multi-disk configuration.
        alpha = {
          mountpoint = "/mnt/alpha";
        } // template;
        beta = {
          mountpoint = "/mnt/beta";
        } // template;
        gamma = {
          mountpoint = "/mnt/gamma";
        } // template;
        delta = {
          mountpoint = "/mnt/delta";
        } // template;
      };
  };
}

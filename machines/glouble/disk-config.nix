# Example to create a bios compatible gpt partition
{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            end = "32G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              # mountOptions = [
              #   "defaults"
              #   "fmask=0077"
              #   "dmask=0077"
              # ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "root";
              settings.allowDiscards = true;
              passwordFile = "/tmp/secret.key";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "verbose"
                  # "fsck"
                  # "fix errors"
                  "degraded"
                  "very_degraded"
                  "continue"
                  "x-systemd.device-timeout=300s"
                  "x-systemd.mount-timeout=300s"
                  # "version_upgrade=compatible"
                ];
              };
            };
          };
        };
      };
    };
  };
}

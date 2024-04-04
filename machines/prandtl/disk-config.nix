# Example to create a bios compatible gpt partition
{ lib, ... }:
{
  disko.devices = {
    disk.disk1 = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            name = "ESP";
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "defaults"
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          root = {
            name = "root";
            end = "-0";
            content = {
              type = "filesystem";
              format = "bcachefs";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}

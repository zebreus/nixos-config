{ pkgs, config, lib, ... }:
{
  options.modules.boot = {
    type = lib.mkOption {
      description = ''
        How to configure the boot loader. The default is "efi" which installs systemd-boot into `/boot/efi`.

        "legacy" uses grub for BIOS systems. "raspi" uses extlinux for Raspberry Pi.
      '';
      type = lib.types.enum [ "efi" "legacy" "raspi" ];
      default = "efi";
    };
  };


  config = {
    boot = {
      # tmp.cleanOnBoot = true;

      kernelPackages = pkgs.linuxPackages_latest;

      loader = {
        legacy = { };
        efi = {
          grub.enable = false;
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/boot/efi";
        };
        raspi = {
          grub.enable = false;
          loader.generic-extlinux-compatible.enable = true;
        };
      }.${config.modules.boot.type};
    };
  };
}

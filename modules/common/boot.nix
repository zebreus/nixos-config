{ pkgs, config, lib, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_7;

    loader = lib.mkMerge [
      { grub.enable = false; }
      (lib.mkIf (! config.boot.loader.generic-extlinux-compatible.enable) {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        efi.efiSysMountPoint = "/boot/efi";
      })
    ];
  };
}

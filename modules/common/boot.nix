{ pkgs, config, lib, ... }:
{
  options = {
    boot.noEfi = lib.mkEnableOption "Disable EFI boot";
  };

  config = {
    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      loader = lib.mkIf (! config.boot.noEfi) (lib.mkMerge [
        { grub.enable = false; }
        (lib.mkIf (! config.boot.loader.generic-extlinux-compatible.enable) {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
          efi.efiSysMountPoint = "/boot/efi";
        })
      ]);
    };
  };
}

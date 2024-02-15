{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_6_7;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
}

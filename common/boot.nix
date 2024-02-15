{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_6_1;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
}

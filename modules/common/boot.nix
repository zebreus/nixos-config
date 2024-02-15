{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_7;

    loader = {
      systemd-boot.enable = true;

      grub = {
        efiSupport = true;
        efiInstallAsRemovable = true;
      };

      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };
}

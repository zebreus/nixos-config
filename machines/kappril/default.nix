{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/borg-repo.nix
    ../../modules/auto-maintenance.nix
  ];


  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "23.11";
  networking = {
    hostName = "kappril";
    domain = "zebre.us";
  };
}

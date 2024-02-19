{ ... }:
{
  imports = [
    ./networking.nix
    ../../modules/common
    ../../modules/workstation
    ./hardware-configuration.nix
    # ../../modules/borg-repo.nix
  ];


  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "23.11";
  networking = {
    hostName = "kappril";
    domain = "zebre.us";
  };
}

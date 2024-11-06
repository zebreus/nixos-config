{ lib, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./framework.nix
    ../../modules
    # ./builders.nix
  ];

  system.stateVersion = "24.11";
  networking.hostName = "prandtl";
  modules.boot.type = "secure";
  nix.settings.max-jobs = lib.mkDefault 12;

  boot.initrd.systemd.enable = true;
}

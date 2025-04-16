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

  # Temporary for some weird USB drive
  boot = {
    extraModprobeConfig = ''
      options usb-storage quirks=174c:55aa:u
    '';
  };
}

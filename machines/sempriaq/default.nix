{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/auto-maintenance.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "sempriaq";
    domain = "zebre.us";
  };

  boot.tmp.cleanOnBoot = true;
  boot.noEfi = true;
}

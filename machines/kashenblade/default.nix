{ config, ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/matrix.nix
    ../../modules/auto-maintenance.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "kashenblade";
    domain = "zebre.us";
  };

  modules.matrix =
    {
      enable = true;
      baseDomain = "zebre.us";
      certEmail = "lennarteichhorn@googlemail.com";
    };
}

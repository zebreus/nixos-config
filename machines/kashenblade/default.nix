{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/matrix.nix
    ../../modules/dns.nix
    ../../modules/auto-maintenance.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "kashenblade";
    domain = "antibuild.ing";
  };

  modules.matrix =
    {
      enable = true;
      baseDomain = "zebre.us";
      certEmail = "lennarteichhorn@googlemail.com";
    };
}

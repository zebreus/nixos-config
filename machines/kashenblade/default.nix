{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "kashenblade";

  modules.authoritative_dns.enable = true;
  modules.matrix = {
    enable = true;
    baseDomain = "zebre.us";
    certEmail = "lennarteichhorn@googlemail.com";
  };
}

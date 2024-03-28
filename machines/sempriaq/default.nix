{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "sempriaq";

  modules.authoritative_dns.enable = true;
  modules.mail = {
    enable = true;
    baseDomain = "zebre.us";
    certEmail = "lennarteichhorn@googlemail.com";
  };
  modules.boot.type = "legacy";
}

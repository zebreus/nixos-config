{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "sempriaq";

  modules = {
    authoritative_dns.enable = true;
    mail = {
      enable = true;
      baseDomain = "zebre.us";
      certEmail = "lennarteichhorn@googlemail.com";
    };
    boot.type = "legacy";
  };
}

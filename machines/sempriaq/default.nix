{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/auto-maintenance.nix
    ../../modules/mail.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "sempriaq";
    domain = "antibuild.ing";
  };

  modules.mailserver =
    {
      enable = true;
      baseDomain = "zebre.us";
      certEmail = "lennarteichhorn@googlemail.com";
    };

  boot.tmp.cleanOnBoot = true;
  boot.noEfi = true;
}

{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ./storagebox.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "blanderdash";

  services.suckmore = {
    enable = true;
    baseDomain = "suckmore.org";
    port = "12742";
    enableCaching = true;
    email = "suckmore@zebre.us";
  };
}

{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "blanderdash";

  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };
}

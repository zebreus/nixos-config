{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/auto-maintenance.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "blanderdash";
    domain = "antibuild.ing";
  };
}

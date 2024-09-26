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
}

{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "kashenblade";

  # TODO: Don't limit it here, but make it default to 1 and increase per machine
  nix.settings = {
    max-jobs = 1;
    cores = 2;
  };
}

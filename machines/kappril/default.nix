{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "kappril";

  modules.borg-repo.enable = true;
  modules.boot.type = "raspi";
}

{ ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "kappril";

  modules.boot.type = "raspi";

  # Reduce log pollution to protect the SD card
  networking.firewall.logRefusedConnections = false;
}

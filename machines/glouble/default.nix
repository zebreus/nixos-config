{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "24.05";
  networking.hostName = "glouble";
}

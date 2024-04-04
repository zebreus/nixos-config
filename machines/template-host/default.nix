{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules/common
  ];

  system.stateVersion = "24.05";
  networking.hostName = "template-host";
}

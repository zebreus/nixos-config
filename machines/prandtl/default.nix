{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./framework.nix
    ../../modules
  ];

  system.stateVersion = "24.11";
  networking.hostName = "prandtl";
  modules.boot.type = "secure";
}

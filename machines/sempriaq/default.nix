{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "23.11";
  networking.hostName = "sempriaq";

  modules = {
    boot.type = "legacy";
  };
}

{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "24.05";
  networking.hostName = "prandtl";
  modules = {
    auto-maintenance.enable = false;
    boot.type = "legacy";
    desktop.enable = true;
    workstation.enable = true;
  };
}

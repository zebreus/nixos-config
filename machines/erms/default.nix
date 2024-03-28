{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
    ../../modules
  ];

  system.stateVersion = "22.05";
  networking.hostName = "erms";

  modules.auto-maintenance.enable = false;
  modules.desktop.enable = true;
  modules.workstation.enable = true;
}


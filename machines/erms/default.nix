{
  imports = [
    ../../modules
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
  ];

  system.stateVersion = "22.05";
  networking = {
    hostName = "erms";
  };

  modules.auto-maintenance.enable = false;
  modules.desktop.enable = true;
  modules.workstation.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}


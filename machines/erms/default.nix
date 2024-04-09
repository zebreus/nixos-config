{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
    ../../modules
  ];

  system.stateVersion = "22.05";
  networking.hostName = "erms";

  modules = {
    auto-maintenance.enable = false;
    desktop.enable = true;
    workstation.enable = true;
  };

  boot = {
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
    '';
  };
}


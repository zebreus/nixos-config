{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
    ./thinkmorse.nix
    ../../modules
  ];

  system.stateVersion = "22.05";
  networking.hostName = "erms";

  services.thinkmorse = {
    enable = true;
    message = "Hello World!";
    devices = [
      "tpacpi::lid_logo_dot"
    ];
    speed = "0.3";
  };

  modules = {
    desktop.enable = true;
    workstation.enable = true;
  };

  boot = {
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
    '';
  };
}


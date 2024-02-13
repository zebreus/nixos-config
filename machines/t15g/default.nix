{
  imports = [
    ../../common.nix
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  networking = {
    hostName = "t15g";
  };

  system.stateVersion = "22.05";
}


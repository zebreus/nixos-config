{
  imports = [
    ../../common/common
    ../../common/desktop
    ../../common/docker.nix
    ../../common/libvirt.nix
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
  ];

  networking = {
    hostName = "t15g";
  };

  system.stateVersion = "22.05";
}


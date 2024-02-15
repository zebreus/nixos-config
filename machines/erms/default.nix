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
    hostName = "erms";
  };

  system.stateVersion = "22.05";
}


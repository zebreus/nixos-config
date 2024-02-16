{
  imports = [
    ../../modules/common
    ../../modules/desktop
    ../../modules/docker.nix
    ../../modules/libvirt.nix
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
  ];

  networking = {
    hostName = "erms";
    domain = "zebre.us";
  };

  system.stateVersion = "22.05";
}


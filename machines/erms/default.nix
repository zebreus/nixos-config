{
  imports = [
    ../../modules/common
    ../../modules/desktop
    ../../modules/workstation
    ../../modules/docker.nix
    ../../modules/libvirt.nix
    ./hardware-configuration.nix
    ./nvidia.nix
    ./webcam.nix
  ];

  system.stateVersion = "22.05";
  networking = {
    hostName = "erms";
    domain = "zebre.us";
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}


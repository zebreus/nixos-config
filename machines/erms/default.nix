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

  system.stateVersion = "22.05";
  networking = {
    hostName = "erms";
    domain = "zebre.us";
  };


  age.secrets.ssh_host_key = {
    file = ../../secrets/erms_ed25519.age;
    owner = "root";
    group = "root";
    mode = "0400";
    path = "/etc/ssh/ssh_host_ed25519_key";
  };

  age.secrets.ssh_host_key_pub = {
    file = ../../secrets/erms_ed25519_pub.age;
    owner = "root";
    group = "root";
    mode = "0444";
    path = "/etc/ssh/ssh_host_ed25519_key.pub";
  };

  age.secrets.wirguard_key = {
    file = ../../secrets/erms_wireguard.age;
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}


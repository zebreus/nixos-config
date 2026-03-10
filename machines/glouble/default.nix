{
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../modules
  ];

  system.stateVersion = "25.11";
  networking.hostName = "glouble";

  # Allow nested virtualization
  boot = {
    extraModprobeConfig = ''
      options kvm_intel nested=1
    '';
  };
}

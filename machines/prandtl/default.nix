{ lib, ... }: {
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./framework.nix
    ../../modules
    # ./builders.nix
  ];

  system.stateVersion = "24.11";
  networking.hostName = "prandtl";
  modules.boot.type = "secure";
  nix.settings.max-jobs = lib.mkDefault 12;

  # Temporary for pentesting course at uni
  networking.hosts = {
    "10.2.17.8" = [
      "friends.connect.usd"
      "connect.usd"
    ];
  };
}

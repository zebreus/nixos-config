{ config, ... }:
{
  imports = [
    ./networking.nix
    ./hardware-configuration.nix
    ../../modules/common
    ../../modules/matrix.nix
    ../../modules/auto-maintenance.nix
  ];

  system.stateVersion = "23.11";
  networking = {
    hostName = "kashenblade";
    domain = "zebre.us";
    wireguard.interfaces.antibuilding.peers = [
      {
        name = "janek-wireguard";
        allowedIPs = [ "10.71.4.0/24" "10.20.30.9/32" ];
        publicKey = "FQIG2kNEnUEbFfw3oCCstqG3lWjCranGXsfCglriJB8="; # TODO: Outsource to publicKeys.janek-wireguard;
        presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
        endpoint = "hstr.haertter.com:51821";
        # Send keepalives every 25 seconds.
        persistentKeepalive = 25;
      }
    ];
  };

  modules.matrix =
    {
      enable = true;
      baseDomain = "zebre.us";
      certEmail = "lennarteichhorn@googlemail.com";
    };
}

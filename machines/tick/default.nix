{ ... }:
{
  imports = [
    ../../modules/common/wireguard.nix
  ];

  networking.hostName = "tick";

  # You need to point this to the private key for tick
  # age.identityPaths = [ "/path/to/the/private/ssh/key" ];
}

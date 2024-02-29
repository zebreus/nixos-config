{ ... }:
{
  imports = [
    ../../modules/common/wireguard.nix
  ];

  networking.hostName = "tick";
}

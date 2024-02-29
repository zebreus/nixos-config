{ ... }:
{
  imports = [
    ../../modules/common/wireguard.nix
  ];

  networking.hostName = "tick";
  age.identityPaths = [ "/path/to/the/private/ssh/key" ];
}

{ ... }: {
  imports = [
    ./dn42
    ./babel.nix
    ./bird-proxy.nix
    ./wireguard.nix
  ];
}

{ ... }: {
  imports = [
    ./babel.nix
    ./bird-proxy.nix
    ./wireguard.nix
    ./wireguard-external.nix
  ];
}

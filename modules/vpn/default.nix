{ ... }: {
  imports = [
    ./bird-proxy.nix
    ./bird.nix
    ./routedbits.nix
    ./wireguard.nix
  ];
}

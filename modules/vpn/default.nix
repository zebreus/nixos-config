{ ... }: {
  imports = [
    ./bird-proxy.nix
    ./bird.nix
    ./wireguard.nix
  ];
}

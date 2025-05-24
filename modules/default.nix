{ ... }:
{
  imports = [
    ./authoritative-dns
    ./common
    ./desktop
    ./dn42
    ./vpn
    ./workstation
    ./auto-maintenance.nix
    ./besserestrichliste.nix
    ./bird-lg.nix
    ./borg-repo.nix
    ./essen-jetzt.nix
    ./mail.nix
    ./matrix.nix
    ./monitoring.nix
    ./ollama.nix
  ];
}

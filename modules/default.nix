{ ... }:
{
  imports = [
    ./common
    ./desktop
    ./vpn
    ./workstation
    ./authoritative-dns.nix
    ./auto-maintenance.nix
    ./bird-lg.nix
    ./borg-repo.nix
    ./headscale.nix
    ./monitoring.nix
    ./pogopeering.nix
    ./mail.nix
    ./matrix.nix
  ];
}

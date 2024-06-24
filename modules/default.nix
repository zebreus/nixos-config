{ ... }:
{
  imports = [
    ./common
    ./desktop
    ./dn42
    ./vpn
    ./workstation
    ./authoritative-dns.nix
    ./auto-maintenance.nix
    ./bird-lg.nix
    ./borg-repo.nix
    ./headscale.nix
    ./monitoring.nix
    ./mail.nix
    ./matrix.nix
  ];
}

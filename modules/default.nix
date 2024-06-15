{ ... }:
{
  imports = [
    ./common
    ./desktop
    ./workstation
    ./authoritative-dns.nix
    ./auto-maintenance.nix
    ./borg-repo.nix
    ./headscale.nix
    ./monitoring.nix
    ./mail.nix
    ./matrix.nix
  ];
}

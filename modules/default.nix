{ ... }:
{
  imports = [
    ./common
    ./desktop
    ./workstation
    ./authoritative-dns.nix
    ./auto-maintenance.nix
    ./borg-repo.nix
    ./monitoring.nix
    ./mail.nix
    ./matrix.nix
  ];
}

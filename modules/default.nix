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
    ./event.nix
    ./gulasch-sites.nix
    ./homeassistant.nix
    ./mail.nix
    ./matrix-lite.nix
    ./matrix.nix
    ./monitoring.nix
    ./n50camp.nix
    ./ollama.nix
    ./shared.nix
    ./photos.nix
    ./suckmore-org.nix
  ];
}

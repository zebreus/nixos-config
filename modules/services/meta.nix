# The meta service declarations. Imported by modules/helpers/machines.nix, so
# they exist wherever the meta config (machines.nix) is used, even without the
# service modules themselves (e.g. the exported vpn module).
{
  imports = [
    ./backup/meta.nix
    ./besserestrichliste/meta.nix
    ./bird-lg/meta.nix
    ./chaosdarmstadt/meta.nix
    ./dns/meta.nix
    ./essen-jetzt/meta.nix
    ./event/meta.nix
    ./gulasch-sites/meta.nix
    ./homeassistant/meta.nix
    ./mail/meta.nix
    ./matrix/meta.nix
    ./matrix-lite/meta.nix
    ./monitoring/meta.nix
    ./n50camp/meta.nix
    ./ollama/meta.nix
    ./photos/meta.nix
    ./rudelshopping/meta.nix
    ./suckmore-org/meta.nix
  ];
}

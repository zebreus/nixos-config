{ config
, lib
, ...
}:
let
  cfg = config.meta.self.gulaschSites;
in
{
  imports = [ ./dns.nix ];

  config = lib.mkIf cfg.enable {
    # The gulasch-site flake's module (imported in flake.nix) builds the static
    # sites from the Nix store and registers one ACME-enabled nginx virtual host
    # per subdomain under baseDomain (ocpncord, pokemon, drive, aisaas, c3cock,
    # testwebseite, testwebseite2, chat, angular, n50camp). DNS for these names is
    # served by ./dns.nix.
    services.gulasch-sites = {
      enable = true;
      baseDomain = cfg.baseDomain;
    };
  };
}

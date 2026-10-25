import ../../helpers/meta-service.nix "n50camp" ({ lib, ... }: {
  cardinality = "atMostOne";
  config = {
    # All base domains the event is reachable under. Every HTTP service is
    # served on all of these; services that cannot serve multiple domains are
    # served on primaryBaseDomain and the secondaries redirect to it.
    baseDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Base domains for the N50 camp event.";
    };
    primaryBaseDomain = lib.mkOption {
      type = lib.types.str;
      description = "Canonical base domain for the N50 camp event. Secondaries redirect here for services that cannot serve multiple domains.";
    };
  };
})

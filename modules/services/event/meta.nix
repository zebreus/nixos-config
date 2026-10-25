import ../../helpers/meta-service.nix "event" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "Base domain for the event.";
  };
})

import ../../helpers/meta-service.nix "gulaschSites" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    default = "gulasch.site";
    description = "Base domain for the exported static gulasch sites.";
  };
})

import ../../helpers/meta-service.nix "photos" ({ lib, ... }: {
  cardinality = "atMostOne";
  config = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "zebre.us";
      description = "Base domain for the photos server";
    };
    subDomain = lib.mkOption {
      type = lib.types.str;
      default = "photos";
      description = "Subdomain for the photos server";
    };
  };
})

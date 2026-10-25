import ../../helpers/meta-service.nix "rudelshopping" ({ lib, ... }: {
  cardinality = "atMostOne";
  config = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "rudelb.link";
      description = "Base domain for the rudelshopping server";
    };
    subDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Subdomain for the rudelshopping server. When null the service runs
        on the apex of baseDomain.
      '';
    };
  };
})

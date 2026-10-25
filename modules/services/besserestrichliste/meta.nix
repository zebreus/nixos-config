import ../../helpers/meta-service.nix "besserestrichliste" ({ lib, ... }: {
  cardinality = "atMostOne";
  config = {
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "wirs.ing";
      description = "Base domain for the besserestrichliste server";
    };
    subDomain = lib.mkOption {
      type = lib.types.str;
      default = "besserer";
      description = "Subdomain for the besserestrichliste server";
    };
  };
})

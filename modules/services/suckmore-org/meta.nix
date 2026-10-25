import ../../helpers/meta-service.nix "suckmoreOrg" ({ lib, ... }: {
  cardinality = "atMostOne";
  config = {
    enableCaching = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable aggressive caching for suckmore.org. This is not recommended if you are actively developing on the server, because you might not see your changes immediately.";
    };
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "suckmore.org";
      description = "Base domain for the suckmore.org server.";
    };
  };
})

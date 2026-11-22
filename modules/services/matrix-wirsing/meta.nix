import ../../helpers/meta-service.nix "matrixWirsing" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "Base domain for the matrix-wirsing server.";
  };
})

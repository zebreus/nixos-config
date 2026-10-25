import ../../helpers/meta-service.nix "matrixLite" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "Base domain for the matrix-lite server.";
  };
})

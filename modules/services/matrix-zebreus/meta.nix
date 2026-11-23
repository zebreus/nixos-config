import ../../helpers/meta-service.nix "matrixZebreus" ({ lib, ... }: {
  cardinality = "atMostOne";
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "Base domain for the matrix-zebreus server.";
  };
})

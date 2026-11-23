import ../../helpers/meta-service.nix "turn" ({ lib, ... }: {
  cardinality = "atMostOne";
  # The relay announces the host's public addresses.
  hostFilter = machine: machine.staticIp4 != null && machine.staticIp6 != null;
  config.baseDomain = lib.mkOption {
    type = lib.types.str;
    description = "The TURN server is turn.<baseDomain>.";
  };
})

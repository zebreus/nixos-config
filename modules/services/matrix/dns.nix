{ lib, config, ... }:
let
  staticRecord = subdomain: { staticIp4, staticIp6, ... }: (
    (if staticIp4 == null then "" else ''
      ${subdomain} IN A ${staticIp4}
    '')
    +
    (if staticIp6 == null then "" else ''
      ${subdomain} IN AAAA ${staticIp6}
    '')
  );

  # The matrix server is named directly by the service; look its machine up by
  # name. atMostOne ⇒ host may be null (matrix runs nowhere), so guard on that.
  inherit (config.meta.services.matrix) host baseDomain;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    ${baseDomain} = ''
      ; Records for matrix/synapse
    '' +
    (staticRecord "@" server) +
    (staticRecord "element" server) +
    (staticRecord "matrix" server) +
    (staticRecord "turn" server);
  };
}

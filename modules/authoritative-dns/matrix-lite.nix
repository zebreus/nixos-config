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

  inherit (config.meta.services.matrixLite) host baseDomain;
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

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

  machines = lib.attrValues config.machines;
  matrixServer = lib.head (lib.filter (machine: machine.matrixServer.enable) machines);
in
{
  config.modules.dns.zones.${matrixServer.matrixServer.baseDomain} = ''
    ; Records for matrix/synapse
  '' +
  (staticRecord "@" matrixServer) +
  (staticRecord "element" matrixServer) +
  (staticRecord "matrix" matrixServer) +
  (staticRecord "turn" matrixServer);
}

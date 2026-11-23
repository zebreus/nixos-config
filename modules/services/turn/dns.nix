{ lib, config, ... }:
let
  inherit (config.meta.services.turn) host baseDomain;
  server = config.meta.machines.${host};
in
{
  config.modules.dns.zones = lib.mkIf (host != null) {
    ${baseDomain} = ''
      turn IN A ${server.staticIp4}
      turn IN AAAA ${server.staticIp6}
    '';
  };
}

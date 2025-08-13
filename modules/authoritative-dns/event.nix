{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  eventServer = lib.head (lib.filter (machine: machine.eventServer.enable) machines);
  baseDomain = eventServer.eventServer.baseDomain;
in
{
  config.modules.dns.zones."${baseDomain}" = ''
    ; Records for $
    engel IN A ${eventServer.staticIp4}
    engel IN AAAA ${eventServer.staticIp6}
    pad IN A ${eventServer.staticIp4}
    pad IN AAAA ${eventServer.staticIp6}
    tickets IN A ${eventServer.staticIp4}
    tickets IN AAAA ${eventServer.staticIp6}
    himmel IN CNAME engel.${baseDomain}
  '';
}

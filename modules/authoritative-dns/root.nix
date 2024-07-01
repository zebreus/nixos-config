{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  primaryServer = lib.head (lib.filter (machine: machine.authoritativeDns.primary) machines);
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = ''
    ; A a record, so there is a record for the root domain
    @ IN A ${primaryServer.staticIp4}
    @ IN AAAA ${primaryServer.staticIp6}
  '';
}

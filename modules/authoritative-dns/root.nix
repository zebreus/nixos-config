{ lib, config, ... }:
let
  # dns is atLeastOne with a single named primary; look it up by name.
  primaryServer = config.meta.machines.${config.meta.services.dns.primary};
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = ''
    ; A a record, so there is a record for the root domain
    @ IN A ${primaryServer.staticIp4}
    @ IN AAAA ${primaryServer.staticIp6}
  '';
}

{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  besserestrichlisteServer = lib.head (lib.filter (machine: machine.besserestrichlisteServer.enable) machines);
in
{
  config.modules.dns.zones.${besserestrichlisteServer.besserestrichlisteServer.baseDomain} = ''
    ; Records for besserestrichliste
    ${besserestrichlisteServer.besserestrichlisteServer.subDomain} IN A ${besserestrichlisteServer.staticIp4}
    ${besserestrichlisteServer.besserestrichlisteServer.subDomain} IN A ${besserestrichlisteServer.staticIp6}
  '';
}

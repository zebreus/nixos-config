{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  besserestrichlisteServers = lib.filter (machine: machine.besserestrichlisteServer.enable) machines;
in
{
  config = lib.mkIf ((builtins.length besserestrichlisteServers) == 1) (
    let besserestrichlisteServer = lib.head besserestrichlisteServers; in {
      modules.dns.zones.${besserestrichlisteServer.besserestrichlisteServer.baseDomain} = ''
        ; Records for besserestrichliste
        ${besserestrichlisteServer.besserestrichlisteServer.subDomain} IN A ${besserestrichlisteServer.staticIp4}
        ${besserestrichlisteServer.besserestrichlisteServer.subDomain} IN AAAA ${besserestrichlisteServer.staticIp6}
      '';
    }
  );
}

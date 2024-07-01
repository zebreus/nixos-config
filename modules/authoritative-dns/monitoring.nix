{ lib, config, ... }:
let
  machines = lib.attrValues config.machines;
  grafanaServer = lib.head (lib.filter (machine: machine.monitoring.enable) machines);
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = ''
    ; Entries for grafana
    grafana IN A ${grafanaServer.staticIp4}
    grafana IN AAAA ${grafanaServer.staticIp6}
  '';
}

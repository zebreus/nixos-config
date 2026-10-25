{ lib, config, ... }:
let
  # monitoring is exactlyOne, so the service always names exactly one host.
  grafanaServer = config.meta.machines.${config.meta.services.monitoring.host};
in
{
  config.modules.dns.zones.${config.modules.dns.mainDomain} = ''
    ; Entries for grafana
    grafana IN A ${grafanaServer.staticIp4}
    grafana IN AAAA ${grafanaServer.staticIp6}
  '';
}

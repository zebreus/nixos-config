{ config, lib, ... }:
let
  thisMachine = config.meta.self;
  # monitoring is exactlyOne; open the exporter only to that single host.
  grafanaServers = [ config.meta.machines.${config.meta.services.monitoring.host} ];
in
{
  config = {
    # Open firewall port 9100 for traffic from the grafana server
    networking.firewall.extraInputRules = lib.mkMerge (builtins.map
      (machine: ''
        ip6 saddr { ${machine.antibuildingIp6}/128 } tcp dport ${builtins.toString config.services.prometheus.exporters.bird.port} accept
      '')
      grafanaServers);
    services.prometheus = {
      exporters.bird = {
        enable = true;
        listenAddress = "[${thisMachine.antibuildingIp6}]";
      };
    };
  };
}

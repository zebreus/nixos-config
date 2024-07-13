{ config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  machines = lib.attrValues config.machines;
  grafanaServers = lib.filter (machine: machine.monitoring.enable) machines;
in
{
  config = {
    # Open firewall port 9100 for traffic from the grafana server
    networking.firewall.extraInputRules = lib.mkMerge (builtins.map
      (machine: ''
        ip6 saddr { ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}/128 } tcp dport ${builtins.toString config.services.prometheus.exporters.node.port} accept
      '')
      grafanaServers);
    services.prometheus = {
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
        port = 9100;
      };
    };
  };
}

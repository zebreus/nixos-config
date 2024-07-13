{ config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  machines = lib.attrValues config.machines;
  grafanaServers = lib.filter (machine: machine.monitoring.enable) machines;
in
{
  config = {
    services.prometheus = {
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
        port = 9100;
        openFirewall = true;
        firewallFilter =
          if ((builtins.length grafanaServers) > 0) then "-p tcp -m tcp --dport 9100 -s ${lib.concatMapStringsSep "," 
        (machine: "${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}/128")
        grafanaServers}" else null;
      };
    };
  };
}

{ config, lib, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));

  otherMachines = builtins.filter (machine: machine.name != config.networking.hostName) machines;
  connectedMachines = builtins.filter (otherMachine: (isServer thisMachine) || (isServer otherMachine)) otherMachines;

  networks = lib.imap
    (index: otherMachine: {
      name = "antibuilding${builtins.toString otherMachine.address}";
    })
    connectedMachines;

  lgServer = lib.head (lib.filter (machine: machine.bird-lg.enable) machines);
in
{
  config = {
    networking.firewall = lib.mkMerge (builtins.map
      (network: {
        interfaces."${network.name}" = {
          allowedTCPPorts = [ 18000 ];
        };
        interfaces.antibuilding = {
          allowedTCPPorts = [ 18000 ];
        };
      })
      networks);
    services = {
      bird-lg = {
        proxy = {
          enable = true;
          birdSocket = "/var/run/bird/bird.ctl";
          listenAddress = "0.0.0.0:18000";
          allowedIPs = [ "${config.antibuilding.ipv6Prefix}::${builtins.toString lgServer.address}" ];
        };
      };
    };
  };
}

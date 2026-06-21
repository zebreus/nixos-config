{ config, lib, ... }:
let
  thisMachine = config.meta.self;
  otherMachines = config.meta.others;
  connectedMachines = builtins.filter (otherMachine: (thisMachine.isServer) || (otherMachine.isServer)) otherMachines;

  networks = lib.imap
    (index: otherMachine: {
      name = "antibuilding${builtins.toString otherMachine.address}";
    })
    connectedMachines;

  # bird-lg is exactlyOne, so the service always names exactly one host.
  lgServer = config.meta.machines.${config.meta.services.bird-lg.host};
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
          listenAddresses = "0.0.0.0:18000";
          allowedIPs = [ "${lgServer.antibuildingIp6}" ];
        };
      };
    };
  };
}

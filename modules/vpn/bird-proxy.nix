{ config, lib, ... }:
let

  machines = lib.attrValues config.machines;
  isServer = machine: ((machine.vpnHub.staticIp4 != null) || (machine.vpnHub.staticIp6 != null));
  servers = lib.filter (machine: isServer machine) machines;

  networks = lib.imap
    (index: server: {
      name = "antibuilding${builtins.toString server.vpnHub.id}";
    })
    servers;

  lgServer = lib.head (lib.filter (machine: machine.bird-lg.enable) machines);
in
{
  config = {
    networking.firewall = lib.mkMerge (builtins.map
      (network: {
        interfaces."${network.name}" = {
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

# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.vpnHub.staticIp4 != null) || (machine.vpnHub.staticIp6 != null));
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  servers = lib.filter (machine: isServer machine) machines;

  inherit (config.antibuilding) ipv6Prefix;

  networks = lib.imap
    (index: server: {
      # General information about the network
      name = "antibuilding${builtins.toString server.vpnHub.id}";
      id = index;
      clients = builtins.filter (machine: machine.name != server.name) machines;
      server = server;
      port = 51820 + server.vpnHub.id;

      prefix = "${ipv6Prefix}";
      size = builtins.toString 112;

      # Information about the other hosts in the network
      thisHostIsServer = config.networking.hostName == server.name;
    })
    servers;
in
{
  config = {
    networking = {
      domain = "antibuild.ing";

      # Open firewall port for WireGuard.
      firewall = lib.mkMerge (builtins.map
        (network: {
          interfaces."${network.name}" = {
            # BGP port
            allowedTCPPorts = [ 179 ];
            # BFD port
            allowedUDPPorts = [ 3784 ];
          };
        })
        networks);
    };

    services.bird2 = {
      enable = true;
      autoReload = true;
      config = lib.mkMerge ([
        ''
          # Enable a lot of logging
          log syslog {info, warning,error,fatal,trace, debug, remote, auth };
          debug protocols { states, routes, filters, interfaces, events, packets };
          debug tables all
          debug channels all;

          router id 10.20.30.${builtins.toString thisMachine.address};

          # Disable automatically generating direct routes to all network interfaces.
          protocol direct {
                  disabled;
          }
          protocol device {}

          # Forbid synchronizing BIRD routing tables with the OS kernel.
          protocol kernel {
            metric 0;
          	ipv6 {
              import none;
              export all;
            };
            learn;
          }

          protocol bfd {
                  accept ipv6;
                  interface "antibuilding*" {
                          min rx interval 200 ms;
                          min tx interval 500 ms;
                          idle tx interval 3000 ms;
                  };
          }

          template bgp antibuilding_peer {
                local ${ipv6Prefix}::${builtins.toString thisMachine.address} as ${builtins.toString (thisMachine.address + 10000)};
                strict bind on;
                direct;

                advertise hostname on;
                bfd on;

                ipv6 {
                        next hop self on;
                        gateway direct;
                        import filter {
                            if net ~ [ ${ipv6Prefix}::${builtins.toString thisMachine.address}/128 ] then {
                              reject;
                            }
                            krt_metric = 32;
                            accept;
                        };
                        export filter {
                            if source !~ [RTS_STATIC, RTS_BGP] then {
                              reject;
                            }
                            accept;
                        };
                };
          }
        ''
      ]
      ++ (
        builtins.map
          (network: ''
            # Add a static route to self
            protocol static static${builtins.toString thisMachine.address}${network.name} {
                    ipv6 {
                      import filter {
                        accept;
                      };
                    };
                    route ${ipv6Prefix}::${builtins.toString thisMachine.address}/128 via "${network.name}" {
                      krt_metric = 16;
                    };
            }
          '')
          networks
      )
      ++ (
        builtins.map
          (network: ''
            # BGP hub
            protocol bgp ${network.name}s${builtins.toString network.server.address} from antibuilding_peer {
                  description "BGP ${network.name}";
                  neighbor ${ipv6Prefix}::${builtins.toString network.server.address}%${network.name} as ${builtins.toString (network.server.address + 10000)};
                  interface "${network.name}";
            }

            # Add a static route to the neighbour, if it does BFD
            # This should make sure, that we prefer the direct connection
            protocol static static${builtins.toString network.server.address}${network.name} {
                    ipv6 {
                      import filter {
                        ifname = "${network.name}";
                        accept;
                      };
                    };
                    route ${ipv6Prefix}::${builtins.toString network.server.address}/128 via ${ipv6Prefix}::${builtins.toString network.server.address} dev "${network.name}" bfd on {
                      krt_metric = 64;
                    };
            }


          '')
          (builtins.filter (network: !network.thisHostIsServer) networks)
      )
      ++ (
        builtins.concatMap
          (network: (builtins.map
            (client: ''
              # BGP client
              protocol bgp ${network.name}c${builtins.toString client.address} from antibuilding_peer {
                    description "BGP to ${network.name} ${builtins.toString client.address}";
                    neighbor ${ipv6Prefix}::${builtins.toString client.address}%${network.name} as ${builtins.toString (client.address + 10000)};
                    interface "${network.name}";
              }

              # Add a static route to the neighbour, if it does BFD
              protocol static static${builtins.toString client.address}${network.name} {
                      ipv6 {
                        import filter {
                          ifname = "${network.name}";
                          accept;
                        };
                      };
                      route ${ipv6Prefix}::${builtins.toString client.address}/128 via ${ipv6Prefix}::${builtins.toString client.address} dev "${network.name}" bfd on {
                        krt_metric = 64;
                      };
              }
            '')
            network.clients))
          (builtins.filter (network: network.thisHostIsServer) networks)
      ));
    };
  };
}

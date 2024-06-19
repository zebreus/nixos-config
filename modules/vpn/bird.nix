# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));

  inherit (config.antibuilding) ipv6Prefix;

  otherMachines = builtins.filter (machine: machine.name != config.networking.hostName) machines;
  connectedMachines = builtins.filter (otherMachine: (isServer thisMachine) || (isServer otherMachine)) otherMachines;

  networks = lib.imap
    (index: otherMachine: {
      # General information about the network
      name = "antibuilding${builtins.toString otherMachine.address}";
      id = index;
      otherMachine = otherMachine;
      thisPort = 51820 + otherMachine.address;
      otherPort = 51820 + thisMachine.address;

      thisAddress = "fe80::${builtins.toString otherMachine.address}:${builtins.toString thisMachine.address}";
      otherAddress = "fe80::${builtins.toString thisMachine.address}:${builtins.toString otherMachine.address}";

      connectTo = if (isServer otherMachine) then "${otherMachine.name}.outside.antibuild.ing:${builtins.toString (51820 + thisMachine.address)}" else null;

      size = builtins.toString 64;

      # Information about the other hosts in the network
      thisHostIsServer = isServer thisMachine;
    })
    connectedMachines;
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
                strict bind on;
                direct;

                advertise hostname on;
                bfd on;

                ipv6 {
                        next hop self on;
                        gateway direct;
                        import filter {
                            if net ~ [ fe80::/64 ] then {
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

           # Add a static route to self
            protocol static antibuilding${builtins.toString thisMachine.address} {
                    ipv6 {
                      import filter {
                        accept;
                      };
                    };
                    route ${ipv6Prefix}::${builtins.toString thisMachine.address}/128 via "antibuilding" {
                      krt_metric = 16;
                    };
            }
        ''
      ]
      ++ (
        builtins.map
          (network: ''
            # BGP hub
            protocol bgp ${network.name} from antibuilding_peer {
                  description "BGP ${network.name}";
                  local ${network.thisAddress} as ${builtins.toString (thisMachine.address + 10000)};
                  neighbor ${network.otherAddress}%${network.name} as ${builtins.toString (network.otherMachine.address + 10000)};
                  interface "${network.name}";
            }
          '')
          networks
      ));
    };
  };
}

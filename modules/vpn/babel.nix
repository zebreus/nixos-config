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
      # Open firewall port for WireGuard.
      firewall = lib.mkMerge (builtins.map
        (network: {
          interfaces."${network.name}" = {
            # BGP port
            allowedTCPPorts = [ 179 ];
            # BFD port
            allowedUDPPorts = [ 3784 6696 ];
          };
        })
        networks);
    };

    # Some protocol continously accumulates memory until the system runs out of memory. I spend 2 hours trying to debug it but was not able to fix it. So for now we just limit the memory usage for the bird2 service.
    # TODO: Find a proper solution
    systemd.services.bird.serviceConfig = {
      MemoryMax = "40%";
      MemoryAccounting = "true";
    };

    services.bird = {
      enable = true;
      autoReload = true;
      config = lib.mkOrder 1 ''
        timeformat protocol iso long;
        # # Enable a lot of logging
        # log syslog {info, warning,error,fatal,trace, debug, remote, auth };
        # debug protocols { states, routes, filters, interfaces, events, packets };
        # debug tables all;
        # debug channels all;

        define OWNIP = 172.20.179.${builtins.toString (thisMachine.address + 128)};
        define OWNIPv6 = ${ipv6Prefix}::${builtins.toString thisMachine.address};

        router id OWNIP;

        # Disable automatically generating direct routes to all network interfaces.
        protocol direct {
            disabled;
        }
        protocol device {}

        protocol kernel {
            scan time 20;
            ipv6 {
                import none;
                export filter {
                    if source = RTS_STATIC then reject;
                    krt_prefsrc = OWNIPv6;
                    accept;
                };
            };
        };
        protocol kernel {
            scan time 20;
            ipv4 {
                import none;
                export filter {
                    if source = RTS_STATIC then reject;
                    krt_prefsrc = OWNIP;
                    accept;
                };
            };
        }

        # Add a static route to self
        protocol static antibuilding${builtins.toString thisMachine.address}_v6 {
            route ${ipv6Prefix}::${builtins.toString thisMachine.address}/128 via "antibuilding";
            ipv6 {
                import all;
            };
        }
        protocol static antibuilding${builtins.toString thisMachine.address}_v4 {
            route 172.20.179.${builtins.toString (128 + thisMachine.address)}/32 via "antibuilding";
            ipv4 {
                import all;
            };
        }

        protocol babel {
            interface "antibuilding*" {
                type tunnel;
                limit 16;
            };
            ipv4 {
                import filter {
                  if source !~ [RTS_BABEL, RTS_STATIC, RTS_BGP] then {
                    reject;
                  }

                  accept;
                };
                export filter {
                  if source !~ [RTS_BABEL, RTS_STATIC, RTS_BGP] then {
                    reject;
                  }

                  accept;
                };
            };
            ipv6 {
                import filter {
                  if source !~ [RTS_BABEL, RTS_STATIC, RTS_BGP] then {
                    reject;
                  }
                  
                  accept;
                };
                export filter {
                  if source !~ [RTS_BABEL, RTS_STATIC, RTS_BGP] then {
                    reject;
                  }

                  accept;
                };
            };
        }
      '';
    };
  };
}

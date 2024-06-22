# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, pkgs, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
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
      # thisAddress4 = "169.254.${builtins.toString (otherMachine.address + 128)}.${builtins.toString (thisMachine.address + 128)}";
      # otherAddress4 = "169.254.${builtins.toString (thisMachine.address + 128)}.${builtins.toString (otherMachine.address + 128)}";

      connectTo = if (isServer otherMachine) then "${otherMachine.name}.outside.antibuild.ing:${builtins.toString (51820 + thisMachine.address)}" else null;

      size = builtins.toString 64;

      thisHostIsServer = isServer thisMachine;
    })
    connectedMachines;

  # All the names that hosts can be reached with
  allHostNames = builtins.concatMap
    (machine: [
      {
        address = "${ipv6Prefix}::${builtins.toString machine.address}";
        name = "${machine.name}.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = "${ipv6Prefix}::${builtins.toString machine.address}";
        name = "${machine.name}.lg.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = "${ipv6Prefix}::${builtins.toString machine.address}";
        inherit (machine) name;
        inherit (machine) sshPublicKey;
      }
      {
        address = "${ipv6Prefix}::${builtins.toString machine.address}";
        name = "${ipv6Prefix}::${builtins.toString machine.address}";
        inherit (machine) sshPublicKey;
      }
    ]
    # Set hostnames for the endpoints of the machines with static IPs.
    ++ (if machine.staticIp4 != null then [
      {
        address = machine.staticIp4;
        name = "${machine.name}.outside.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = machine.staticIp4;
        name = machine.staticIp4;
        inherit (machine) sshPublicKey;
      }
    ] else [ ])
    ++ (if machine.staticIp6 != null then [
      {
        address = machine.staticIp6;
        name = "${machine.name}.outside.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = machine.staticIp6;
        name = machine.staticIp6;
        inherit (machine) sshPublicKey;
      }
    ] else [ ])
    )
    machines;
in
{
  options = with lib; {
    antibuilding = {
      ipv6Prefix = mkOption {
        default = "fd10:2030";
        description = "The IPv6 prefix for the antibuilding. There is not much reason to change this, I just added this option so I can reuse the prefix in other places.";
        type = types.str;
      };
      customWireguardPrivateKeyFile = mkOption {
        default = null;
        description = "The wireguard private key for this machine. Should only be set if the secrets of that machine are not managed in this repo";
        type = types.nullOr types.str;
      };
      customWireguardPskFile = mkOption {
        default = null;
        description = "Information about the machines in the network. Should only be set if the secrets of that machine are not managed in this repo";
        type = types.nullOr types.str;
      };
    };
  };

  config = {
    age.secrets.wireguard_private_key = {
      file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
      owner = "systemd-network";
      group = "systemd-network";
    };
    age.secrets.shared_wireguard_psk = {
      file = ../../secrets/shared_wireguard_psk.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    # Add known ssh keys to the known_hosts file.
    services.openssh.knownHosts = builtins.foldl'
      (acc: { name, sshPublicKey, ... }: acc // {
        ${name} = {
          publicKey = sshPublicKey;
        };
      })
      { }
      (builtins.filter (e: e.sshPublicKey != null) allHostNames);

    environment.systemPackages = [
      pkgs.wireguard-tools
    ];

    networking = {
      domain = "antibuild.ing";

      # Open firewall port for WireGuard.
      firewall = lib.mkMerge (builtins.map
        (network: {
          allowedUDPPorts = (builtins.map (network: network.thisPort) networks);
          interfaces."${network.name}" = {
            allowedTCPPorts = [ 22 ];
          };
        })
        networks);

      # Add all machines to the hosts file.
      hosts = builtins.listToAttrs
        (
          builtins.map
            (address: {
                name = address;
                value = builtins.map (e: e.name) (builtins.filter (e: e.address == address) allHostNames);
            })
            (lib.unique (builtins.map (e: e.address) allHostNames)));

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = (builtins.map (network: network.name) networks);
        };
    };

    systemd.network = lib.mkMerge ([{
      wait-online.enable = false;
      wait-online.anyInterface = false;
      enable = true;

      netdevs = {
        "50-antibuilding" = {
          enable = true;
          netdevConfig = {
            Kind = "dummy";
            Name = "antibuilding";
          };
        };
      };

      networks.antibuilding = {
        matchConfig.Name = "antibuilding";
        address = [ "fd10:2030::${builtins.toString thisMachine.address}/112" "172.20.179.${builtins.toString (128 + thisMachine.address)}/27" ];
      };
    }]
    ++
    (builtins.map
      (network: {
        netdevs = {
          "50-${network.name}" = {
            netdevConfig = {
              Kind = "wireguard";
              Name = network.name;
              MTUBytes = "1420";
            };
            wireguardConfig = {
              PrivateKeyFile = config.age.secrets.wireguard_private_key.path;
              ListenPort = network.thisPort;
            };
            wireguardPeers = [
              (lib.mkMerge
                ([{
                PresharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                PublicKey = network.otherMachine.wireguardPublicKey;
                AllowedIPs = [ "::/0" "0.0.0.0/0" ];
                PersistentKeepalive = 25;
              }
                  (lib.mkIf (network.connectTo != null) {
                    Endpoint = network.connectTo;
                  })]))
            ];
          };
        };
        networks.${network.name} = {
          matchConfig.Name = "${network.name}";
          address = [ "${network.thisAddress}/64" ];
          routes = [{
              Destination = "${network.otherAddress}/128";
              Scope = "link";
          }];
          networkConfig = {
            IPForward = true;
            # # TODO: Why arent the options called IPv6Forwarding (like in systemd) but IPForward?
            # IPv4Forwarding = true;
            # IPv6Forwarding = true;
          };
        };
      })
      networks));

    # Enable IP forwarding on the server so peers can communicate with each other.
    boot =
      if isServer thisMachine then {
        kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
        kernel.sysctl."net.ipv4.ip_forward" = true;
      } else { };
  };
}

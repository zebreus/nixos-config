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
        description = "Path to a file containing the wireguard private key for this machine at run time. Should only be set if the secrets of that machine are not managed in this repo";
        type = types.nullOr types.str;
      };
    };
    age.dummy = lib.mkOption {
      type = lib.types.raw;
    };
  };

  config = {
    age =
      if config.antibuilding.customWireguardPrivateKeyFile == null then {
        secrets.wireguard_private_key = {
          file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
          owner = "systemd-network";
          group = "systemd-network";
        };
      } else { };

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
          rejectPackets = true;
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

      # Enable systemd networkd
      useNetworkd = true;

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = (builtins.map (network: network.name) networks);
      };
    };

    systemd = lib.mkMerge ([{
      network = {
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
      };


    }]
    ++
    (builtins.map
      (network: {
        network = {
          netdevs = {
            "50-${network.name}" = {
              netdevConfig = {
                Kind = "wireguard";
                Name = network.name;
                MTUBytes = "1420";
              };
              wireguardConfig = {
                PrivateKeyFile =
                  if config.antibuilding.customWireguardPrivateKeyFile != null then
                    config.antibuilding.customWireguardPrivateKeyFile else
                    config.age.secrets.wireguard_private_key.path;
                ListenPort = network.thisPort;
              };
              wireguardPeers = [
                (lib.mkMerge
                  ([{
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
            };
          };
        };
        services."wireguard-refresh-endpoint-for-${network.name}" = lib.mkIf (network.connectTo != null) {
          enable = true;
          description = "WireGuard Endpoint refresh service";
          # requires = [ "wireguard-${interfaceName}.service" ];
          # wants = [ "network-online.target" ];
          # after = [ "wireguard-${interfaceName}.service" "network-online.target" ];
          # wantedBy = [ "wireguard-${interfaceName}.service" ];
          requires = [ "systemd-networkd.service" ];
          wants = [ "network-online.target" ];
          after = [ "systemd-networkd.service" "network-online.target" ];
          wantedBy = [ "systemd-networkd.service" ];
          environment.DEVICE = network.name;
          environment.WG_ENDPOINT_RESOLUTION_RETRIES = "infinity";
          path = with pkgs; [ iproute2 wireguard-tools ];

          serviceConfig = {
            Type = "simple"; # re-executes 'wg' indefinitely
            # Note that `Type = "oneshot"` services with `RemainAfterExit = true`
            # cannot be used with systemd timers (see `man systemd.timer`),
            # which is why `simple` with a loop is the best choice here.
            # It also makes starting and stopping easiest.
            #
            # Restart if the service exits (e.g. when wireguard gives up after "Name or service not known" dns failures):
            Restart = "always";
            RestartSec = 60;
          };
          unitConfig = {
            StartLimitIntervalSec = 0;
          };

          script =
            let
              wg = lib.getExe pkgs.wireguard-tools;
              wg_setup = ''${wg} set ${network.name} peer "${network.otherMachine.wireguardPublicKey}" endpoint "${network.connectTo}"'';
            in
            ''
              ${wg_setup}
              # Re-execute 'wg' periodically to notice DNS / hostname changes.
              # Note this will not time out on transient DNS failures such as DNS names
              # because we have set 'WG_ENDPOINT_RESOLUTION_RETRIES=infinity'.
              # Also note that 'wg' limits its maximum retry delay to 20 seconds as of writing.
              while ${wg_setup}; do
                sleep 60;
              done
            '';
        };
      })
      networks));
  };
}

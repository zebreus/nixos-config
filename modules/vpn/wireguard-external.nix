# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  machines = lib.attrValues config.machines;

  inherit (config.antibuilding) ipv6Prefix;

  otherMachines = builtins.filter (machine: machine.name != config.networking.hostName) machines;
  unmanagedMachines = builtins.filter (otherMachine: !otherMachine.managed) otherMachines;
in
{
  config = lib.mkIf (config.networking.hostName == "kashenblade") {
    age =
      if config.antibuilding.customWireguardPrivateKeyFile == null then {
        secrets.wireguard_private_key = {
          file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
          owner = "systemd-network";
          group = "systemd-network";
        };
        secrets.shared_wireguard_psk = {
          file = ../../secrets/shared_wireguard_psk.age;
          owner = "systemd-network";
          group = "systemd-network";
          mode = "0444";
        };
      } else {
        secrets.shared_wireguard_psk = {
          file = ../../secrets/shared_wireguard_psk.age;
          owner = "systemd-network";
          group = "systemd-network";
          mode = "0444";
        };
      };


    networking = {
      # Open firewall port for WireGuard.
      firewall.allowedUDPPorts = [ 51820 ];

      # Enable systemd networkd
      useNetworkd = true;

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        unmanaged = [ "antibuilding99" ];
      };
    };

    systemd = lib.mkMerge ([
      {
        network = {
          netdevs."50-antibuilding-external" = {
            netdevConfig = {
              Kind = "wireguard";
              Name = "antibuilding99";
              MTUBytes = "1420";
            };
            wireguardConfig = {
              PrivateKeyFile =
                if config.antibuilding.customWireguardPrivateKeyFile != null then
                  config.antibuilding.customWireguardPrivateKeyFile else
                  config.age.secrets.wireguard_private_key.path;
              ListenPort = 51820;
            };
            wireguardPeers = builtins.map
              (machine: {
                PublicKey = machine.wireguardPublicKey;
                AllowedIPs = [ "${ipv6Prefix}::${builtins.toString machine.address}/128" ];
                PresharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                PersistentKeepalive = 25;
              })
              unmanagedMachines;
          };

          networks.antibuilding99 = {
            matchConfig.Name = "antibuilding99";
            address = [ "fe80::1922:3932:1029:1111/128" ];
            routes = builtins.map
              (machine: {
                Destination = "${ipv6Prefix}::${builtins.toString machine.address}/128";
              })
              unmanagedMachines;
            networkConfig = {
              IPForward = true;
            };
          };
        };
      }
    ]
    );
  };
}

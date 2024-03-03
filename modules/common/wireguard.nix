{ pkgs, config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  otherMachines = lib.attrValues (lib.filterAttrs (name: machine: name != config.networking.hostName && ((isServer thisMachine) || (isServer machine))) config.machines);

  ipv6_prefix = "fd10:2030";
in
{
  imports = [
    ../machines.nix
  ];

  options = with lib; {
    customWireguardPrivateKeyFile = mkOption {
      default = [ ];
      description = lib.mdDoc "The wireguard private key for this machine. Should only be set if the secrets of that machine are not managed in this repo";
      type = with types; attrsOf (submodule machineOpts);
    };
    customWireguardPskFile = mkOption {
      default = [ ];
      description = lib.mdDoc "Information about the machines in the network. Should only be set if the secrets of that machine are not managed in this repo";
      type = with types; attrsOf (submodule machineOpts);
    };
  };

  config = {
    age.secrets.wireguard_private_key = {
      file = ../../secrets + "/${config.networking.hostName}_wireguard.age";
      mode = "0444";
    };
    age.secrets.shared_wireguard_psk = {
      file = ../../secrets/shared_wireguard_psk.age;
      mode = "0444";
    };

    networking = {
      # Open firewall port for WireGuard.
      firewall = {
        allowedUDPPorts = [ 51820 ];
        interfaces."antibuilding".allowedTCPPorts = [ 22 ];
      };

      # Add all machines to the hosts file.
      hosts = builtins.listToAttrs (builtins.concatMap
        (machine: [
          {
            name = "${ipv6_prefix}::${builtins.toString machine.address}";
            value = [ "${machine.name}.antibuild.ing" machine.name ];
          }
        ]
        # Set hostnames for the endpoints of the machines with static IPs.
        ++ (if machine.staticIp4 != null then [
          {
            name = machine.staticIp4;
            value = [ "${machine.name}.endpoint.zebre.us" ];
          }
        ] else [ ])
        ++ (if machine.staticIp6 != null then [
          {
            name = machine.staticIp6;
            value = [ "${machine.name}.endpoint.zebre.us" ];
          }
        ] else [ ])
        )
        (lib.attrValues config.machines));

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager =
        lib.mkIf config.networking.networkmanager.enable {
          unmanaged = [ "antibuilding" ];
        };

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        # "antibuilding" is the network interface name.
        antibuilding = rec {
          ips = [ "${ipv6_prefix}::${builtins.toString thisMachine.address}/64" ];
          listenPort = 51820;

          # Path to the private key file.
          privateKeyFile = config.age.secrets.wireguard_private_key.path;

          # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
          postSetup = builtins.concatStringsSep "\n" (
            (if isServer thisMachine then
              ((builtins.concatMap
                (machine:
                  # Trusted machines are allowed to connect to all other machines.
                  (if machine.trusted then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A FORWARD -s ${ipv6_prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]) ++
                  # Block connections from untrusted machines, if this machine is not public.
                  (if machine.trusted || thisMachine.public then [ ] else [
                    "${pkgs.iptables}/bin/ip6tables -I INPUT 1 -s ${ipv6_prefix}::${builtins.toString machine.address} -j DROP"
                  ]) ++
                  # Connections to public machines are allowed from all other machines.
                  (if machine.public then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A FORWARD -d ${ipv6_prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]))
                otherMachines) ++
              [
                "${pkgs.iptables}/bin/ip6tables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT"
                "${pkgs.iptables}/bin/ip6tables -A FORWARD -j DROP"
              ]) else [ ])
            ++ [ ]
          );

          postShutdown = builtins.replaceStrings [ "-A" "-I INPUT 1" ] [ "-D" "-D" ] postSetup;

          peers = builtins.map
            (machine: (
              {
                name = machine.name;
                publicKey = machine.wireguardPublicKey;
                presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                # Send keepalives every 25 seconds.
                persistentKeepalive = 25;
              } //
              (if !isServer machine then {
                allowedIPs = [ "${ipv6_prefix}::${builtins.toString machine.address}/128" ];
              } else {
                allowedIPs = [ "${ipv6_prefix}::0/64" ];

                # Set this to the server IP and port.
                endpoint = "${machine.name}.endpoint.zebre.us:51820";
                dynamicEndpointRefreshSeconds = 60;
              })
            ))
            otherMachines;
        };
      };
    };

    # Enable IP forwarding on the server so peers can communicate with each other.
    boot =
      if isServer thisMachine then {
        kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
      } else { };
  };
}

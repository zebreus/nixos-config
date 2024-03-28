{ pkgs, config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.staticIp4 != null) || (machine.staticIp6 != null));
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  otherMachines = lib.attrValues (lib.filterAttrs (name: machine: name != config.networking.hostName && ((isServer thisMachine) || (isServer machine))) config.machines);

  ipv6Prefix = config.antibuilding.ipv6Prefix;

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
        name = machine.name;
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
    (lib.attrValues config.machines);
in
{
  options = with lib; {
    antibuilding = {
      ipv6Prefix = mkOption {
        default = "fd10:2030";
        description = lib.mdDoc "The IPv6 prefix for the antibuilding. There is not much reason to change this, I just added this option so I can reuse the prefix in other places.";
        type = types.str;
      };
      customWireguardPrivateKeyFile = mkOption {
        default = null;
        description = lib.mdDoc "The wireguard private key for this machine. Should only be set if the secrets of that machine are not managed in this repo";
        type = types.nullOr types.str;
      };
      customWireguardPskFile = mkOption {
        default = null;
        description = lib.mdDoc "Information about the machines in the network. Should only be set if the secrets of that machine are not managed in this repo";
        type = types.nullOr types.str;
      };
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

    # Add known ssh keys to the known_hosts file.
    services.openssh.knownHosts = builtins.foldl'
      (acc: { name, sshPublicKey, ... }: acc // {
        ${name} = {
          publicKey = sshPublicKey;
        };
      })
      { }
      (builtins.filter (e: e.sshPublicKey != null) allHostNames);

    networking = {
      domain = "antibuild.ing";

      # Open firewall port for WireGuard.
      firewall = {
        allowedUDPPorts = [ 51820 ];
        interfaces."antibuilding".allowedTCPPorts = [ 22 ];
      };

      # Add all machines to the hosts file.
      hosts = builtins.listToAttrs
        (
          builtins.map
            (
              address: {
                name = address;
                value = builtins.map (e: e.name) (builtins.filter (e: e.address == address) allHostNames);
              }
            )
            (lib.unique (builtins.map (e: e.address) allHostNames)));

      # Prevent networkmanager from doing weird stuff with the wireguard interface.
      networkmanager =
        lib.mkIf config.networking.networkmanager.enable {
          unmanaged = [ "antibuilding" ];
        };

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        # "antibuilding" is the network interface name.
        antibuilding = {
          ips = [ "${ipv6Prefix}::${builtins.toString thisMachine.address}/64" ];
          listenPort = 51820;

          # Path to the private key file.
          privateKeyFile = config.age.secrets.wireguard_private_key.path;

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
                allowedIPs = [ "${ipv6Prefix}::${builtins.toString machine.address}/128" ];
              } else {
                allowedIPs = [ "${ipv6Prefix}::0/64" ];

                # Set this to the server IP and port.
                endpoint = "${machine.name}.outside.antibuild.ing:51820";
                dynamicEndpointRefreshSeconds = 60;
              })
            ))
            otherMachines;

          # Setup firewall rules for the WireGuard interface.
          postSetup = builtins.concatStringsSep "\n" (
            if isServer thisMachine then
              [
                # Make sure the temp chain does not exist and is empty
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input-temp || true"
                # Create the temp chain.
                "${pkgs.iptables}/bin/ip6tables -N antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -N antibuilding-input-temp || true" # The input chain should only contain drop rules
                # Allow input traffic, if it is related to an established connection
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-input-temp -m state --state RELATED,ESTABLISHED -j RETURN"
              ] ++
              ((builtins.concatMap
                (machine:
                  # Trusted machines are allowed to connect to all other machines.
                  (if machine.trusted then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -s ${ipv6Prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]) ++
                  # Forward trusted ports to all machines.
                  (builtins.map
                    (port:
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -s ${ipv6Prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j ACCEPT"
                    )
                    machine.trustedPorts) ++
                  # Block connections from untrusted machines, if this machine is not public.
                  # TODO: Support public and trusted ports
                  (if machine.trusted || thisMachine.public then [ ] else
                  (
                    (builtins.map
                      (port:
                        "${pkgs.iptables}/bin/ip6tables -A antibuilding-input-temp -s ${ipv6Prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j RETURN"
                      )
                      (machine.trustedPorts ++ thisMachine.publicPorts)) ++
                    [
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-input-temp -s ${ipv6Prefix}::${builtins.toString machine.address} -j DROP"
                    ]
                  )) ++
                  # Connections to public machines are allowed from all other machines.
                  (if machine.public then
                    [
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -d ${ipv6Prefix}::${builtins.toString machine.address} -j ACCEPT"
                    ] else [ ]) ++
                  # Open individual public ports.
                  (builtins.map
                    (port:
                      "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -d ${ipv6Prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j ACCEPT"
                    )
                    machine.publicPorts))
                otherMachines) ++
              [
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -m state --state RELATED,ESTABLISHED -j ACCEPT"
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-forward-temp -j DROP"
                "${pkgs.iptables}/bin/ip6tables -A antibuilding-input-temp -j RETURN"
                # Add the new chain
                "${pkgs.iptables}/bin/ip6tables -A FORWARD -j antibuilding-forward-temp"
                "${pkgs.iptables}/bin/ip6tables -I INPUT 1 -j antibuilding-input-temp"
                # Delete the previous chain
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input || true"
                # Give the real name to the new chain
                "${pkgs.iptables}/bin/ip6tables -E antibuilding-forward-temp antibuilding-forward"
                "${pkgs.iptables}/bin/ip6tables -E antibuilding-input-temp antibuilding-input"
              ]) else [ ]
          );

          # Tear down firewall rules
          postShutdown = builtins.concatStringsSep "\n" (
            if isServer thisMachine then
              ([
                # Remove and delete the chains
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input || true"
              ] ++ [
                # Do the same for the temp chains, if they exist (they should not, but just in case)
                "${pkgs.iptables}/bin/ip6tables -D FORWARD -j antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -D INPUT -j antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -F antibuilding-input-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-forward-temp || true"
                "${pkgs.iptables}/bin/ip6tables -X antibuilding-input-temp || true"
              ]) else [ ]
          );
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

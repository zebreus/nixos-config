# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ pkgs, config, lib, ... }:
let
  machines = lib.attrValues config.machines;
  thisMachine = config.machines."${config.networking.hostName}";
  # isServer = thisMachine.staticIp != null;
  isServer = machine: ((machine.vpnHub.staticIp4 != null) || (machine.vpnHub.staticIp6 != null));
  # If this is a server: All other machines including servers and clients
  # If this is a client: Only other machines that are servers
  otherMachines = lib.attrValues (lib.filterAttrs (name: machine: name != config.networking.hostName && ((isServer thisMachine) || (isServer machine))) config.machines);
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
    ++ (if machine.vpnHub.staticIp4 != null then [
      {
        address = machine.vpnHub.staticIp4;
        name = "${machine.name}.outside.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = machine.vpnHub.staticIp4;
        name = machine.vpnHub.staticIp4;
        inherit (machine) sshPublicKey;
      }
    ] else [ ])
    ++ (if machine.vpnHub.staticIp6 != null then [
      {
        address = machine.vpnHub.staticIp6;
        name = "${machine.name}.outside.antibuild.ing";
        inherit (machine) sshPublicKey;
      }
      {
        address = machine.vpnHub.staticIp6;
        name = machine.vpnHub.staticIp6;
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
      firewall = lib.mkMerge (builtins.map
        (network: {
          allowedUDPPorts = [ network.port ];
          interfaces."${network.name}" = {
            allowedTCPPorts = [ 22 ];
          };
        })
        networks);

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
          unmanaged = (builtins.map
            (network: network.name)
            networks);
        };

      # Configure the WireGuard interface.
      wireguard.interfaces = builtins.listToAttrs
        (builtins.map
          (network: {
            name = network.name;
            value = {
              ips = [ "${network.prefix}::${builtins.toString thisMachine.address}/112" ];
              allowedIPsAsRoutes = false;
              listenPort = network.port;

              # Path to the private key file.
              privateKeyFile = config.age.secrets.wireguard_private_key.path;

              peers =
                if network.thisHostIsServer then
                  (
                    builtins.map
                      (machine: {
                        inherit (machine) name;
                        publicKey = machine.wireguardPublicKey;
                        presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                        # Send keepalives every 25 seconds.
                        persistentKeepalive = 25;
                        allowedIPs = [ "${network.prefix}::${builtins.toString machine.address}/128" ];
                      })
                      network.clients
                  )
                else [
                  {
                    inherit (network.server) name;
                    publicKey = network.server.wireguardPublicKey;
                    presharedKeyFile = config.age.secrets.shared_wireguard_psk.path;
                    # Send keepalives every 25 seconds.
                    persistentKeepalive = 25;

                    allowedIPs = [ "${network.prefix}::0/${network.size}" ];

                    # Set this to the server IP and port.
                    endpoint = "${network.server.name}.outside.antibuild.ing:${builtins.toString network.port}";
                    dynamicEndpointRefreshSeconds = 60;
                  }
                ];

              # Setup firewall rules for the WireGuard interface.
              postSetup = builtins.concatStringsSep "\n"
                (
                  [
                    ''
                      set -x
                      set +e
                      # ip -6 addr add ${network.prefix}::${builtins.toString thisMachine.address}/${network.size} dev ${network.name} noprefixroute || true
                    ''
                  ]
                  ++
                  (if isServer thisMachine then
                    [
                      # Make sure the temp chain does not exist and is empty
                      "${pkgs.iptables}/bin/ip6tables -F ${network.name}-forward-temp || true"
                      "${pkgs.iptables}/bin/ip6tables -X ${network.name}-forward-temp || true"
                      "${pkgs.iptables}/bin/ip6tables -F ${network.name}-input-temp || true"
                      "${pkgs.iptables}/bin/ip6tables -X ${network.name}-input-temp || true"
                      # Create the temp chain.
                      "${pkgs.iptables}/bin/ip6tables -N ${network.name}-forward-temp || true"
                      "${pkgs.iptables}/bin/ip6tables -N ${network.name}-input-temp || true" # The input chain should only contain drop rules
                      # Allow input traffic, if it is related to an established connection
                      "${pkgs.iptables}/bin/ip6tables -A ${network.name}-input-temp -m state --state RELATED,ESTABLISHED -j RETURN"
                    ] ++
                    ((builtins.concatMap
                      (machine:
                        # Trusted machines are allowed to connect to all other machines.
                        (if machine.trusted then
                          [
                            "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -s ${network.prefix}::${builtins.toString machine.address} -j ACCEPT"
                          ] else [ ]) ++
                        # Forward trusted ports to all machines.
                        (builtins.map
                          (port:
                            "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -s ${network.prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j ACCEPT"
                          )
                          machine.trustedPorts) ++
                        # Block connections from untrusted machines, if this machine is not public.
                        # TODO: Support public and trusted ports
                        (if machine.trusted || thisMachine.public then [ ] else
                        (
                          (builtins.map
                            (port:
                              "${pkgs.iptables}/bin/ip6tables -A ${network.name}-input-temp -s ${network.prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j RETURN"
                            )
                            (machine.trustedPorts ++ thisMachine.publicPorts ++ [ "179" ])) ++
                          [
                            "${pkgs.iptables}/bin/ip6tables -A ${network.name}-input-temp -s ${network.prefix}::${builtins.toString machine.address} -j DROP"
                          ]
                        )) ++
                        # Connections to public machines are allowed from all other machines.
                        (if machine.public then
                          [
                            "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -d ${network.prefix}::${builtins.toString machine.address} -j ACCEPT"
                          ] else [ ]) ++
                        # Open individual public ports.
                        (builtins.map
                          (port:
                            "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -d ${network.prefix}::${builtins.toString machine.address} -p tcp --dport ${builtins.toString port} -j ACCEPT"
                          )
                          machine.publicPorts ++ [ "179" ]))
                      otherMachines) ++
                    [
                      "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -m state --state RELATED,ESTABLISHED -j ACCEPT"
                      "${pkgs.iptables}/bin/ip6tables -A ${network.name}-forward-temp -j DROP"
                      "${pkgs.iptables}/bin/ip6tables -A ${network.name}-input-temp -j RETURN"
                      # Add the new chain
                      "${pkgs.iptables}/bin/ip6tables -A FORWARD -i ${network.name} -j ${network.name}-forward-temp"
                      "${pkgs.iptables}/bin/ip6tables -A FORWARD -o ${network.name} -j ${network.name}-forward-temp"
                      "${pkgs.iptables}/bin/ip6tables -I INPUT 1 -i ${network.name} -j ${network.name}-input-temp"
                      # Delete the previous chain
                      "${pkgs.iptables}/bin/ip6tables -D FORWARD -i ${network.name} -j ${network.name}-forward || true"
                      "${pkgs.iptables}/bin/ip6tables -D FORWARD -o ${network.name} -j ${network.name}-forward || true"
                      "${pkgs.iptables}/bin/ip6tables -D INPUT -i ${network.name} -j ${network.name}-input || true"
                      # Give the real name to the new chain
                      "${pkgs.iptables}/bin/ip6tables -E ${network.name}-forward-temp ${network.name}-forward || true"
                      "${pkgs.iptables}/bin/ip6tables -E ${network.name}-input-temp ${network.name}-input || true"
                      "true"
                    ]) else [ ])
                );

              # Tear down firewall rules
              postShutdown =
                builtins.concatStringsSep "\n"
                  (
                    [
                      ''
                        set -x
                        set +e
                        # ip -6 addr delete ${network.prefix}::${builtins.toString thisMachine.address}/${network.size} dev ${network.name} noprefixroute || true
                      ''
                    ] ++ (if isServer thisMachine then
                      ([
                        # Remove and delete the chains
                        "${pkgs.iptables}/bin/ip6tables -D FORWARD -i ${network.name} -j ${network.name}-forward || true"
                        "${pkgs.iptables}/bin/ip6tables -D FORWARD -o ${network.name} -j ${network.name}-forward || true"
                        "${pkgs.iptables}/bin/ip6tables -D INPUT -i ${network.name} -j ${network.name}-input || true"
                        "${pkgs.iptables}/bin/ip6tables -F ${network.name}-forward || true"
                        "${pkgs.iptables}/bin/ip6tables -F ${network.name}-input || true"
                        "${pkgs.iptables}/bin/ip6tables -X ${network.name}-forward || true"
                        "${pkgs.iptables}/bin/ip6tables -X ${network.name}-input || true"
                        "true"
                      ] ++ [
                        # Do the same for the temp chains, if they exist (they should not, but just in case)
                        "${pkgs.iptables}/bin/ip6tables -D FORWARD -i ${network.name} -j ${network.name}-forward-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -D FORWARD -o ${network.name} -j ${network.name}-forward-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -D INPUT -i ${network.name} -j ${network.name}-input-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -F ${network.name}-forward-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -F ${network.name}-input-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -X ${network.name}-forward-temp || true"
                        "${pkgs.iptables}/bin/ip6tables -X ${network.name}-input-temp || true"
                        "true"
                      ]) else [ ]
                    )
                  );
            };
          })
          networks);
    };

    # Enable IP forwarding on the server so peers can communicate with each other.
    boot =
      if isServer thisMachine then {
        kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
      } else { };
  };
}

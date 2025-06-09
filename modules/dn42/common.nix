{ lib, config, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
  activePeerings = thisMachine.dn42Peerings;

  dn42PeeringOpts = self: {
    options = {
      peerLinkLocal = lib.mkOption {
        type = lib.types.str;
        description = ''
          The link-local address of the peer.
        '';
        example = "fe80::715";
      };
      ownLinkLocal = lib.mkOption {
        type = lib.types.str;
        description = ''
          The link-local address of the local machine.
        '';
        example = "fe80::1234:5678";
      };
      asNumber = lib.mkOption {
        type = lib.types.str;
        description = ''
          The AS number of the peer.
        '';
        example = "4242420714";
      };
      networkName = lib.mkOption {
        description = ''
          The name of the network. You can only use lowercase letters, numbers, and underscores.
        '';
        example = "echonet";
        type = lib.types.str;
      };
      publicWireguardEndpoint = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = ''
          The public endpoint of the Wireguard peer.
        '';
        default = null;
        example = "de01.dn42.lare.cc:21403";
      };
      publicWireguardKey = lib.mkOption {
        type = lib.types.str;
        description = ''
          The public key of the Wireguard peer.
        '';
        example = "UrANRZ2S0WzUbo3cCaaaaaa/VAucFFeGLNP3aY/ovyM=";
      };
      publicWireguardPort = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = ''
          Our own public wireguard port.
        '';
        default = null;
        example = "5";
      };

    };
  };
in
{
  options = {
    modules.dn42.peerings = lib.mkOption {
      default = { };
      description = ''
        A dn42 peering and the name of the network. You can only use lowercase letters, numbers, and underscores.
      '';
      type = with lib.types; attrsOf (lib.types.submodule dn42PeeringOpts);
    };
  };

  config = {
    age.secrets = lib.mkMerge
      (builtins.map
        (networkName:
          {
            "${networkName}" = {
              file = ../../secrets/${networkName}_dn42.age;
              owner = "systemd-network";
              group = "systemd-network";
            };
          })
        activePeerings);

    networking.firewall = lib.mkMerge
      (builtins.map
        (networkName:
          let
            peering = config.modules.dn42.peerings.${networkName};
          in
          (lib.mkMerge [
            {
              interfaces."${networkName}".allowedTCPPorts = [ 179 ];
            }
            (
              lib.mkIf (peering.publicWireguardPort != null) {
                allowedUDPPorts = [ (lib.strings.toInt peering.publicWireguardPort) ];
              }
            )
          ])
        )
        activePeerings);

    systemd.network = lib.mkMerge
      (builtins.map
        (networkName:
          let
            peering = config.modules.dn42.peerings.${networkName};
          in
          {
            netdevs = {
              "50-${networkName}" = {
                netdevConfig = {
                  Kind = "wireguard";
                  Name = "${networkName}";
                  MTUBytes = "1420";
                };
                wireguardConfig = (lib.mkMerge
                  [{
                    PrivateKeyFile = config.age.secrets."${networkName}".path;
                  }
                    (
                      lib.mkIf (peering.publicWireguardPort != null) {
                        ListenPort = lib.strings.toInt peering.publicWireguardPort;
                      }
                    )]);
                wireguardPeers = [
                  (lib.mkMerge
                    [{
                      PublicKey = peering.publicWireguardKey;
                      AllowedIPs = [ "::/0" "0.0.0.0/0" ];
                      PersistentKeepalive = 25;
                    }
                      (
                        lib.mkIf (peering.publicWireguardEndpoint != null) {
                          Endpoint = peering.publicWireguardEndpoint;
                        }
                      )]
                  )
                ];
              };
            };
            networks."${networkName}" = {
              matchConfig.Name = "${networkName}";
              address = [ "${peering.ownLinkLocal}/64" ];
              routes = [{
                Destination = "${peering.peerLinkLocal}/128";
                Scope = "link";
              }];
              networkConfig = {
                IPv4Forwarding = true;
                IPv6Forwarding = true;
              };
            };
          }
        )
        activePeerings);

    services.bird = lib.mkMerge
      (builtins.map
        (networkName:
          let
            peering = config.modules.dn42.peerings.${networkName};
          in
          {
            config = lib.mkAfter ''
              protocol bgp ${networkName} from dnpeers {
                  neighbor ${peering.peerLinkLocal}%${networkName} as ${peering.asNumber};
              }
            '';
          }
        )
        activePeerings);
  };
}

# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}."${networkName}Dn42";

  peerLinkLocal = "fe80::715";
  ownLinkLocal = "fe80::1234:5678";
  asNumber = "4242420714";
  networkName = "echonet";
  publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
  publicWireguardKey = "UrANRZ2S0WzUbo3cCIbT0PP/VAucFFeGLNP3aY/ovyM=";
  publicWireguardPort = 5;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets."${networkName}" = {
      file = ../../secrets/${networkName}_dn42.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ publicWireguardPort ];
      firewall.interfaces."${networkName}".allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-${networkName}" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "${networkName}";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets."${networkName}".path;
            ListenPort = publicWireguardPort;
          };
          wireguardPeers = [{
            PublicKey = publicWireguardKey;
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            Endpoint = publicWireguardEndpoint;
            PersistentKeepalive = 25;
          }];
        };
      };
      networks."${networkName}" = {
        matchConfig.Name = "${networkName}";
        address = [ "${ownLinkLocal}/64" ];
        routes = [{
          Destination = "${peerLinkLocal}/128";
          Scope = "link";
        }];
        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };
      };
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp ${networkName} from dnpeers {
            neighbor ${peerLinkLocal}%${networkName} as ${asNumber};
        }
      '';
    };
  };
}

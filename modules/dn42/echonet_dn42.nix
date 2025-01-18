# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}."${peering.networkName}Dn42";

  peering = {
    peerLinkLocal = "fe80::715";
    ownLinkLocal = "fe80::1234:5678";
    asNumber = "4242420714";
    networkName = "echonet";
    publicWireguardEndpoint = "de01.dn42.lare.cc:21403";
    publicWireguardKey = "UrANRZ2S0WzUbo3cCIbT0PP/VAucFFeGLNP3aY/ovyM=";
    publicWireguardPort = 5;
  };
in
{
  config = lib.mkIf cfg.enable {
    age.secrets."${peering.networkName}" = {
      file = ../../secrets/${peering.networkName}_dn42.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ peering.publicWireguardPort ];
      firewall.interfaces."${peering.networkName}".allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-${peering.networkName}" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "${peering.networkName}";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets."${peering.networkName}".path;
            ListenPort = peering.publicWireguardPort;
          };
          wireguardPeers = [
            ({
              PublicKey = peering.publicWireguardKey;
              AllowedIPs = [ "::/0" "0.0.0.0/0" ];
              Endpoint = peering.publicWireguardEndpoint;
              PersistentKeepalive = 25;
            } ++ (
              lib.mkIf (peering ? "publicWireguardEndpoint") {
                Endpoint = peering.publicWireguardEndpoint;
              }
            ))
          ];
        };
      };
      networks."${peering.networkName}" = {
        matchConfig.Name = "${peering.networkName}";
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
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp ${peering.networkName} from dnpeers {
            neighbor ${peering.peerLinkLocal}%${peering.networkName} as ${peering.asNumber};
        }
      '';
    };
  };
}

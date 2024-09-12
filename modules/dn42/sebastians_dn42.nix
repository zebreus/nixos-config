# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.sebastiansDn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.sebastians_dn42 = {
      file = ../../secrets/sebastians_dn42.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ 2 ];
      firewall.interfaces.sebastians_dn42.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-sebastians_dn42" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "sebastians_dn42";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.sebastians_dn42.path;
            ListenPort = 2;
          };
          wireguardPeers = [{
            PublicKey = "saICY1kV8JbuPOQNQLtm9TnVP2CuxC0qFSkd69pEKQQ=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            Endpoint = "pioneer.sebastians.dev:51822";
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.sebastians_dn42 = {
        matchConfig.Name = "sebastians_dn42";
        address = [ "fe80::beef/64" ];
        routes = [{
          Destination = "fe80::cafe/128";
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
        protocol bgp sebastians_dn42 from dnpeers {
            neighbor fe80::cafe%sebastians_dn42 as 4242420611;
        }
      '';
    };
  };
}

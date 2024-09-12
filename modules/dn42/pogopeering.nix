# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.pogopeering;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.pogopeering = {
      file = ../../secrets/pogopeering.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ 1 ];
      firewall.interfaces.pogopeering.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-pogopeering" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "pogopeering";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.pogopeering.path;
            ListenPort = 1;
          };
          wireguardPeers = [{
            PublicKey = "DZ75UrnScBQlqPKH2vxzIcYJmbJ9rYKmEXc0J2+jgAs=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.pogopeering = {
        matchConfig.Name = "pogopeering";
        address = [ "fe80::acab/64" ];
        routes = [{
          Destination = "fe80::1213/128";
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
        protocol bgp pogopeering from dnpeers {
            neighbor fe80::1213%pogopeering as 4242420663;
        }
      '';
    };
  };
}

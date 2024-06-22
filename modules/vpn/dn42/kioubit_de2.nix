# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.kioubitDn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.kioubit_de2 = {
      file = ../../../secrets/kioubit_de2.age;
      mode = "0444";
    };

    networking = {
      firewall.interfaces.kioubit_de2.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-kioubit_de2" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "kioubit_de2";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.kioubit_de2.path;
          };
          wireguardPeers = [{
            PublicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            Endpoint = "de2.g-load.eu:21403";
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.kioubit_de2 = {
        matchConfig.Name = "kioubit_de2";
        address = [ "fe80::1920:4444/64" ];
        routes = [{
          Destination = "fe80::ade0/128";
          Scope = "link";
        }];
        networkConfig = {
          IPForward = true;
        };
      };
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp kioubit_de2 from dnpeers {
            neighbor fe80::ade0%kioubit_de2 as 4242423914;
        }
      '';
    };
  };
}

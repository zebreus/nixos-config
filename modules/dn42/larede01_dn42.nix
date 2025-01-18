# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.larede01Dn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.larede01 = {
      file = ../../secrets/larede01_dn42.age;
      owner = "systemd-network";
      group = "systemd-network";
    };

    networking = {
      firewall.allowedUDPPorts = [ 4 ];
      firewall.interfaces.larede01.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-larede01" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "larede01";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.larede01.path;
            ListenPort = 4;
          };
          wireguardPeers = [{
            PublicKey = "OL2LE2feDsFV+fOC4vo4u/1enuxf3m2kydwGRE2rKVs=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            Endpoint = "de01.dn42.lare.cc:21403";
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.larede01 = {
        matchConfig.Name = "larede01";
        address = [ "fe80::4249:7543/64" ];
        routes = [{
          Destination = "fe80::3035:130/128";
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
        protocol bgp larede01 from dnpeers {
            neighbor fe80::3035:130%larede01 as 4242423035;
        }
      '';
    };
  };
}

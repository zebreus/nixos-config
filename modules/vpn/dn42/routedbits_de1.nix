# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
# let
#   cfg = config.machines.${config.networking.hostName}.routedbitsDn42;
# in
{
  # TODO: Reenable if routedbits works
  # config = lib.mkIf cfg.enable {
  config = lib.mkIf false {
    age.secrets.routedbits_de1 = {
      file = ../../../secrets/routedbits_de1.age;
    };

    networking = {
      firewall.allowedTCPPorts = [ 57319 ];
      firewall.interfaces.routedbits_de1.allowedTCPPorts = [ 179 ];
    };

    systemd.network = {
      netdevs = {
        "50-routedbits_de1" = {
          netdevConfig = {
            Kind = "wireguard";
            Name = "routedbits_de1";
            MTUBytes = "1420";
          };
          wireguardConfig = {
            PrivateKeyFile = config.age.secrets.routedbits_de1.path;
            ListenPort = 57319;
          };
          wireguardPeers = [{
            PublicKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
            AllowedIPs = [ "::/0" "0.0.0.0/0" ];
            Endpoint = "router.fra1.routedbits.com:51403";
            PersistentKeepalive = 25;
          }];
        };
      };
      networks.routedbits_de1 = {
        matchConfig.Name = "routedbits_de1";
        address = [ "fe80::1920:3289/64" ];
        routes = [{
          Destination = "fe80::207/128";
          Scope = "link";
        }];
        networkConfig = {
          IPForward = true;
        };
      };
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp routedbits_de1 from dnpeers {
            neighbor fe80::207%routedbits_de1 as 4242420207;
        }
      '';
    };
  };
}

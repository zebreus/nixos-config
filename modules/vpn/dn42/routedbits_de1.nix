# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.routedbitsDn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.routedbits_de1 = {
      file = ../../../secrets/routedbits_de1.age;
      owner = "bird2";
      group = "bird2";
      mode = "0400";
    };

    networking = {
      firewall.allowedTCPPorts = [ 57319 ];
      firewall.interfaces.routedbits_de1.allowedTCPPorts = [ 179 ];

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        routedbits_de1 = {
          ips = [ "fe80::1920:3289/64" ];
          allowedIPsAsRoutes = false;
          listenPort = 57319;

          privateKeyFile = config.age.secrets.routedbits_de1.path;

          peers = [
            {
              name = "router.fra1.routedbits.com";
              publicKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
              persistentKeepalive = 25;
              allowedIPs = [ "0::/0" "0.0.0.0/0" ];

              # Set this to the server IP and port.
              endpoint = "router.fra1.routedbits.com:51403";
              dynamicEndpointRefreshSeconds = 60;
            }
          ];

          postSetup = ''
            ip -6 route add fe80::207/128 dev routedbits_de1 || true
          '';
          postShutdown = ''
            ip -6 route delete fe80::207/128 dev routedbits_de1 || true
          '';
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

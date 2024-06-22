# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.kioubitDn42;
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
      firewall.interfaces.kioubit_de2.allowedTCPPorts = [ 179 ];

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        kioubit_de2 = {
          ips = [ "fe80::1920:4444/64" ];
          allowedIPsAsRoutes = false;

          privateKeyFile = config.age.secrets.routedbits_de1.path;

          peers = [
            {
              name = "de2.g-load.eu";
              publicKey = "B1xSG/XTJRLd+GrWDsB06BqnIq8Xud93YVh/LYYYtUY=";
              persistentKeepalive = 25;
              allowedIPs = [ "0::/0" "0.0.0.0/0" ];

              # Set this to the server IP and port.
              endpoint = "de2.g-load.eu:21403";
              dynamicEndpointRefreshSeconds = 60;
            }
          ];

          postSetup = ''
            ip -6 route add fe80::ade0/128 dev kioubit_de2 || true
          '';
          postShutdown = ''
            ip -6 route delete fe80::ade0/128 dev kioubit_de2 || true
          '';
        };
      };
    };

    services.bird2 = {
      config = lib.mkAfter ''
        protocol bgp kioubit_de1 from dnpeers {
                neighbor fe80::ade0%kioubit_de2 as 4242423914;
        }
      '';
    };
  };
}

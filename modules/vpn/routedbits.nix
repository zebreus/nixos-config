# Establishes wireguard tunnels with all nodes with static IPs as hubs.
{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.routedbitsDn42;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets.routedbits_de1 = {
      file = ../../secrets/routedbits_de1.age;
      mode = "0444";
    };

    networking = {
      firewall = {
        allowedTCPPorts = [ 57319 ];
      };

      # Configure the WireGuard interface.
      wireguard.interfaces = {
        routedbitsde1 = {
          ips = [ "fe80::1920:3289/64" ];
          allowedIPsAsRoutes = false;
          listenPort = 57319;

          privateKeyFile = config.age.secrets.routedbits_de1.path;

          peers = [
            {
              name = "router.fra1.routedbits.com";
              publicKey = "FIk95vqIJxf2ZH750lsV1EybfeC9+V8Bnhn8YWPy/l8=";
              persistentKeepalive = 25;
              allowedIPs = [ "fe80::207/128" "0::/0" ];

              # Set this to the server IP and port.
              endpoint = "router.fra1.routedbits.com:51403";
              dynamicEndpointRefreshSeconds = 60;
            }
          ];

          postSetup = "ip -6 route add fe80::207/128 dev routedbitsde1 || true";
          postShutdown = "ip -6 route delete fe80::207/128 dev routedbitsde1 || true";
        };
      };
    };

    # Enable IP forwarding
    boot = {
      kernel.sysctl."net.ipv6.conf.all.forwarding" = lib.mkDefault true;
      kernel.sysctl."net.ipv4.ip_forward" = lib.mkDefault true;
    };
  };
}

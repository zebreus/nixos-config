{ pkgs, ... }:
let
  websockify = pkgs.python312Packages.websockify.overridePythonAttrs (_: {
    doCheck = false;
  });
in
{
  services.nginx = {
    enable = true;

    virtualHosts."web.nowhere.wirs.ing" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8081";
        proxyWebsockets = true;
        extraConfig = ''
          # Only allow WebSocket upgrades
          if ($http_upgrade != "websocket") {
            return 426;
          }
          if ($http_connection !~* "upgrade") {
            return 426;
          }

          proxy_buffering off;
          proxy_read_timeout 1h;
          proxy_send_timeout 1h;

          # Allow connections from any origin
          add_header Access-Control-Allow-Origin "*" always;
          if ($request_method = OPTIONS) {
            return 204;
          }
        '';
      };
    };
  };

  systemd.services.websockify-nowhere = {
    description = "WebSocket-to-SSH proxy for nowhere.wirs.ing";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "nss-lookup.target" ];
    wants = [ "network-online.target" "nss-lookup.target" ];

    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${websockify}/bin/websockify 127.0.0.1:8081 nowhere.wirs.ing:22";
      Restart = "on-failure";
      RestartSec = 5;

      # ridiculous amount of hardening
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      IPAddressDeny = "any";
      IPAddressAllow = [
        "127.0.0.1/32"
        "::1/128"
        "45.13.237.176/32"
        "2a0e:97c0:711:11b::1/128"
      ];
      SocketBindAllow = "tcp:127.0.0.1:8081";
      SocketBindDeny = "any";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateDevices = true;
      ReadOnlyPaths = [ "/etc/ssl/certs" ];
      BindReadOnlyPaths = [
        "/etc/hosts"
        "/etc/nsswitch.conf"
        "/etc/resolv.conf"
        "/run/systemd/resolve"
      ];
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
        "~@resources"
      ];
      UMask = "0077";
    };
  };
}

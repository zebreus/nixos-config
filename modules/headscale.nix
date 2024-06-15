{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.headscale;
  domain = "headscale.antibuild.ing";
in
{
  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = "lennarteichhorn@googlemail.com";
    };

    services = {
      headscale = {
        enable = true;
        address = "0.0.0.0";
        port = 8562;
        settings = {
          server_url = "https://${domain}";
          dns = {
            baseDomain = "example.com";
          };
          logtail.enabled = false;
          # prefixes = {
          #   v6 = "fd10:2031::/120";
          #   v4 = "10.20.31.0/24";
          # };
        };
      };

      nginx.virtualHosts.${domain} = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.headscale.port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}

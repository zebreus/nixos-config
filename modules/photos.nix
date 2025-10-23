{ lib, config, ... }:
with lib;
let
  cfg = config.machines.${config.networking.hostName}.photosServer;
  baseDomain = "zebre.us";
in
{
  config = mkIf cfg.enable {
    # Get certs
    security.acme = {
      acceptTerms = true;
      certs = {
        "photos.${baseDomain}".email = "lennarteichhorn@googlemail.com";
      };
    };

    services.immich = {
      enable = true;
      port = 18282;
      host = "::1";
    };

    services.nginx.virtualHosts."photos.${baseDomain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.immich.port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50000M;
          proxy_read_timeout   600s;
          proxy_send_timeout   600s;
          send_timeout         600s;
        '';
      };
    };
  };
}




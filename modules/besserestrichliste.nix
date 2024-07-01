{ config, lib, ... }:
let
  cfg = config.machines.${config.networking.hostName}.besserestrichlisteServer;
in
{
  config = lib.mkIf cfg.enable {
    # Temporary besserestrichliste deployment

    services.besserestrichliste = {
      enable = true;
      port = 8080;
      host = "localhost";
      origin = "https://besserer.wirs.ing";
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    # Get certs
    security.acme = {
      acceptTerms = true;
      certs = {
        "besserer.wirs.ing".email = "lennart@zebre.us";
      };
    };

    services.nginx = {
      enable = true;
      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      virtualHosts = {
        "besserer.wirs.ing" = {
          enableACME = true;
          forceSSL = true;
          locations = {
            "/".proxyPass = "http://[::1]:8080";
          };
        };
      };
    };
  };
}

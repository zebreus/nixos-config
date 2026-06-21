{ config, lib, ... }:
let
  cfg = config.meta.self.besserestrichliste;
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

    services.nginx = {
      enable = true;
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

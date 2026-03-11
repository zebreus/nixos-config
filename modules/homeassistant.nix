{ config, lib, ... }:
let
  thisMachine = config.machines."${config.networking.hostName}";
in
{
  config = lib.mkIf thisMachine.homeassistantServer.enable {
    services.home-assistant = {
      enable = true;
      # opt-out from declarative configuration management
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
      };
      # lovelaceConfig = null;
      # configure the path to your config directory
      # configDir = "/etc/home-assistant";
      # specify list of components required by your configuration
      extraComponents = [
        "analytics"
        "google_translate"
        "met"
        "radio_browser"
        "shopping_list"
        "default_config"
        # Recommended for fast zlib compression
        # https://www.home-assistant.io/integrations/isal
        "isal"
        "esphome"
      ];
    };
    networking.firewall.allowedTCPPorts = [ 80 443 ];
    # Get certs
    security.acme = {
      acceptTerms = true;
      defaults.email = "lennarteichhorn@googlemail.com";
    };

    services.nginx = {
      enable = true;
      # Only allow PFS-enabled ciphers with AES256
      # sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      # recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts."hass.zebre.us" = {
        enableACME = false;
        # forceSSL = false;
        addSSL = false;
        locations."/" = {
          proxyPass = "http://localhost:8123";
          proxyWebsockets = true;
          # recommendedProxySettings = true;
          # extraConfig = ''
          #   client_max_body_size 50000M;
          #   proxy_read_timeout   600s;
          #   proxy_send_timeout   600s;
          #   send_timeout         600s;
          # '';
        };
      };
    };
  };
}

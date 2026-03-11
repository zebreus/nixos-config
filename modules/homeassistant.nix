{ pkgs, config, lib, ... }:
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
        homeassistant = {
          time_zone = "Europe/Berlin";
          latitude = 52.52;
          longitude = 13.40;
          unit_system = "metric";
          country = "DE";
          temperature_unit = "C";
          # external_url = "http://192.168.0.43";
          external_url = "https://hass.zebre.us";
          # media_dirs.media = "/media";
          allowlist_external_dirs = [
            "/tmp"
            # "/media"
          ];
        };
        http = {
          server_host = [ "0.0.0.0" "::" ];
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = [ "::1" ];

        };
        lovelace = {
          mode = "storage";
          resources = [ ];
        };
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
        "matter"
        "mqtt"
      ];
      extraPackages = python3Packages: with python3Packages; [
        numpy
        python-matter-server
        getmac
      ];
    };
    # services.matter-server = {
    #   enable = true;
    #   logLevel = "debug";
    #   openFirewall = true;
    #   port = 5580;
    #   extraArgs =
    #     let
    #       cert-dir = pkgs.fetchFromGitHub {
    #         repo = "connectedhomeip";
    #         owner = "project-chip";
    #         rev = "ec85153519cbfb9e9c5b8f34d801bdcc2787e272";
    #         hash = "sha256-ZI/tvqsSNUtvB9JhRAK2jVMmycS3RnGdsSvLAM7ye14=";
    #       };
    #     in
    #     [
    #       # "--bluetooth-adapter=0"
    #       "--paa-root-cert-dir=${cert-dir}/credentials/production/paa-root-certs"
    #       "--enable-test-net-dcl"
    #       "--ota-provider-dir=/var/lib/matter-server/ota-provider"
    #     ];
    # };
    services.matter-server = {
      enable = true;
      logLevel = "debug";
      extraArgs =
        let
          cert-dir = pkgs.fetchFromGitHub {
            repo = "connectedhomeip";
            owner = "project-chip";
            rev = "6e8676be6142bb541fa68048c77f2fc56a21c7b1";
            hash = "sha256-QwPKn2R4mflTKMyr1k4xF04t0PJIlzNCOdXEiQwX5wk=";
          };
        in
        [
          "--bluetooth-adapter=0"
          "--paa-root-cert-dir=${cert-dir}/credentials/production/paa-root-certs"
          "--enable-test-net-dcl"
          "--ota-provider-dir=/var/lib/matter-server/ota-provider"
        ];
    };
    # virtualisation.oci-containers.containers = {
    #   matter-server = {
    #     image = "ghcr.io/home-assistant-libs/python-matter-server:6.6.1";
    #     volumes = [
    #       "/var/lib/matter:/data"
    #       "/run/dbus:/run/dbus:ro"
    #     ];
    #     extraOptions = [
    #       "--network=host"
    #       "--security-opt=apparmor=unconfined"
    #     ];
    #     cmd = [ "--storage-path" "/data" ];
    #   };
    # };
    networking.firewall.allowedTCPPorts = [ 80 443 8123 5540 5541 5353 1900 ];
    networking.firewall.allowedUDPPorts = [ 80 443 5540 5541 5353 1900 ];
    # Get certs
    security.acme = {
      acceptTerms = true;
      defaults.email = "lennarteichhorn@googlemail.com";
    };

    services.nginx = {
      enable = true;
      # Only allow PFS-enabled ciphers with AES256
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts."hass.zebre.us" = {
        enableACME = true;
        # useACMEHost = "hass.zebre.us";
        # forceSSL = false;
        # addSSL = false;
        # rejectSSL = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
          # basicAuth = { user = "password8"; };
          recommendedProxySettings = true;

          # extraConfig = ''
          #   client_max_body_size 50000M;
          #   proxy_read_timeout   600s;
          #   proxy_send_timeout   600s;
          #   send_timeout         600s;
          # '';
          extraConfig = ''
            allow ${thisMachine.staticIp6}/64;
            allow ::1;
            allow 127.0.0.1;
            allow fe80::/64;
            allow 192.168.0.0/24;
            deny all;
          '';
        };
      };
    };
  };
}

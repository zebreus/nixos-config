{ config, lib, ... }:
let
  thisMachine = config.meta.self;
in
{
  config = lib.mkIf thisMachine.homeassistant.enable {
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
        # automation = [
        #   {
        #     alias = "Wecker";
        #     description = "";
        #     mode = "single";
        #     trigger = [
        #       {
        #         platform = "sun";
        #         event = "sunrise";
        #         offset = 0;
        #       }
        #     ];
        #     condition = [ ];
        #     action = [
        #       {
        #         action = "light.turn_on";
        #         metadata = { };
        #         target = {
        #           entity_id = "light.hue_white_lamp";
        #         };
        #         data = {
        #           transition = 114;
        #           brightness_pct = 100;
        #         };
        #       }
        #     ];
        #   }
        # ];
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
      # `extraArgs` is now an attribute set, converted to a GNU command line by
      # the module. `log-level`, `ota-provider-dir` and `paa-root-cert-dir` are
      # set by the module itself, so they are no longer passed here.
      extraArgs = {
        bluetooth-adapter = 0;
        log-level-sdk = "debug";
      };
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
    networking.firewall.allowedTCPPorts = [ 8123 5540 5541 5353 1900 ];
    networking.firewall.allowedUDPPorts = [ 5540 5541 5353 1900 ];
    systemd.network.networks.enp3s0.networkConfig.MulticastDNS = true;

    services.nginx = {
      enable = true;
      virtualHosts."hass.zebre.us" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;

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
            allow 192.168.178.0/24;
            deny all;
          '';
        };
      };
    };
  };
}

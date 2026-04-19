{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.machines.${config.networking.hostName}.matrixLiteServer;
  # inherit (cfg) baseDomain;
  inherit (cfg) baseDomain;
  turnDomain = "turn.${baseDomain}";
  elementDomain = "element.${baseDomain}";
  synapseDomain = "matrix.${baseDomain}";
  clientConfig."m.homeserver".base_url = "https://${synapseDomain}";
  serverConfig."m.server" = "${synapseDomain}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
  email = cfg.certEmail;

  hostAddress = "192.168.208.10";
  containerAddress = "192.168.208.11";
  hostAddress6 = "fc00:9292::1";
  containerAddress6 = "fc00:9292::2";
in
{
  config = mkIf cfg.enable {
    # Define the files with the secrets
    age.secrets = {
      # coturn_static_auth_secret = {
      #   file = ../secrets/coturn_static_auth_secret.age;
      #   owner = "turnserver";
      # };
      # coturn_static_auth_secret_matrix_config = {
      #   file = ../secrets/coturn_static_auth_secret_matrix_config.age;
      #   owner = "matrix-synapse";
      # };
    };

    # nixpkgs.config.element-web = {
    #   conf = {
    #     show_labs_settings = true;
    #     default_theme = "dark";
    #     default_server_config = clientConfig;
    #     brand = "wirs.ing";
    #     permalink_prefix = "https://element.zebre.us";
    #     branding = element-branding;
    #   };
    # };
    # # Patch the welcome strings on the login page to say the domain instead of element
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     element-web-unwrapped = prev.element-web-unwrapped.overrideAttrs (old: {
    #       prePatch = ''
    #         sed -Ei 's/("welcome_to_element": ")([^"]*)Element([^"]*")/\1\2${baseDomain}\3/' src/i18n/strings/*.json
    #       '';
    #     });
    #   })
    # ];

    networking.nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      # externalInterface = "ens3";
      # Lazy IPv6 connectivity for the container
      enableIPv6 = true;
    };

    # Enable the PostgreSQL service.
    containers.matrix-lite = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = hostAddress;
      localAddress = containerAddress;
      hostAddress6 = hostAddress6;
      localAddress6 = containerAddress6;

      config = {
        # open the firewall
        networking = {
          firewall = {
            allowedTCPPorts = [ 8008 8009 ];
          };
          # Use systemd-resolved inside the container
          # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
          useHostResolvConf = lib.mkForce false;
        };
        services.resolved.enable = true;
        system.stateVersion = "26.05";

        services = {
          postgresql = {
            enable = true;
            initialScript = pkgs.writeText "synapse-init.sql" ''
              CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD 'synapse';
              CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
                TEMPLATE template0
                LC_COLLATE = "C"
                LC_CTYPE = "C";
            '';
          };
          matrix-synapse = {
            enable = true;
            settings = {
              server_name = baseDomain;
              # The public base URL value must match the `base_url` value set in `clientConfig` above.
              # The default value here is based on `server_name`, so if your `server_name` is different
              # from the value of `fqdn` above, you will likely run into some mismatched domain names
              # in client applications.
              public_baseurl = "https://${synapseDomain}";
              listeners = [
                {
                  port = 8008;
                  bind_addresses = [ "${containerAddress6}" ];
                  type = "http";
                  tls = false;
                  x_forwarded = true;
                  resources = [{
                    names = [ "client" "federation" ];
                    compress = true;
                  }];
                }
              ];
              max_upload_size = "500M";

              turn_uris = [ "turn:${config.services.coturn.realm}:3478?transport=udp" "turn:${config.services.coturn.realm}:3478?transport=tcp" ];
              turn_user_lifetime = "1h";
            };
            # There is no file option for the coturn static auth secret, so we need to add it via extraConfigFiles
            extraConfigFiles = [
              config.age.secrets.coturn_static_auth_secret_matrix_config.path
            ];
          };
          nginx = {
            enable = true;
            virtualHosts = {
              ${elementDomain} = {
                default = true;
                listen = [{ port = 8009; addr = "[${containerAddress6}]"; }];
                enableACME = false;
                forceSSL = false;
                root = pkgs.element-web;
              };
            };
          };
        };
      };
    };
    services = {
      nginx = {
        enable = true;
        virtualHosts = {
          ${baseDomain} = {
            enableACME = true;
            forceSSL = true;
            locations = {
              "= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
              "= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
              "/.well-known".extraConfig = ''
                try_files $uri $uri/ =404;
              '';
              "/".extraConfig = ''
                return 301 $scheme://${elementDomain}$request_uri;
              '';
            };
          };
          ${synapseDomain} = {
            enableACME = true;
            forceSSL = true;
            # Forward all Matrix API calls to the synapse Matrix homeserver. A trailing slash
            # *must not* be used here.
            locations = {
              "/_matrix".proxyPass = "http://[${containerAddress6}]:8008";
              # Forward requests for e.g. SSO and password-resets.
              "/_synapse/client".proxyPass = "http://[${containerAddress6}]:8008";
              "/".extraConfig = ''
                return 301 $scheme://${elementDomain}$request_uri;
              '';
            };
          };
          # ${turnDomain} = {
          #   enableACME = true;
          #   forceSSL = true;
          #   # It's also possible to do a redirect here or something else, this vhost is not
          #   # needed for Matrix. It's recommended though to *not put* element
          #   # here, see also the section about Element.
          #   locations = {
          #     "/".extraConfig = ''
          #       return 301 $scheme://${elementDomain}$request_uri;
          #     '';
          #   };
          # };
          ${elementDomain} = {
            enableACME = true;
            forceSSL = true;
            # serverAliases = [
            #   elementDomain
            # ];
            locations."/" = {
              proxyPass = "http://[${containerAddress6}]:8009";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
            # locations = {
            #   "/extra/resources/" = { alias = element-branding-resources + "/"; };
            # };
          };
        };
      };
    };
  };
}

{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.machines.${config.networking.hostName}.matrixLiteServer;
  inherit (cfg) baseDomain;
  elementDomain = "element.${baseDomain}";
  adminDomain = "admin.${baseDomain}";
  synapseDomain = "matrix.${baseDomain}";
  clientConfig."m.homeserver".base_url = "https://${synapseDomain}";
  serverConfig."m.server" = "${synapseDomain}:443";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
  element-branding = {
    welcome_background_url = "/extra/resources/wirsing.webp";
    auth_header_logo_url = "/extra/resources/wirsing-logo.webp";
    auth_footer_links = [{ "text" = "Über Wirsing"; "url" = "https://de.wikipedia.org/wiki/Wirsing"; }];
  };
  branded-element-web = pkgs.element-web.override
    {
      conf = {
        show_labs_settings = true;
        default_theme = "dark";
        default_server_config = clientConfig;
        brand = "wirsing";
        permalink_prefix = "https://element.wirs.ing";
        branding = element-branding;
      };
    };
  synapse-admin = pkgs.ketesa.withConfig {
    restrictBaseUrl = [
      "https://${synapseDomain}"
    ];
  };
in
{
  config = mkIf cfg.enable {
    containers.matrix-lite = {
      autoStart = true;
      privateNetwork = false;
      bindMounts = {
        "${config.age.secrets.coturn_static_auth_secret_matrix_config.path}" = {
          hostPath = "${config.age.secrets.coturn_static_auth_secret_matrix_config.path}";
          isReadOnly = true;
        };
        "${config.age.secrets.coturn_static_auth_secret.path}" = {
          hostPath = "${config.age.secrets.coturn_static_auth_secret.path}";
          isReadOnly = true;
        };
      };
      config = {
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
            settings.port = 5433;
          };
          matrix-synapse = {
            enable = true;
            settings = {
              server_name = baseDomain;
              public_baseurl = "https://${synapseDomain}";
              database.args.port = 5433;
              registration_requires_token = true;
              listeners = [
                {
                  port = 28008;
                  bind_addresses = [ "::1" ];
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
                listen = [{ port = 28009; addr = "[::1]"; }];
                enableACME = false;
                forceSSL = false;
                root = branded-element-web;
                locations = {
                  "= /extra/resources/wirsing.webp" = { alias = ../resources/wirsing.webp; };
                  "= /extra/resources/wirsing-logo.webp" = { alias = ../resources/wirsing-logo.webp; };
                  "= /favicon.ico" = { alias = ../resources/wirsing.ico; };
                  "= /vector-icons/24.97ab000.png" = { alias = ../resources/wirsing/24.97ab000.png; };
                  "= /vector-icons/120.570a7f9.png" = { alias = ../resources/wirsing/120.570a7f9.png; };
                  "= /vector-icons/144.5a63bf2.png" = { alias = ../resources/wirsing/144.5a63bf2.png; };
                  "= /vector-icons/152.1ccdc8a.png" = { alias = ../resources/wirsing/152.1ccdc8a.png; };
                  "= /vector-icons/180.30b915f.png" = { alias = ../resources/wirsing/180.30b915f.png; };
                  "= /vector-icons/512.7ce350d.png" = { alias = ../resources/wirsing/512.7ce350d.png; };
                };
              };
              "${adminDomain}" = {
                default = true;
                listen = [{ port = 28010; addr = "[::1]"; }];
                enableACME = false;
                forceSSL = false;
                root = synapse-admin;
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
              "/_matrix".proxyPass = "http://[::1]:28008";
              "/_synapse/client".proxyPass = "http://[::1]:28008";
              "/_synapse/admin" = {
                proxyPass = "http://[::1]:28008";
                extraConfig = ''
                  allow ::1;
                  allow 127.0.0.1;
                  allow fe80::/64;
                  allow 192.168.178.0/24;
                  allow 2a03:4000:20:19d::1/64;
                  allow 159.195.88.96/32;
                  deny all;
                '';
              };
              "/" = {
                proxyPass = "http://[::1]:28010";
                proxyWebsockets = true;
                recommendedProxySettings = true;
              };
              # "/".extraConfig = ''
              #   return 301 $scheme://${elementDomain}$request_uri;
              # '';
            };
          };
          ${elementDomain} = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
              proxyPass = "http://[::1]:28009";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
      };
    };
  };
}

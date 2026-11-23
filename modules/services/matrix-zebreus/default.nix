{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.meta.self.matrixZebreus;
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
  branded-element-web = pkgs.element-web.override {
    conf = {
      show_labs_settings = true;
      default_theme = "dark";
      default_server_config = clientConfig;
      brand = "zebre.us";
      permalink_prefix = "https://element.zebre.us";
    };
  };
  synapse-admin = pkgs.ketesa.withConfig {
    restrictBaseUrl = [
      "https://${synapseDomain}"
    ];
  };
in
{
  imports = [ ./dns.nix ];

  config = mkIf cfg.enable {
    age.secrets.coturn_static_auth_secret = { };

    # Synapse, its database and the nginx for element and synapse-admin run in
    # a gVisor sandbox. The host's nginx proxies to them over IPv6.
    isocon.matrix-zebreus = {
      tcpPorts = map (port: { inherit port; ipv4 = false; ipv6 = true; }) [ 18008 18009 18010 ];
      # Federation goes to whatever port the other server chooses, and to
      # wirs.ing on this host on 443.
      outgoingTcpPorts = [{ port = "1-65535"; } { port = 443; local = true; global = false; }];
      persist = [
        # The signing key and the media.
        { path = "/var/lib/matrix-synapse"; backup = true; }
        { path = "/var/lib/postgresql"; backup = true; }
      ];
      credentials.turn = config.age.secrets.coturn_static_auth_secret.path;
      config = {
        # Not the host's: it decides the version of postgresql and so of its
        # data directory.
        system.stateVersion = "26.05";
        systemd.services.matrix-synapse.serviceConfig.LoadCredential = [ "turn" ];
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
              public_baseurl = "https://${synapseDomain}";
              listeners = [
                {
                  port = 18008;
                  bind_addresses = [ "::" ];
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

              turn_uris = [ "turn:turn.${config.meta.services.turn.baseDomain}:3478?transport=udp" "turn:turn.${config.meta.services.turn.baseDomain}:3478?transport=tcp" ];
              turn_shared_secret_path = "/run/credentials/matrix-synapse.service/turn";
              turn_user_lifetime = "1h";
            };
          };
          nginx = {
            enable = true;
            # The host's nginx passes redirects on unchanged, so they can't
            # name the guest's port.
            appendHttpConfig = "absolute_redirect off;";
            virtualHosts = {
              ${elementDomain} = {
                listen = [{ port = 18009; addr = "[::]"; }];
                root = branded-element-web;
              };
              ${adminDomain} = {
                listen = [{ port = 18010; addr = "[::]"; }];
                root = synapse-admin;
              };
            };
          };
        };
      };
    };

    services.nginx = {
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
            "/_matrix".proxyPass = "http://[::1]:18008";
            # Forward requests for e.g. SSO and password-resets.
            "/_synapse/client".proxyPass = "http://[::1]:18008";
            "/_synapse/admin" = {
              proxyPass = "http://[::1]:18008";
              extraConfig = ''
                allow ::1;
                allow 127.0.0.1;
                allow fe80::/64;
                allow 192.168.178.0/24;
                allow 2a03:4000:20:19d::/64;
                allow 159.195.88.96/32;
                deny all;
              '';
            };
            "/" = {
              proxyPass = "http://[::1]:18010";
              proxyWebsockets = true;
              recommendedProxySettings = true;
            };
          };
        };
        ${elementDomain} = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://[::1]:18009";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };
      };
    };
  };
}

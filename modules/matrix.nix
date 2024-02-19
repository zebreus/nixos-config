{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.matrix;
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
in
{
  options.modules.matrix = {
    enable = mkEnableOption "Enable matrix server";

    baseDomain = mkOption {
      type = types.str;
      description = "Base domain for the matrix server. You need to setup the DNS records for this domain and for the matrix, element, and turn subdomains.";
    };

    certEmail = mkOption {
      type = types.str;
      description = "Email address to use for Let's Encrypt certificates.";
    };
  };

  config = mkIf cfg.enable {
    # Define the files with the secrets
    age.secrets.coturn_static_auth_secret = {
      file = ../secrets/coturn_static_auth_secret.age;
      owner = "turnserver";
    };
    age.secrets.coturn_static_auth_secret_matrix_config = {
      file = ../secrets/coturn_static_auth_secret_matrix_config.age;
      owner = "matrix-synapse";
    };
    age.secrets.matrix_backup_passphrase = {
      file = ../secrets/matrix_backup_passphrase.age;
    };

    # Get certs
    security.acme = {
      acceptTerms = true;
      certs = {
        ${baseDomain}.email = email;
        ${elementDomain}.email = email;
        ${synapseDomain}.email = email;
        ${turnDomain} = {
          postRun = "systemctl restart coturn.service";
          inherit email;
        };
      };
    };

    # open the firewall
    networking.firewall = {
      allowedUDPPortRanges = [{
        from = config.services.coturn.min-port;
        to = config.services.coturn.max-port;
      }];
      allowedUDPPorts = [ 3478 5349 ];
      allowedTCPPortRanges = [ ];
      allowedTCPPorts = [ 80 443 3478 5349 ];
    };

    nixpkgs.config.element-web.conf = {
      show_labs_settings = true;
      default_theme = "dark";
    };

    # Enable the PostgreSQL service.
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

      nginx = {
        enable = true;
        # Only allow PFS-enabled ciphers with AES256
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;
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
              "/_matrix".proxyPass = "http://[::1]:8008";
              # Forward requests for e.g. SSO and password-resets.
              "/_synapse/client".proxyPass = "http://[::1]:8008";
              "/".extraConfig = ''
                return 301 $scheme://${elementDomain}$request_uri;
              '';
            };
          };
          ${turnDomain} = {
            enableACME = true;
            forceSSL = true;
            # It's also possible to do a redirect here or something else, this vhost is not
            # needed for Matrix. It's recommended though to *not put* element
            # here, see also the section about Element.
            locations = {
              "/".extraConfig = ''
                return 301 $scheme://${elementDomain}$request_uri;
              '';
            };
          };
          ${elementDomain} = {
            enableACME = true;
            forceSSL = true;
            serverAliases = [
              elementDomain
            ];

            root = pkgs.element-web.override {
              conf = {
                default_server_config = clientConfig; # see `clientConfig` from the snippet above.
              };
            };
          };
        };
      };

      # enable coturn
      coturn = {
        enable = true;
        no-cli = true;
        no-tcp-relay = true;
        min-port = 49000;
        max-port = 50000;
        use-auth-secret = true;
        static-auth-secret-file = config.age.secrets.coturn_static_auth_secret.path;
        realm = turnDomain;
        cert = "${config.security.acme.certs.${turnDomain}.directory}/full.pem";
        pkey = "${config.security.acme.certs.${turnDomain}.directory}/key.pem";
        extraConfig = ''
          # for debugging
          verbose
          # ban private IP ranges
          no-multicast-peers
          denied-peer-ip=0.0.0.0-0.255.255.255
          denied-peer-ip=10.0.0.0-10.255.255.255
          denied-peer-ip=100.64.0.0-100.127.255.255
          denied-peer-ip=127.0.0.0-127.255.255.255
          denied-peer-ip=169.254.0.0-169.254.255.255
          denied-peer-ip=172.16.0.0-172.31.255.255
          denied-peer-ip=192.0.0.0-192.0.0.255
          denied-peer-ip=192.0.2.0-192.0.2.255
          denied-peer-ip=192.88.99.0-192.88.99.255
          denied-peer-ip=192.168.0.0-192.168.255.255
          denied-peer-ip=198.18.0.0-198.19.255.255
          denied-peer-ip=198.51.100.0-198.51.100.255
          denied-peer-ip=203.0.113.0-203.0.113.255
          denied-peer-ip=240.0.0.0-255.255.255.255
          denied-peer-ip=::1
          denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
          denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
          denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
          denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
          denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
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

      # Restore backup: 
      # borgmatic extract --archive latest --path var/lib/matrix-synapse --destination /var/lib/matrix-synapse
      # borgmatic restore --archive latest
      borgmatic = {
        enable = true;
        settings = {
          source_directories = [ "/var/lib/matrix-synapse" ];
          postgresql_databases = [
            {
              name = "matrix-synapse";
              username = "matrix-synapse";
              password = "synapse";
              hostname = "127.0.0.1";
            }
          ];
          repositories = [
            {
              path = "ssh://borg@kappril//storage/borg/matrix";
              label = "kappril";
            }
          ];
          archive_name_format = "matrix-{now}";
          ssh_command = "ssh -i ${config.age.secrets.ssh_host_key_ed25519.path}";
          encryption_passcommand = "cat ${config.age.secrets.matrix_backup_passphrase.path}";
          keep_daily = 7;
          keep_within = "24H";
          skip_actions = [ "prune" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      (with pkgs;
      writeScriptBin "restore-matrix-from-backup" ''
        #!${bash}/bin/bash

        read -r -p "Are you sure you want to restore from the latest backup? This will destroy the current data. [y/N]" -n 1
        echo # (optional) move to a new line
        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            echo "Operation continues"
        else
            echo "Operation aborted"
            exit 1
        fi

        set -e
        set -x
        
        systemctl stop matrix-synapse

        rm -rf /var/lib/matrix-synapse

        borgmatic extract --archive latest --path var/lib/matrix-synapse --destination /var/lib/matrix-synapse
        borgmatic restore --archive latest

        echo Backup restored. To start the server again run:
        echo systemctl start matrix-synapse
      '')
    ];
  };
}

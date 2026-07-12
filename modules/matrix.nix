{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.meta.self.matrix;
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

  element-branding-resources = pkgs.runCommand "element-branding-resources"
    {
      src = [
        ../resources/blobs-dark.webp
        ../resources/icon.webp
      ];
    } ''
    mkdir -p $out
    for file in $src; do
      out_name=$(echo $file | sed -E 's|/nix/store/[^-]+-||')
      cp $file $out/$out_name
    done
  '';
  element-branding = {
    # When a string, the URL for the full-page image background of the login, registration, and welcome pages. This property can additionally be an array to have the app choose an image at random from the selections.
    welcome_background_url = "/extra/resources/blobs-dark.webp";
    # A URL to the logo used on the login, registration, etc pages.
    auth_header_logo_url = "/extra/resources/icon.webp";
    # A list of links to add to the footer during login, registration, etc. Each entry must have a text and url property.
    # auth_footer_links = [ ];
  };
  branded-element-web = pkgs.element-web.override {
    conf = {
      show_labs_settings = true;
      default_theme = "dark";
      default_server_config = clientConfig;
      brand = "zebre.us";
      permalink_prefix = "https://element.zebre.us";
      branding = element-branding;
    };
  };

  backupRepo = lib.findFirst (r: r.name == "matrix")
    (throw "No backup repo matrix in meta.allBackupRepos")
    config.meta.allBackupRepos;
  # The secrets only exist once terraform has been run for this repo.
  resticSecretsPresent = builtins.pathExists ../secrets/matrix_restic_password.age
    && builtins.pathExists ../secrets/shared_restic_environment.age;
in
{
  config = mkIf cfg.enable {
    # Define the files with the secrets
    age.secrets = {
      coturn_static_auth_secret = {
        file = ../secrets/coturn_static_auth_secret.age;
        owner = "turnserver";
      };
      coturn_static_auth_secret_matrix_config = {
        file = ../secrets/coturn_static_auth_secret_matrix_config.age;
        owner = "matrix-synapse";
      };
    } // lib.optionalAttrs resticSecretsPresent {
      matrix_restic_password.file = ../secrets/matrix_restic_password.age;
      shared_restic_environment.file = ../secrets/shared_restic_environment.age;
    };

    warnings = lib.optional (!resticSecretsPresent)
      "Matrix backups are disabled because the restic secrets are missing. Run `nix run .#terraform -- apply && nix run .#sync-restic-secrets` and rebuild.";

    # Get certs
    security.acme = {
      certs = {
        ${turnDomain} = {
          postRun = "systemctl restart coturn.service";
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
      allowedTCPPorts = [ 3478 5349 ];
    };

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
            root = branded-element-web;
            locations = {
              "/extra/resources/" = { alias = element-branding-resources + "/"; };
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

          # log = {
          #   disable_existing_loggers = false;
          #   formatters = {
          #     journal_fmt = {
          #       format = "%(name)s: [%(request)s] %(message)s";
          #     };
          #   };
          #   handlers = {
          #     journal = {
          #       class = "systemd.journal.JournalHandler";
          #       formatter = "journal_fmt";
          #     };
          #   };
          #   loggers = {
          #     synapse.federation =
          #       { level = "DEBUG"; };
          #     synapse.handlers.federation =
          #       { level = "DEBUG"; };
          #     synapse.federation.sender =
          #       { level = "DEBUG"; };
          #     synapse.federation.federation_client =
          #       { level = "DEBUG"; };
          #     synapse.federation.federation_server =
          #       { level = "DEBUG"; };
          #     synapse.federation.transport.client =
          #       { level = "DEBUG"; };
          #     synapse.handlers.federation_event =
          #       { level = "DEBUG"; };
          #     synapse.handlers.federation_state =
          #       { level = "DEBUG"; };
          #     synapse.handlers.room_member =
          #       { level = "DEBUG"; };
          #     synapse.storage.databases.main.events =
          #       { level = "DEBUG"; };
          #   };
          #   root = {
          #     handlers = [
          #       "journal"
          #     ];
          #     level = "INFO";
          #   };
          #   version = 1;
          # };
        };
        # There is no file option for the coturn static auth secret, so we need to add it via extraConfigFiles
        extraConfigFiles = [
          config.age.secrets.coturn_static_auth_secret_matrix_config.path
        ];
      };

      # Create db dump 5 minutes before the restic backup
      postgresqlBackup =
        {
          enable = true;
          startAt = "*-*-* 00/1:55:00";
          databases = [
            "matrix-synapse"
          ];
          compression = "none";
          location = "/var/backup/postgresql";
          pgdumpOptions = "--clean --format=custom --no-password";
        };

      restic.backups = lib.optionalAttrs resticSecretsPresent {
        matrix = {
          inherit (backupRepo) repository;
          initialize = true;
          passwordFile = config.age.secrets.matrix_restic_password.path;
          environmentFile = config.age.secrets.shared_restic_environment.path;
          paths = [
            "/var/lib/matrix-synapse"
            "/var/backup/postgresql/matrix-synapse.sql"
          ];
          timerConfig = {
            OnCalendar = "*-*-* 00/1:00:00";
            Persistent = true;
          };
          # The B2 key cannot hard-delete: pruned data is only hidden and the
          # bucket lifecycle rule removes it for good after its grace period.
          pruneOpts = [
            "--keep-within 2d"
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
          ];
          # Provides restic-matrix with repo, password and credentials preset.
          createWrapper = true;
        };
      };
    };

    environment.systemPackages = lib.optionals resticSecretsPresent [
      (with pkgs;
      writeScriptBin "restore-matrix-from-backup" ''
        #!${bash}/bin/bash

        # TODO: Test this script after the restic migration

        SNAPSHOT="''${1:-latest}"

        read -r -p "Are you sure you want to restore from snapshot $SNAPSHOT? This will destroy the current data. [y/N]" -n 1
        echo # (optional) move to a new line
        if [[ "$REPLY" =~ ^[^Yy]$ ]]; then
            echo "Operation aborted"
            exit 1
        fi
        set -ex

        systemctl stop matrix-synapse

        RESTORE_DIR=$(mktemp -d)
        function cleanup {
          rm -rf "$RESTORE_DIR"
        }
        trap cleanup EXIT

        echo "Fetching database dump"
        restic-matrix restore "$SNAPSHOT" --target "$RESTORE_DIR" --include /var/backup/postgresql/matrix-synapse.sql

        echo "Dropping old database"
        sudo -u postgres psql -c "DROP DATABASE \"matrix-synapse\" WITH (FORCE);" || true
        echo "Restoring database"
        sudo -u postgres psql -c 'CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse" TEMPLATE template0 LC_COLLATE = "C" LC_CTYPE = "C";'
        PGPASSWORD=synapse pg_restore -h 127.0.0.1 -U matrix-synapse -d matrix-synapse "$RESTORE_DIR/var/backup/postgresql/matrix-synapse.sql"
        echo "Database restored"

        echo "Deleting old media"
        rm -rf /var/lib/matrix-synapse
        echo "Restoring media"
        restic-matrix restore "$SNAPSHOT" --target / --include /var/lib/matrix-synapse --verbose
        echo "Restored media"

        echo Backup restored. Restarting matrix-synapse
        systemctl start matrix-synapse
      '')
    ];
  };

  imports = [
    # Create backup Repo
    {
      config = {
        meta.allBackupRepos = [{
          name = "matrix";
          machines = lib.optional (config.meta.services.matrix.host != null) config.meta.services.matrix.host;
        }];
      };
    }
  ];
}

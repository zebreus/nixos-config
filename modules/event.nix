{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.machines.${config.networking.hostName}.eventServer;
  inherit (cfg) baseDomain;
  engelDomain = "engel.${baseDomain}";
  ticketsDomain = "tickets.${baseDomain}";
  padDomain = "pad.${baseDomain}";
  email = cfg.certEmail;
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
      # matrix_backup_passphrase = {
      #   file = ../secrets/matrix_backup_passphrase.age;
      # };
      himmel_mail_password = {
        file = ../secrets/himmel_mail_password.age;
        mode = "0444";
      };
      engelsystem_database_password = {
        file = ../secrets/engelsystem_database_password.age;
        mode = "0444";
      };
      pretix_extra_secrets = {
        file = ../secrets/pretix_extra_secrets.age;
        mode = "0444";
      };
    };


    # Get certs
    security.acme = {
      acceptTerms = true;
      certs = {
        ${engelDomain}.email = email;
      };
    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };

    services.engelsystem = {
      enable = true;
      settings = {
        autoarrive = true;
        database = {
          database = "engelsystem";
          # host = "127.0.0.1";
          # password = {
          #   _secret = config.age.secrets.engelsystem_database_password.path;
          # };
          username = "engelsystem";
        };
        default_locale = "de_DE";
        email = {
          driver = "smtp";
          encryption = "tls";
          from = {
            address = "himmel@darmfest.de";
            name = "Darmfest Engelsystem";
          };
          host = "mail.zebre.us";
          password = {
            _secret = config.age.secrets.himmel_mail_password.path;
          };
          port = 465;
          username = "himmel@darmfest.de";
        };
        maintenance = false;
        min_password_length = 6;
      };
      domain = engelDomain;
    };

    services.pretix = {
      enable = true;
      gunicorn.extraArgs = [
        "--name=pretix"
        "--workers=8"
      ];
      nginx.enable = true;
      nginx.domain = ticketsDomain;
      settings = {
        pretix = {
          instance_name = ticketsDomain;
          registration = true;
          url = "https://${ticketsDomain}";
        };
        mail = {
          from = "himmel@darmfest.de";
          host = "mail.zebre.us";
          port = 465;
          tls = true;
          user = "himmel@darmfest.de";
          admins = "pretix-bugs@darmfest.de";
        };
      };
      environmentFile = config.age.secrets.pretix_extra_secrets.path;
      # plugins = with config.services.pretix.package.plugins; [
      #   pages
      # ];
    };

    services.hedgedoc = {
      enable = true;
      settings.domain = padDomain;
      settings.port = 23943;
      settings.host = "127.0.0.1"; # IP of the VM (or public IP of webserver)
      settings.protocolUseSSL = false;
      settings.allowOrigin = [
        "localhost"
        padDomain
      ];
    };

    services.nginx = {
      virtualHosts = {
        "${engelDomain}" = {
          enableACME = true;
          forceSSL = true;
        };
        "${ticketsDomain}" = {
          enableACME = true;
          forceSSL = true;
        };
        "${padDomain}" = {
          enableACME = true;
          forceSSL = true;
          root = "/var/www/hedgedoc";
          locations."/".proxyPass = "http://${config.services.hedgedoc.settings.host}:${builtins.toString config.services.hedgedoc.settings.port}";
          locations."/socket.io/" = {
            proxyPass = "http://${config.services.hedgedoc.settings.host}:${builtins.toString config.services.hedgedoc.settings.port}";
            proxyWebsockets = true;
            extraConfig =
              "proxy_ssl_server_name on;"
            ;
          };
        };
      };

    };
  };
}


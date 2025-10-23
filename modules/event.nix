{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.machines.${config.networking.hostName}.eventServer;
  inherit (cfg) baseDomain;
  engelDomain = "engel.${baseDomain}";
  ticketsDomain = "tickets.${baseDomain}";
  padDomain = "pad.${baseDomain}";
  wikiDomain = "wiki.${baseDomain}";
  email = cfg.certEmail;
  # Extra domains that redirect to the main domain
  extraDomains = [ "darmfe.st" ];
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
      mediawiki_password = {
        file = ../secrets/mediawiki_password.age;
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
          tls = false;
          ssl = true;
          user = "himmel@darmfest.de";
          admins = "pretix-bugs@darmfest.de";
        };
      };
      environmentFile = config.age.secrets.pretix_extra_secrets.path;
      plugins = with config.services.pretix.package.plugins; [
        pages
        passbook
      ];
    };

    services.mediawiki = {
      enable = true;
      # Prior to NixOS 24.05, there is a admin name bug that prevents using spaces in the mediawiki name https://github.com/NixOS/nixpkgs/issues/298902
      name = "Darmfest Wiki";
      # hostName = "${wikiDomain}";
      url = "https://${wikiDomain}";
      webserver = "nginx";
      nginx = {
        hostName = "${wikiDomain}";
      };
      database.type = "postgres";

      skins = {
        Citizen = pkgs.fetchzip {
          url = "https://github.com/StarCitizenTools/mediawiki-skins-Citizen/archive/refs/tags/v3.5.0.zip";
          sha256 = "sha256-uW22eaXJ8ZHbKHVV4msth+V1VrfoPGseez2jg8f4Vo0=";
        };
      };
      # Administrator account username is admin.
      # Set initial password to "cardbotnine" for the account admin.
      passwordFile = config.age.secrets.mediawiki_password.path;
      extraConfig = ''
        # Disable anonymous editing
        $wgGroupPermissions['*']['edit'] = true;
        $wgPasswordSender = 'himmel@darmfest.de';
        $wgEmergencyContact = 'himmel@darmfest.de';

        $wgSMTP = [
            'host'      => 'tls://mail.zebre.us', // could also be an IP address. Where the SMTP server is located. If using SSL or TLS, add the prefix "ssl://" or "tls://".
            'IDHost'    => '${wikiDomain}',      // Generally this will be the domain name of your website (aka mywiki.org)
            'localhost' => '${wikiDomain}',      // Same as IDHost above; required by some mail servers
            'port'      => 465,                // Port to use when connecting to the SMTP server
            'auth'      => true,               // Should we use SMTP authentication (true or false)
            'username'  => 'himmel@darmfest.de',     // Username to use for SMTP authentication (if being used)
            'password'  => file_get_contents('${config.age.secrets.himmel_mail_password.path}')       // Password to use for SMTP authentication (if being used)
        ];

        $wgDefaultSkin = 'citizen';
      '';

      extensions = {
        # some extensions are included and can enabled by passing null
        VisualEditor = null;

        # https://www.mediawiki.org/wiki/Extension:TemplateStyles
        # TemplateStyles = pkgs.fetchzip {
        #   url = "https://extdist.wmflabs.org/dist/extensions/TemplateStyles-REL1_40-c639c7a.tar.gz";
        #   hash = "sha256-YBL0Cs4hDSNnoutNJSJBdLsv9zFWVkzo7m5osph8QiY=";
        # };
      };
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
      settings.allowEmailRegister = true;
      settings.email = true;
      settings.allowAnonymous = true;
      settings.allowAnonymousEdits = true;
      settings.allowFreeURL = true;
    };

    services.nginx = {
      virtualHosts = lib.mkMerge ([{
        "${engelDomain}" = {
          enableACME = true;
          forceSSL = true;
          extraConfig = ''
            proxy_hide_header 'Content-Security-Policy';
            proxy_hide_header 'X-Frame-Options';
            add_header Content-Security-Policy "frame-ancestors *;" always;
            add_header X-Frame-Options "";
          '';
        };
        "${wikiDomain}" = {
          enableACME = true;
          forceSSL = true;
        };
        "${ticketsDomain}" = {
          enableACME = true;
          forceSSL = true;
          # Redirect to /darmfest-orga/darmfest2000
          locations."= /".extraConfig = ''
            return 302 $scheme://${ticketsDomain}/darmfest-orga/darmfest2000;
          '';
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
      }] ++ (
        builtins.map
          (domain: {
            "${domain}" = {
              enableACME = true;
              forceSSL = true;
              locations."/".extraConfig = ''
                return 301 $scheme://${baseDomain}$request_uri;
              '';
            };
          })
          extraDomains
      ));
    };
  };
}




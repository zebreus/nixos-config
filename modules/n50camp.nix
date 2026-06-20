{ lib, config, pkgs, n50-camp, ... }:
with lib;
let
  cfg = config.machines.${config.networking.hostName}.n50campServer;

  # The event is reachable under several base domains. Apps run inside the
  # container only on the canonical (primary) base domain; the other base domains
  # are served by the host and redirect to the primary (see the host nginx block
  # at the bottom). The subdomains below therefore always refer to the primary.
  primaryBaseDomain = cfg.primaryBaseDomain;
  secondaryBaseDomains = lib.filter (d: d != primaryBaseDomain) cfg.baseDomains;
  # Subdomain prefixes that every base domain exposes.
  subdomains = [ "engel" "cfp" "tickets" "pad" "wiki" ];

  engelDomain = "engel.${primaryBaseDomain}";
  cfpDomain = "cfp.${primaryBaseDomain}";
  ticketsDomain = "tickets.${primaryBaseDomain}";
  padDomain = "pad.${primaryBaseDomain}";
  wikiDomain = "wiki.${primaryBaseDomain}";

  # Unlike event.nix, every service here runs inside a NixOS container (see
  # matrix-lite.nix for the same pattern). The container shares the host network
  # namespace (privateNetwork = false) and exposes a single internal nginx that
  # serves all app vhosts on one localhost port. The host nginx terminates TLS
  # and reverse-proxies each domain to that port, preserving the Host header so
  # the container nginx can route by server_name.
  internalAddr = "[::1]";
  internalPort = 28080;
  internalUrl = "http://${internalAddr}:${toString internalPort}";
  hedgedocPort = 23943;
  # Port of the static n50-camp website server (from the n50-camp flake input),
  # which serves the main site on the primary base domain's apex.
  websitePort = 28011;

  # The agenix secrets are decrypted on the host and bind-mounted (read-only)
  # into the container at the very same paths, so the service config inside the
  # container can reference them transparently.
  secretPaths = {
    himmelMail = config.age.secrets.n50_himmel_mail_password.path;
    pretalxExtra = config.age.secrets.n50_pretalx_extra_secrets.path;
    mediawiki = config.age.secrets.n50_mediawiki_password.path;
  };
  mkSecretBind = path: { ${path} = { hostPath = path; isReadOnly = true; }; };

  # Reverse-proxy a host vhost to the container's internal nginx.
  proxyToContainer = {
    proxyPass = internalUrl;
    proxyWebsockets = true;
    recommendedProxySettings = true;
  };
in
{
  config = mkIf cfg.enable {
    # Define the files with the secrets. These are decrypted on the host and then
    # bind-mounted into the container below.
    age.secrets = {
      # The himmel@n50.lat mail account password (raw, no newline). Used by
      # engelsystem and mediawiki for SMTP. pretalx uses the same account but
      # gets its password via the PRETALX_MAIL_PASSWORD env file below.
      n50_himmel_mail_password = {
        file = ../secrets/n50_himmel_mail_password.age;
        mode = "0444";
      };
      # Holds pretalx's secret env vars using the PRETALX_<SECTION>_<KEY>
      # pattern, e.g. PRETALX_MAIL_PASSWORD=...  Create/edit it with
      # `agenix -e n50_pretalx_extra_secrets.age`.
      n50_pretalx_extra_secrets = {
        file = ../secrets/n50_pretalx_extra_secrets.age;
        mode = "0444";
      };
      n50_mediawiki_password = {
        file = ../secrets/n50_mediawiki_password.age;
        mode = "0444";
      };
    };

    containers.n50camp = {
      autoStart = true;
      privateNetwork = false;
      bindMounts = lib.mkMerge [
        (mkSecretBind secretPaths.himmelMail)
        (mkSecretBind secretPaths.pretalxExtra)
        (mkSecretBind secretPaths.mediawiki)
      ];
      config = { config, pkgs, lib, ... }: {
        # The n50-camp flake provides services.n50-camp (a hardened, sandboxed
        # static-web-server serving the built site) plus the overlay it needs.
        imports = [ n50-camp.nixosModules.default ];

        system.stateVersion = "26.05";

        # Main camp website, served on the primary base domain's apex. It only
        # listens on localhost; the host nginx terminates TLS and proxies to it
        # through the container's internal nginx.
        services.n50-camp = {
          enable = true;
          host = "::1";
          port = websitePort;
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
              # The engelsystem DB user authenticates over the local MariaDB unix
              # socket (services.mysql.ensureUsers), so no host/password is needed.
              username = "engelsystem";
            };
            default_locale = "de_DE";
            email = {
              driver = "smtp";
              # Port 465 is implicit TLS (SMTPS), so PHPMailer wants "ssl".
              encryption = "ssl";
              from = {
                address = "himmel@n50.lat";
                name = "N50 Camp Engelsystem";
              };
              host = "mail.stapatum.dev";
              password = {
                _secret = secretPaths.himmelMail;
              };
              port = 465;
              username = "himmel";
            };
            maintenance = false;
            min_password_length = 6;
          };
          domain = engelDomain;
        };

        # pretalx requires PostgreSQL (it sets up services.postgresql itself via
        # database.createLocally) and Redis (services.redis.servers.pretalx),
        # both of which run alongside the existing MySQL used by engelsystem. It
        # registers an nginx vhost (keyed by nginx.domain) the same way pretix
        # did, so the host reverse-proxy keeps working unchanged.
        services.pretalx = {
          enable = true;
          gunicorn.extraArgs = [
            "--name=pretalx"
            "--workers=8"
          ];
          nginx.enable = true;
          nginx.domain = cfpDomain;
          settings = {
            site.url = "https://${cfpDomain}";
            mail = {
              from = "himmel@n50.lat";
              host = "mail.stapatum.dev";
              port = 465;
              tls = false;
              ssl = true;
              user = "himmel";
            };
          };
          # The mail password (and any other secrets) come from this env file
          # using pretalx's PRETALX_<SECTION>_<KEY> pattern, e.g.
          # PRETALX_MAIL_PASSWORD=...
          environmentFiles = [ secretPaths.pretalxExtra ];
          plugins = with config.services.pretalx.package.plugins; [
            pages
          ];
        };

        services.mediawiki = {
          enable = true;
          # Prior to NixOS 24.05, there is a admin name bug that prevents using spaces in the mediawiki name https://github.com/NixOS/nixpkgs/issues/298902
          name = "N50 Camp Wiki";
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
          passwordFile = secretPaths.mediawiki;
          extraConfig = ''
            # Disable anonymous editing
            $wgGroupPermissions['*']['edit'] = true;
            $wgPasswordSender = 'himmel@n50.lat';
            $wgEmergencyContact = 'himmel@n50.lat';

            $wgSMTP = [
                'host'      => 'ssl://mail.stapatum.dev', // could also be an IP address. Where the SMTP server is located. If using SSL or TLS, add the prefix "ssl://" or "tls://".
                'IDHost'    => '${wikiDomain}',      // Generally this will be the domain name of your website (aka mywiki.org)
                'localhost' => '${wikiDomain}',      // Same as IDHost above; required by some mail servers
                'port'      => 465,                // Port to use when connecting to the SMTP server
                'auth'      => true,               // Should we use SMTP authentication (true or false)
                'username'  => 'himmel',     // Username to use for SMTP authentication (if being used)
                'password'  => file_get_contents('${secretPaths.himmelMail}')       // Password to use for SMTP authentication (if being used)
            ];

            $wgDefaultSkin = 'citizen';

            # Anti-spam captcha (ConfirmEdit is loaded via the `extensions` attr).
            wfLoadExtension('ConfirmEdit/QuestyCaptcha');
            $wgCaptchaClass = 'QuestyCaptcha';
            $wgCaptchaQuestions = [
                'Anzahl der Zelte im Logo + Breitengrad' => '55',
            ];
            $wgCaptchaTriggers['createaccount'] = true;
            $wgCaptchaTriggers['badlogin']      = true;
            $wgCaptchaTriggers['sendemail']     = true;
            $wgCaptchaTriggers['edit']          = false;
            $wgGroupPermissions['autoconfirmed']['skipcaptcha'] = true;
            $wgRateLimits['createaccount']['ip'] = [ 5, 86400 ];
            $wgRateLimits['sendemail']['ip']     = [ 5, 86400 ];
          '';

          extensions = {
            # some extensions are included and can enabled by passing null
            VisualEditor = null;
            # Official MediaWiki anti-spam captcha extension (bundled in core).
            # Configured as QuestyCaptcha in extraConfig below.
            ConfirmEdit = null;
          };
        };

        services.hedgedoc = {
          enable = true;
          settings.domain = padDomain;
          settings.port = hedgedocPort;
          settings.host = "127.0.0.1"; # localhost inside the container (shared netns)
          settings.protocolUseSSL = true; # TLS is terminated by the host nginx
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

        # The container's nginx serves all app vhosts on a single internal port.
        # The engelsystem/pretix modules register their own vhosts (keyed by
        # their domain); defaultListen makes every vhost listen on the internal
        # port without TLS, so the host can reverse-proxy by Host header.
        services.nginx = {
          enable = true;
          defaultListen = [{ addr = internalAddr; port = internalPort; }];
          virtualHosts = {
            # Main camp website on the primary base domain's apex.
            "${primaryBaseDomain}" = {
              locations."/".proxyPass = "http://[::1]:${toString websitePort}";
            };
            # hedgedoc is not served by its module, so wire up its vhost here
            # (this mirrors what event.nix did on the host).
            "${padDomain}" = {
              root = "/var/www/hedgedoc";
              locations."/".proxyPass = "http://127.0.0.1:${toString hedgedocPort}";
              locations."/socket.io/" = {
                proxyPass = "http://127.0.0.1:${toString hedgedocPort}";
                proxyWebsockets = true;
                extraConfig = "proxy_ssl_server_name on;";
              };
            };
          };
        };
      };
    };

    # Host nginx: terminate TLS for every public domain and reverse-proxy to the
    # container's internal nginx. The apps only exist on the primary base domain;
    # the same subdomains on every secondary base domain 301-redirect to the
    # primary (none of these apps can serve more than one canonical domain).
    services.nginx = {
      enable = true;
      virtualHosts = lib.mkMerge ([
        # Primary base domain: actually serve the apps.
        {
          # Apex of the primary base domain: the main camp website.
          "${primaryBaseDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = proxyToContainer;
          };
          "${engelDomain}" = {
            enableACME = true;
            forceSSL = true;
            extraConfig = ''
              proxy_hide_header 'Content-Security-Policy';
              proxy_hide_header 'X-Frame-Options';
              add_header Content-Security-Policy "frame-ancestors *;" always;
              add_header X-Frame-Options "";
            '';
            locations."/" = proxyToContainer;
          };
          "${wikiDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = proxyToContainer;
          };
          # pretalx (the call for papers) is served on the cfp subdomain.
          "${cfpDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = proxyToContainer;
          };
          # Ticketing is handled by pretix on tickets.n50.lat; keep this name
          # reachable but permanently redirect it there.
          "${ticketsDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/".extraConfig = ''
              return 301 https://tickets.n50.lat$request_uri;
            '';
          };
          "${padDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = proxyToContainer;
          };
        }
      ] ++ (
        # Secondary base domains: redirect both the apex and every subdomain to
        # the matching name on the primary base domain, preserving the path.
        lib.concatMap
          (base: builtins.map
            (name: {
              "${name}" = {
                enableACME = true;
                forceSSL = true;
                locations."/".extraConfig = ''
                  return 301 $scheme://${lib.replaceStrings [ base ] [ primaryBaseDomain ] name}$request_uri;
                '';
              };
            })
            ([ base ] ++ (builtins.map (sub: "${sub}.${base}") subdomains)))
          secondaryBaseDomains
      ));
    };
  };
}

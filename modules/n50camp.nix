{ lib, config, utils, n50-camp, ... }:
with lib;
let
  cfg = config.meta.self.n50camp;

  # The event is reachable under several base domains. Apps run inside the
  # container only on the canonical (primary) base domain; the other base domains
  # are served by the host and redirect to the primary (see the host nginx block
  # at the bottom). The subdomains below therefore always refer to the primary.
  primaryBaseDomain = cfg.primaryBaseDomain;
  secondaryBaseDomains = lib.filter (d: d != primaryBaseDomain) cfg.baseDomains;
  # Subdomain prefixes that every base domain exposes. Each one gets DNS records
  # and a secondary-base-domain -> primary redirect (see the host nginx block at
  # the bottom). pretalx/fahrplan are here so e.g. pretalx.n50.camp redirects to
  # pretalx.camp.n50.lat and fahrplan.n50.camp to fahrplan.camp.n50.lat.
  subdomains = [ "engel" "cfp" "tickets" "pad" "wiki" "pretalx" "fahrplan" ];

  engelDomain = "engel.${primaryBaseDomain}";
  # pretalx's main domain (SITE_URL): the orga backend and the canonical
  # instance live here.
  pretalxDomain = "pretalx.${primaryBaseDomain}";
  # Friendly alias for the public schedule; redirects to the event schedule on
  # pretalxDomain (no separate pretalx event/custom domain is used).
  fahrplanDomain = "fahrplan.${primaryBaseDomain}";
  # Friendly alias for the call for papers; redirects to the event CfP on
  # pretalxDomain.
  cfpDomain = "cfp.${primaryBaseDomain}";
  ticketsDomain = "tickets.${primaryBaseDomain}";
  padDomain = "pad.${primaryBaseDomain}";
  wikiDomain = "wiki.${primaryBaseDomain}";

  # Every service here runs inside a NixOS container with its OWN network
  # namespace (privateNetwork = true). Isolation is required because the host
  # runs a parallel darmfest event stack (event.nix) on the same default ports
  # (MariaDB 3306, PostgreSQL 5432, HedgeDoc 23943); a shared namespace collides
  # on all of them.
  #
  # The container's host-side veth is enslaved to a host bridge (hostBridge), so
  # nixos-containers does no imperative veth addressing — instead the bridge, its
  # /30 subnet, the container's eth0 and the outbound NAT are all plain
  # systemd-networkd config (see the `systemd.network.*` blocks). The host nginx
  # terminates TLS and reverse-proxies each domain to the container's single
  # internal nginx over the bridge, preserving the Host header so it can route by
  # server_name. Container outbound (SMTP etc.) is masqueraded by IPMasquerade on
  # the bridge.
  containerBridge = "br-n50camp";
  containerHostAddress = "192.168.207.1"; # bridge address; the container's gateway
  containerLocalAddress = "192.168.207.2"; # container's eth0 address (nginx upstream)
  # The container nginx binds all interfaces within its own netns; the host
  # reaches it at containerLocalAddress:internalPort.
  internalListenAddr = "0.0.0.0";
  internalPort = 28080;
  internalUrl = "http://${containerLocalAddress}:${toString internalPort}";
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
    pretalxAdmin = config.age.secrets.n50_pretalx_admin_password.path;
    mediawiki = config.age.secrets.n50_mediawiki_password.path;
    n50CampAdmin = config.age.secrets.n50_camp_admin_password.path;
  };
  mkSecretBind = path: { ${path} = { hostPath = path; isReadOnly = true; }; };

  # Reverse-proxy a host vhost to the container's internal nginx.
  proxyToContainer = {
    proxyPass = internalUrl;
    proxyWebsockets = true;
    recommendedProxySettings = true;
  };

  # Headers the container nginx must pass to the apps it proxies. The host nginx
  # terminates TLS and sets the real Host + X-Forwarded-* before forwarding here;
  # this inner hop must propagate them (especially X-Forwarded-Proto: it must be
  # carried through as the host set it, NOT regenerated from this hop's http
  # $scheme) so apps build correct https URLs instead of http ones.
  innerProxyHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    proxy_set_header X-Forwarded-Host $host;
  '';

  # The fastcgi apps (engelsystem, mediawiki) get the real Host via fastcgi's
  # HTTP_HOST, but HTTPS/REQUEST_SCHEME come from this inner hop's $scheme (http,
  # since the host terminates TLS). Override them from the forwarded proto so PHP
  # detects https (secure cookies, https URL generation) instead of plain http.
  # Appended after the modules' `include fastcgi_params`, so it wins.
  fastcgiForwardScheme = ''
    fastcgi_param HTTPS $forwardedHttps if_not_empty;
    fastcgi_param REQUEST_SCHEME $http_x_forwarded_proto if_not_empty;
  '';
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
      # Env file holding PRETALX_ADMIN_PASSWORD for the pretalx admin account
      # (see the pretalx-create-admin service in the container). Only read by
      # systemd (as root) via EnvironmentFile, so it stays 0400.
      n50_pretalx_admin_password = {
        file = ../secrets/n50_pretalx_admin_password.age;
        mode = "0400";
      };
      n50_mediawiki_password = {
        file = ../secrets/n50_mediawiki_password.age;
        mode = "0444";
      };
      # CMS admin password (raw, no newline) for the n50-camp site's /admin
      # area. Bind-mounted into the container and read by the service's
      # systemd credential loader.
      n50_camp_admin_password = {
        file = ../secrets/n50_camp_admin_password.age;
        mode = "0444";
      };
    };

    systemd.network.netdevs."40-br-n50camp".netdevConfig = {
      Name = containerBridge;
      Kind = "bridge";
    };
    systemd.network.networks."40-br-n50camp" = {
      matchConfig.Name = containerBridge;
      address = [ "${containerHostAddress}/30" ];
      networkConfig.IPMasquerade = "ipv4";
    };
    systemd.network.networks."45-ve-n50camp" = {
      matchConfig.Name = "ve-n50camp";
      networkConfig.Bridge = containerBridge;
    };
    systemd.services."container@n50camp" =
      let dev = "sys-subsystem-net-devices-${utils.escapeSystemdPath containerBridge}.device";
      in {
        after = [ dev ];
        wants = [ dev ];
      };

    containers.n50camp = {
      autoStart = true;
      # Own network namespace; see the addressing/NAT notes in the let block.
      privateNetwork = true;
      # Enslave the host-side veth to the bridge defined in networkd below. With
      # hostBridge set, nixos-containers does NO imperative host-side addressing;
      # both ends are configured declaratively via systemd-networkd instead.
      hostBridge = containerBridge;
      bindMounts = lib.mkMerge [
        (mkSecretBind secretPaths.himmelMail)
        (mkSecretBind secretPaths.pretalxExtra)
        (mkSecretBind secretPaths.pretalxAdmin)
        (mkSecretBind secretPaths.mediawiki)
        (mkSecretBind secretPaths.n50CampAdmin)
      ];
      config = { config, pkgs, lib, ... }: {
        # The n50-camp flake provides services.n50-camp (a hardened, sandboxed
        # static-web-server serving the built site) plus the overlay it needs.
        imports = [ n50-camp.nixosModules.default ];

        system.stateVersion = "26.05";

        networking.useNetworkd = true;
        systemd.network.networks."20-eth0" = {
          matchConfig.Name = "eth0";
          address = [ "${containerLocalAddress}/30" ];
          gateway = [ containerHostAddress ];
        };
        networking.useHostResolvConf = lib.mkForce false;
        networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
        networking.firewall.allowedTCPPorts = [ internalPort ];

        # Main camp website, served on the primary base domain's apex. It only
        # listens on localhost; the host nginx terminates TLS and proxies to it
        # through the container's internal nginx.
        services.n50-camp = {
          enable = true;
          host = "::1";
          port = websitePort;
          # The admin password comes from the agenix secret that's decrypted
          # on the host and bind-mounted into the container at the same path.
          # Without it the /admin area fails closed (404).
          adminPasswordFile = secretPaths.n50CampAdmin;
        };

        services.mysql = {
          enable = true;
          package = pkgs.mariadb;
          # engelsystem connects over the local unix socket, so there is no need
          # for a TCP listener at all (socket-only).
          settings.mysqld.skip-networking = true;
        };

        services.engelsystem = {
          enable = true;
          settings = {
            autoarrive = true;
            # Canonical external URL. engelsystem builds asset/link URLs from this
            # (config('url')); without it it falls back to the request scheme, which
            # is http here (the host terminates TLS), producing http:// asset URLs
            # that the browser blocks as mixed content on the https page.
            url = "https://${engelDomain}";
            database = {
              database = "engelsystem";
              username = "engelsystem";
              # Connect over the local MariaDB unix socket. The engelsystem DB user
              # authenticates via unix_socket auth (services.mysql.ensureUsers),
              # matching the engelsystem service user, so no password is needed.
              # This must be set explicitly: engelsystem's Illuminate bootstrap
              # defaults the DB host to "" when unset, producing an invalid DSN
              # (mysql:host=;dbname=...) and a 500 on every request.
              unix_socket = "/run/mysqld/mysqld.sock";
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
          nginx.domain = pretalxDomain;
          settings = {
            site.url = "https://${pretalxDomain}";
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

        # Idempotently create (or update) the pretalx administrator account on
        # every deploy. A small Django snippet sets is_administrator on the user,
        # creating it if missing and resetting its password from the secret, so
        # the account always matches the declared config (and the password can be
        # rotated by editing the secret). Unlike `init`, this never creates an
        # organiser and is safe to re-run, so no marker guard is needed.
        #
        # Email comes from environment; the password from the bind-mounted agenix
        # secret as an EnvironmentFile (PRETALX_ADMIN_PASSWORD=...). It MUST run
        # as the pretalx user: the `pretalx-manage` wrapper drops privileges with
        # `sudo --preserve-env=PRETALX_CONFIG_FILE`, which would strip these vars
        # if we started as root. Running as pretalx (systemd sets $USER=pretalx)
        # takes the wrapper's no-sudo path, preserving them.
        systemd.services.pretalx-create-admin = {
          description = "Create/update the pretalx administrator account";
          wantedBy = [ "multi-user.target" ];
          after = [ "pretalx-web.service" ];
          requires = [ "pretalx-web.service" ];
          environment.PRETALX_ADMIN_EMAIL = "himmel@n50.lat";
          serviceConfig = {
            Type = "oneshot";
            User = config.services.pretalx.user;
            Group = config.services.pretalx.group;
            EnvironmentFile = secretPaths.pretalxAdmin;
          };
          # `pretalx-manage` is the module's wrapper on the active system's PATH,
          # so it tracks the deployed pretalx version. `shell` executes the
          # snippet read from stdin. `--unsafe-disable-scopes` is required:
          # pretalx scopes management commands to a single event by default, but
          # this operates on a global User, so scoping must be turned off.
          script =
            let
              adminScript = pkgs.writeText "pretalx-create-admin.py" ''
                import os
                from django.contrib.auth import get_user_model

                User = get_user_model()
                email = os.environ["PRETALX_ADMIN_EMAIL"]
                password = os.environ["PRETALX_ADMIN_PASSWORD"]

                user, created = User.objects.get_or_create(
                    email=email, defaults={"name": "N50 Admin"}
                )
                user.is_administrator = True
                user.is_active = True
                user.is_staff = True
                user.set_password(password)
                user.save()
                print(("Created" if created else "Updated") + f" pretalx admin {email}")
              '';
            in
            ''
              /run/current-system/sw/bin/pretalx-manage shell --unsafe-disable-scopes < ${adminScript}
            '';
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
          # Initial admin account is "admin"; its password is the contents of the
          # n50_mediawiki_password secret. Change it after first login.
          passwordFile = secretPaths.mediawiki;
          extraConfig = ''
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
          settings.host = "127.0.0.1"; # only the container nginx talks to hedgedoc
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
          defaultListen = [{ addr = internalListenAddr; port = internalPort; }];
          # The host terminates TLS and reverse-proxies here on an internal http
          # port (28080). Without this, nginx turns relative redirects (e.g.
          # MediaWiki's "/" -> "/wiki/") into absolute ones using the internal
          # socket, leaking "http://wiki.camp.n50.lat:28080/...". Emitting relative
          # redirects lets the browser resolve them against the real https origin.
          commonHttpConfig = ''
            absolute_redirect off;
            # Derive an HTTPS on/off flag from the proto the host forwarded, for
            # the fastcgi apps below (see fastcgiForwardScheme).
            map $http_x_forwarded_proto $forwardedHttps {
              https on;
              default "";
            }
          '';
          virtualHosts = {
            # Main camp website on the primary base domain's apex.
            "${primaryBaseDomain}" = {
              locations."/" = {
                proxyPass = "http://[::1]:${toString websitePort}";
                extraConfig = innerProxyHeaders;
                recommendedProxySettings = true;
                proxyWebsockets = true;
              };
            };
            # hedgedoc is not served by its own module's nginx, so proxy it here.
            # It additionally needs WebSocket support for socket.io.
            "${padDomain}" = {
              locations."/" = {
                proxyPass = "http://127.0.0.1:${toString hedgedocPort}";
                recommendedProxySettings = true;
                proxyWebsockets = true;
                extraConfig = innerProxyHeaders;
              };
            };
            # engelsystem and mediawiki register their own fastcgi vhosts; append
            # the forwarded scheme to their php locations (keys mirror those
            # modules) so PHP sees https rather than this inner hop's http.
            "${engelDomain}".locations."~ \\.php$".extraConfig =
              lib.mkAfter fastcgiForwardScheme;
            "${wikiDomain}".locations."~ ^/w/(index|load|api|thumb|opensearch_desc|rest|img_auth)\\.php$".extraConfig =
              lib.mkAfter fastcgiForwardScheme;
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
          # Main pretalx instance: orga backend and SITE_URL. Reverse-proxied to
          # the container; pretalx serves the backend and any event without a
          # custom domain here.
          "${pretalxDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = proxyToContainer;
          };
          # Friendly alias for the public schedule: redirect to the event's
          # schedule on the main pretalx instance.
          "${fahrplanDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/".extraConfig = ''
              return 301 https://${pretalxDomain}/n50-camp-2026/schedule;
            '';
          };
          # Friendly alias for the call for papers: redirect to the event's CfP on
          # the main pretalx instance.
          "${cfpDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/".extraConfig = ''
              return 301 https://${pretalxDomain}/n50-camp-2026/cfp;
            '';
          };
          # Ticketing is handled by pretix on tickets.n50.lat; keep this name
          # reachable but permanently redirect it there.
          "${ticketsDomain}" = {
            enableACME = true;
            forceSSL = true;
            locations."/".extraConfig = ''
              return 301 https://tickets.n50.lat/n50/n50camp/;
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

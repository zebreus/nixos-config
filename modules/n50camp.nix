{ lib, config, utils, n50-camp, ... }:
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
      # Own network namespace; see the addressing/NAT notes in the let block.
      privateNetwork = true;
      # Enslave the host-side veth to the bridge defined in networkd below. With
      # hostBridge set, nixos-containers does NO imperative host-side addressing;
      # both ends are configured declaratively via systemd-networkd instead.
      hostBridge = containerBridge;
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

        # Container networking is declarative systemd-networkd: eth0 (the renamed
        # host0 veth peer) sits on the host bridge's /30, with the bridge as its
        # default gateway. Outbound is masqueraded by IPMasquerade on the bridge.
        networking.useNetworkd = true;
        systemd.network.networks."20-eth0" = {
          matchConfig.Name = "eth0";
          address = [ "${containerLocalAddress}/30" ];
          gateway = [ containerHostAddress ];
        };
        # The host's resolv.conf points at a loopback resolver unreachable from
        # the container's netns; use public resolvers instead.
        networking.useHostResolvConf = lib.mkForce false;
        networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
        # Only the host (over the bridge) talks to the internal nginx; open just it.
        networking.firewall.allowedTCPPorts = [ internalPort ];

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
          # engelsystem connects over the local unix socket, so there is no need
          # for a TCP listener at all (socket-only).
          settings.mysqld.skip-networking = true;
        };

        services.engelsystem = {
          enable = true;
          settings = {
            autoarrive = true;
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
          '';
          virtualHosts = {
            # Main camp website on the primary base domain's apex.
            "${primaryBaseDomain}" = {
              locations."/".proxyPass = "http://[::1]:${toString websitePort}";
            };
            # hedgedoc is not served by its own module's nginx, so proxy it here.
            # It needs WebSocket support for socket.io, plus the original Host and
            # the https scheme the host set (X-Forwarded-Proto must be preserved,
            # not overwritten with this inner hop's http $scheme) so hedgedoc's
            # realtime upgrade and secure cookies work exactly as a single-hop
            # setup would.
            "${padDomain}" = {
              locations."/" = {
                proxyPass = "http://127.0.0.1:${toString hedgedocPort}";
                proxyWebsockets = true;
                extraConfig = ''
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
                '';
              };
            };
          };
        };
      };
    };

    # The container's host-side veth is enslaved to this bridge (hostBridge). The
    # bridge holds the host end of the /30 and masquerades the container's
    # outbound traffic via systemd's native IPMasquerade (no networking.nat).
    systemd.network.netdevs."40-br-n50camp".netdevConfig = {
      Name = containerBridge;
      Kind = "bridge";
    };
    systemd.network.networks."40-br-n50camp" = {
      matchConfig.Name = containerBridge;
      address = [ "${containerHostAddress}/30" ];
      # Masquerades the whole 192.168.207.0/30, which contains the container.
      networkConfig.IPMasquerade = "ipv4";
    };
    # Mark the container veth as a bridge port so systemd's shipped
    # 80-container-ve.network does not give it an address. "45-" sorts before
    # "80-", so networkd picks this file for ve-n50camp.
    systemd.network.networks."45-ve-n50camp" = {
      matchConfig.Name = "ve-n50camp";
      networkConfig.Bridge = containerBridge;
    };

    # nixos-containers only orders the container after the device units of
    # `interfaces`, not `hostBridge`. nspawn's --network-bridge needs the bridge
    # to exist first, so wait for its .device unit (active once networkd has
    # created the netdev).
    systemd.services."container@n50camp" =
      let dev = "sys-subsystem-net-devices-${utils.escapeSystemdPath containerBridge}.device";
      in {
        after = [ dev ];
        wants = [ dev ];
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

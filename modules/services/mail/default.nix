{ lib, config, ... }:
let
  cfg = config.meta.self.mail;
  inherit (cfg) baseDomain;
  mailFqdn = "mail.${baseDomain}";
  certDirectory = config.security.acme.certs.${mailFqdn}.directory;

  machineDomain = machine: "${machine.name}.${config.meta.domain}";

  # The mail domains, each with the secret of its DKIM key. Every domain needs
  # one: for a domain without, SNM silently signs with a new key that isn't in
  # DNS.
  dkimKeys = lib.genAttrs [ baseDomain "madmanfred.com" config.meta.domain "darmfest.de" ]
    (domain: "${builtins.replaceStrings [ "." "-" ] [ "_" "_" ] domain}_dkim_rsa")
  // lib.listToAttrs (map (machine: lib.nameValuePair (machineDomain machine) "${machine.name}_dkim_rsa") config.meta.managedMachines);

  # The accounts, each with the secret of its password hash.
  accounts = {
    "lennart@${baseDomain}" = {
      passwordHash = "lennart_mail_passwordhash";
      aliases = [ "postmaster@${baseDomain}" "dmarc-reports@${baseDomain}" "abuse@${baseDomain}" "@${baseDomain}" "@madmanfred.com" "@${config.meta.domain}" ];
    };
    "himmel@darmfest.de" = {
      passwordHash = "himmel_mail_passwordhash";
      aliases = [ "@darmfest.de" ];
    };
  } // lib.listToAttrs (map
    (machine: lib.nameValuePair "root@${machineDomain machine}" {
      passwordHash = "${machine.name}_mail_passwordhash";
      # Allow sending and receiving from all users at the machine.
      aliases = [ "@${machineDomain machine}" ];
    })
    config.meta.managedMachines);
  passwordHashes = lib.mapAttrsToList (_: account: account.passwordHash) accounts;
in
{
  config = lib.mkIf cfg.enable {
    age.secrets = lib.genAttrs (lib.attrValues dkimKeys ++ passwordHashes) (_: { });

    # simple-nixos-mailserver in a gVisor sandbox.
    isocon.mail = {
      # 9154 is the postfix exporter's.
      tcpPorts = map (port: { inherit port; mode = "global"; ipv6 = true; }) [ 25 465 993 9154 ];
      # SMTP to other servers, DNS for kresd, also to this host's own
      # nameserver, and rspamd's maps and fuzzy hashes.
      outgoingTcpPorts = [{ port = 25; } { port = 80; } { port = 443; } { port = 53; local = true; }];
      outgoingUdpPorts = [{ port = 11335; } { port = 53; local = true; }];
      persist = [
        { path = "/var/vmail"; backup = true; }
        { path = "/var/lib/dovecot"; }
        { path = "/var/lib/postfix"; }
        { path = "/var/lib/rspamd"; }
        { path = "/var/lib/redis-rspamd"; }
      ];
      # Maildirs change by renames, so they can be backed up while running.
      duringBackup = "run";
      credentials = {
        tls_cert = "${certDirectory}/fullchain.pem";
        tls_key = "${certDirectory}/key.pem";
      } // lib.genAttrs (lib.attrValues dkimKeys ++ passwordHashes) (secret: config.age.secrets.${secret}.path);
      config = { config, pkgs, ... }: {
        mailserver = {
          enable = true;
          stateVersion = 3;
          fqdn = mailFqdn;
          domains = lib.attrNames dkimKeys;
          dkim.domains = lib.mapAttrs (_: secret: { selectors.mail.keyFile = "/run/credentials/rspamd.service/${secret}"; }) dkimKeys;

          messageSizeLimit = (2048 + 50) * 1024 * 1024; # 2 GiB + 50 MiB

          # Spamhaus and URIBL refuse queries that come through public resolvers.
          localDnsResolver = true;

          accounts = lib.mapAttrs
            (_: account: {
              inherit (account) aliases;
              hashedPasswordFile = "/run/credentials/dovecot.service/${account.passwordHash}";
            })
            accounts;

          # Default directory for mail storage
          storage.path = "/var/vmail";
          # Mail indices do not need to be backed up
          indexDir = "/var/lib/dovecot/indices";
          fullTextSearch = {
            enable = true;
            # index new email as they arrive
            autoIndex = true;
            # Indexing memory limit in MiB
            memoryLimit = 400;
          };

          # dovecot's copy; postfix reads its own, below.
          x509 = {
            certificateFile = "/run/credentials/dovecot.service/tls_cert";
            privateKeyFile = "/run/credentials/dovecot.service/tls_key";
          };
        };

        # kresd, from localDnsResolver.
        networking.nameservers = [ "127.0.0.1" ];

        systemd.services = {
          dovecot.serviceConfig.LoadCredential = [ "tls_cert" "tls_key" ] ++ passwordHashes;
          postfix.serviceConfig.LoadCredential = [ "tls_cert" "tls_key" ];
          rspamd.serviceConfig.LoadCredential = lib.attrValues dkimKeys;
          # postmap drops root for the owner of its input, a store file, which
          # the guest sees as nobody, and then can't write the map. -o keeps
          # root, as postalias already does. In ExecStart, as script would
          # refer to itself.
          postfix-setup.serviceConfig.ExecStart = lib.mkForce (pkgs.writeShellScript "postfix-setup"
            ("set -e\n" + builtins.replaceStrings [ "/bin/postmap " ] [ "/bin/postmap -o " ] config.systemd.services.postfix-setup.script));
        };

        services.postfix.settings.main = {
          smtpd_tls_chain_files = lib.mkForce [ "/run/credentials/postfix.service/tls_key" "/run/credentials/postfix.service/tls_cert" ];
          # Not the guest's other addresses. The host and its other containers
          # connect from pasta's addresses or the host's public ones, and have
          # to log in like everyone else.
          mynetworks = [ "127.0.0.0/8" "[::1]/128" ];

          smtp_host_lookup = [ "native" "dns" ];

          # Some customized error messages
          bounce_template_file = "${../../../resources/bounce.cf}";
        };

        services.rspamd.extraConfig = ''
          actions {
            reject = null; # Disable rejects, default is 15
            add_header = 13; # Add header when reaching this score
            greylist = 10; # Apply greylisting when reaching this score
          }
        '';

        services.prometheus.exporters.postfix = {
          enable = true;
          listenAddress = "[::]";
        };
      };
    };

    # pasta's ports for 25, 465 and 993, see isocon's tcpPorts.
    networking.firewall.allowedTCPPorts = [ 30025 30465 30993 ];
    monitoring.scrapePorts = [ 9154 ];

    # Obtain and renew the mail server's TLS certificate via ACME HTTP-01.
    # This nginx vhost serves the .well-known/acme-challenge. nginx, port
    # 80/443 and the ACME defaults are already configured in modules/shared.nix.
    services.nginx = {
      enable = true;
      virtualHosts.${mailFqdn} = {
        enableACME = true;
        forceSSL = true;
      };
    };
    # The container gets the certificate as a credential, which it only reads
    # when it starts.
    security.acme.certs.${mailFqdn}.reloadServices = [ "isocon-mail.service" ];
    systemd.services.isocon-mail = {
      wants = [ "acme-${mailFqdn}.service" ];
      after = [ "acme-${mailFqdn}.service" ];
    };

    services.restic.backups.isocon-mail.timerConfig.OnCalendar = "hourly";
  };

  imports = [ ./dns.nix ];
}

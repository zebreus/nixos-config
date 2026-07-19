{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.meta.self.mail;
  inherit (cfg) baseDomain;
  mailFqdn = "mail.${baseDomain}";
  domain = baseDomain;
  name = builtins.replaceStrings [ "." "-" ] [ "_" "_" ] baseDomain;

  thisMachine = config.meta.self;

  backupRepo = lib.findFirst (r: r.name == "mail")
    (throw "No backup repo mail in meta.allBackupRepos")
    config.meta.allBackupRepos;
  # The secrets only exist once terraform has been run for this repo.
  resticSecretsPresent = builtins.pathExists ../secrets/mail_restic_password.age
    && builtins.pathExists ../secrets/shared_restic_environment.age;
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      lennart_mail_passwordhash = {
        file = ../secrets/lennart_mail_passwordhash.age;
        mode = "0444";
      };
      himmel_mail_passwordhash = {
        file = ../secrets/himmel_mail_passwordhash.age;
        mode = "0444";
      };
      "${name}_dkim_rsa" = {
        file = ../secrets + "/${name}_dkim_rsa.age";
        owner = config.services.rspamd.user;
        inherit (config.services.rspamd) group;
        path = "${config.mailserver.dkim.keyDirectory}/${domain}.mail.key";
      };
      "madmanfred_com_dkim_rsa" = {
        file = ../secrets + "/madmanfred_com_dkim_rsa.age";
        owner = config.services.rspamd.user;
        inherit (config.services.rspamd) group;
        path = "${config.mailserver.dkim.keyDirectory}/madmanfred.com.mail.key";
      };
      "antibuild_ing_dkim_rsa" = {
        file = ../secrets + "/antibuild_ing_dkim_rsa.age";
        owner = config.services.rspamd.user;
        inherit (config.services.rspamd) group;
        path = "${config.mailserver.dkim.keyDirectory}/antibuild.ing.mail.key";
      };
      "darmfest_de_dkim_rsa" = {
        file = ../secrets + "/darmfest_de_dkim_rsa.age";
        owner = config.services.rspamd.user;
        inherit (config.services.rspamd) group;
        path = "${config.mailserver.dkim.keyDirectory}/darmfest.de.mail.key";
      };
    } // lib.optionalAttrs resticSecretsPresent {
      mail_restic_password.file = ../secrets/mail_restic_password.age;
      shared_restic_environment.file = ../secrets/shared_restic_environment.age;
    };

    warnings = lib.optional (!resticSecretsPresent)
      "Mail backups are disabled because the restic secrets are missing. Run `nix run .#terraform -- apply && nix run .#sync-restic-secrets` and rebuild.";

    services.postfix = {
      settings.main = {
        smtp_host_lookup = [ "native" "dns" ];

        # Some customized error messages
        bounce_template_file = "${../resources/bounce.cf}";
      };
    };

    mailserver = {
      enable = true;
      stateVersion = 3;
      fqdn = mailFqdn;
      domains = [ domain "madmanfred.com" config.meta.domain "darmfest.de" ];

      messageSizeLimit = (2048 + 50) * 1024 * 1024; # 2 GiB + 50 MiB

      # According to the simple nix mailserver doc it is a good idea to run a local DNS resolver on the mail server
      # However, I also want to run an authoritative DNS server on the mail server, so for now I will disable the local DNS resolver (kresd)
      # TODO: Enable local DNS resolver again
      localDnsResolver = false;

      accounts = {
        "lennart@${domain}" = {
          hashedPasswordFile = config.age.secrets.lennart_mail_passwordhash.path;
          aliases = [ "postmaster@${domain}" "dmarc-reports@${domain}" "abuse@${domain}" "@${domain}" "@madmanfred.com" "@${config.meta.domain}" ];
        };
        "himmel@darmfest.de" = {
          hashedPasswordFile = config.age.secrets.himmel_mail_passwordhash.path;
          aliases = [ "@darmfest.de" ];
        };
      };

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

      # TLS certificate for the mail FQDN. simple-nixos-mailserver no longer
      # provisions ACME itself (the old `certificateScheme = "acme-nginx"` is
      # gone); we obtain the cert via the NixOS ACME module (HTTP-01 through the
      # nginx vhost defined below) and reference it here by name.
      x509.useACMEHost = mailFqdn;

      # # Enable unencrypted imap on port 143
      # enableImap = true;
      # # Enable encrypted imap on port 993
      # enableImapSsl = true;
    };

    # Obtain and renew the mail server's TLS certificate via ACME HTTP-01.
    # This nginx vhost serves the .well-known/acme-challenge and registers
    # security.acme.certs."${mailFqdn}", which mailserver.x509.useACMEHost
    # above consumes. nginx, port 80/443 and the ACME defaults are already
    # configured in modules/shared.nix.
    services.nginx = {
      enable = true;
      virtualHosts.${mailFqdn} = {
        enableACME = true;
        forceSSL = true;
      };
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
      listenAddress = "[${thisMachine.antibuildingIp6}]";
    };
    monitoring.scrapePorts = [ config.services.prometheus.exporters.postfix.port ];

    services.restic.backups = lib.optionalAttrs resticSecretsPresent {
      mail = {
        inherit (backupRepo) repository;
        initialize = true;
        passwordFile = config.age.secrets.mail_restic_password.path;
        environmentFile = config.age.secrets.shared_restic_environment.path;
        paths = [
          "/var/vmail"
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
        # Provides restic-mail with repo, password and credentials preset.
        createWrapper = true;
      };
    };

    environment.systemPackages = lib.optionals resticSecretsPresent [
      (with pkgs;
      writeScriptBin "restore-mail-from-backup" ''
        #!${bash}/bin/bash

        # TODO: Test this script after the restic migration

        MODE="$1"
        if [ "$MODE" == list ] ; then
          echo "Available snapshots:"
          restic-mail snapshots
          echo "Please use '$0 restore SNAPSHOT' to restore from a specific snapshot"
          exit 0
        fi

        if [ "$MODE" != restore ] ; then
          echo "Usage: $0 COMMAND"
          echo ""
          echo "Commands:"
          echo "  list                List all available snapshots"
          echo "  restore SNAPSHOT    Restore from a specific snapshot id"
          echo "  restore             Restore from the latest snapshot"
          exit 0
        fi

        SNAPSHOT="''${2:-latest}"

        read -r -p "Are you sure you want to restore from snapshot $SNAPSHOT? This will destroy the current data. [y/N]" -n 1
        echo # (optional) move to a new line
        if [[ "$REPLY" =~ ^[^Yy]$ ]]; then
            echo "Operation aborted"
            exit 1
        fi
        set -ex

        systemctl stop dovecot2

        echo "Deleting old mail data"
        rm -rf /var/vmail
        echo "Restoring mail data"
        restic-mail restore "$SNAPSHOT" --target / --include /var/vmail --verbose
        echo "Restored mail"

        echo Backup restored. Restarting dovecot2
        systemctl start dovecot2
      '')
    ];
  };

  imports = [
    # Add backup repo
    {
      config = {
        meta.allBackupRepos = [{
          name = "mail";
          machines = lib.optional (config.meta.services.mail.host != null) config.meta.services.mail.host;
        }];
      };
    }
    # Configure the mail server to relay mail for all other machines on the VPN
    ({ lib, config, pkgs, ... }:
      let
        machines =
          builtins.map
            (machine:
              let
                inherit (machine) name;
              in
              rec {
                secrets = {
                  "${name}_mail_passwordhash" = {
                    file = ../secrets + "/${name}_mail_passwordhash.age";
                  };
                  "${name}_dkim_rsa" = {
                    file = ../secrets + "/${name}_dkim_rsa.age";
                    owner = config.services.rspamd.user;
                    inherit (config.services.rspamd) group;
                    path = "${config.mailserver.dkim.keyDirectory}/${domain}.mail.key";
                  };
                };
                domain = "${name}.${config.meta.domain}";
                loginAccount = {
                  "root@${domain}" = {
                    hashedPasswordFile = config.age.secrets."${name}_mail_passwordhash".path;
                    # Allow sending and receiving from all users at the machine.
                    aliases = [ "@${domain}" ];
                  };
                };
              })
            # All managed servers
            config.meta.managedMachines;
      in
      {
        config = mkIf cfg.enable {
          age.secrets = builtins.foldl' (acc: machine: (acc // machine.secrets)) { } machines;
          mailserver = {
            domains = builtins.map (machine: machine.domain) machines;
            accounts = builtins.foldl' (acc: machine: (acc // machine.loginAccount)) { } machines;
          };
        };
      })
  ];
}

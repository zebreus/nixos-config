{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.modules.mail;
  inherit (cfg) baseDomain;
  mailFqdn = "mail.${baseDomain}";
  inherit (cfg) certEmail;
  domain = baseDomain;
  name = builtins.replaceStrings [ "." "-" ] [ "_" "_" ] baseDomain;
in
{
  options.modules.mail = {
    enable = mkEnableOption "Enable the mail server";

    baseDomain = mkOption {
      type = types.str;
      description = ''
        Base domain for the mail server. You need to setup the DNS records according to the
        setup guide at https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html
        and https://nixos-mailserver.readthedocs.io/en/latest/autodiscovery.html. Also add
        an additional SPF record for the mail subdomain.
      '';
    };

    certEmail = mkOption {
      type = types.str;
      description = "Email address to use for Let's Encrypt certificates.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets = {
      lennart_mail_passwordhash = {
        file = ../secrets/lennart_mail_passwordhash.age;
        mode = "0444";
      };
      "mail_${name}_backup_passphrase" = {
        file = ../secrets + "/mail_${name}_backup_passphrase.age";
      };
      "mail_${name}_backup_append_only_ed25519" = {
        file = ../secrets + "/mail_${name}_backup_append_only_ed25519.age";
      };
      "${name}_dkim_rsa" = {
        file = ../secrets + "/${name}_dkim_rsa.age";
        owner = config.services.opendkim.user;
        inherit (config.services.opendkim) group;
        path = "${config.mailserver.dkimKeyDirectory}/${domain}.mail.key";
      };
      "madmanfred_com_dkim_rsa" = {
        file = ../secrets + "/madmanfred_com_dkim_rsa.age";
        owner = config.services.opendkim.user;
        inherit (config.services.opendkim) group;
        path = "${config.mailserver.dkimKeyDirectory}/madmanfred.com.mail.key";
      };
    };

    services.postfix = {
      config = {
        smtp_host_lookup = [ "native" "dns" ];

        # Some customized error messages
        bounce_template_file = "${../resources/bounce.cf}";
      };
    };

    mailserver = {
      enable = true;
      debug = true;
      fqdn = mailFqdn;
      domains = [ domain "madmanfred.com" ];

      # According to the simple nix mailserver doc it is a good idea to run a local DNS resolver on the mail server
      # However, I also want to run an authoritative DNS server on the mail server, so for now I will disable the local DNS resolver (kresd)
      # TODO: Enable local DNS resolver again
      localDnsResolver = false;

      loginAccounts = {
        "lennart@${domain}" = {
          hashedPasswordFile = config.age.secrets.lennart_mail_passwordhash.path;
          aliases = [ "postmaster@${domain}" "dmarc-reports@${domain}" "abuse@${domain}" "@${domain}" "@madmanfred.com" ];
        };
      };

      # Default directory for mail storage
      mailDirectory = "/var/vmail";
      # Mail indices do not need to be backed up
      indexDir = "/var/lib/dovecot/indices";
      fullTextSearch = {
        enable = true;
        # index new email as they arrive
        autoIndex = true;
        # this only applies to plain text attachments, binary attachments are never indexed
        indexAttachments = true;
        enforced = "body";
        # Indexing memory limit in MiB
        memoryLimit = 400;
      };

      # Use Let's Encrypt certificates. Note that this needs to set up a stripped
      # down nginx and opens port 80.
      certificateScheme = "acme-nginx";
    };
    security.acme.acceptTerms = true;
    security.acme.defaults.email = certEmail;

    services.borgbackup.jobs = builtins.listToAttrs
      (builtins.map
        (borgRepo: {
          name = "mail-${name}-to-${borgRepo.name}";
          value =
            {
              archiveBaseName = "mail_${name}";
              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.age.secrets."mail_${name}_backup_passphrase".path}";
              };
              environment.BORG_RSH = "ssh -i ${config.age.secrets."mail_${name}_backup_append_only_ed25519".path}";
              environment.BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
              extraCreateArgs = "--stats --checkpoint-interval 600";
              repo = borgRepo.url;
              startAt = "*-*-* 00/1:00:00";
              user = "root";
              paths = [
                "/var/vmail"
              ];
            };
        })
        [
          { name = "kappril"; url = "ssh://borg@kappril//storage/borg/mail_${name}"; }
        ]
      );

    environment.systemPackages = with pkgs; [
      (with pkgs;
      writeScriptBin "restore-mail-from-backup" ''
        #!${bash}/bin/bash

        # Mail restore script tested at 07.03.2024

        read -r -p "Are you sure you want to restore from the latest backup? This will destroy the current data. [y/N]" -n 1
        echo # (optional) move to a new line
        if [[ "$REPLY" =~ ^[^Yy]$ ]]; then
            echo "Operation aborted"
            exit 1
        fi
        set -ex
        
        systemctl stop dovecot2

        export BORG_RSH="ssh -i ${config.age.secrets."mail_${name}_backup_append_only_ed25519".path}"
        export BORG_PASSCOMMAND="cat ${config.age.secrets."mail_${name}_backup_passphrase".path}"
        export BORG_REPO='ssh://borg@kappril//storage/borg/mail_${name}'
        export ARCHIVE=$(borg list --last 1 | cut -d" " -f1)

        echo "Deleting old mail data"
        rm -rf /var/vmail
        echo "Restoring mail data"
        cd /
        borg extract $BORG_REPO::$ARCHIVE var/vmail --progress
        echo "Restored mail"

        echo Backup restored. Restarting dovecot2
        systemctl start dovecot2
      '')
    ];
  };

  # Configure the mail server to relay mail for all other machines on the VPN
  imports = [
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
                    owner = config.services.opendkim.user;
                    inherit (config.services.opendkim) group;
                    path = "${config.mailserver.dkimKeyDirectory}/${domain}.mail.key";
                  };
                };
                domain = "${name}.antibuild.ing";
                loginAccount = {
                  "root@${domain}" = {
                    hashedPasswordFile = config.age.secrets."${name}_mail_passwordhash".path;
                    # Allow sending and receiving from all users at the machine.
                    aliases = [ "@${domain}" ];
                  };
                };
              })
            # All managed servers
            (lib.attrValues (lib.filterAttrs (name: machine: machine.managed) config.machines));
      in
      {
        config = mkIf cfg.enable {
          age.secrets = builtins.foldl' (acc: machine: (acc // machine.secrets)) { } machines;
          mailserver = {
            domains = builtins.map (machine: machine.domain) machines;
            loginAccounts = builtins.foldl' (acc: machine: (acc // machine.loginAccount)) { } machines;
          };
        };
      })
  ];
}

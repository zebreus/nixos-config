{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.machines.${config.networking.hostName}.mailServer;
  inherit (cfg) baseDomain;
  mailFqdn = "mail.${baseDomain}";
  inherit (cfg) certEmail;
  domain = baseDomain;
  name = builtins.replaceStrings [ "." "-" ] [ "_" "_" ] baseDomain;

  thisMachine = config.machines."${config.networking.hostName}";
  machines = lib.attrValues config.machines;
  grafanaServers = lib.filter (machine: machine.monitoring.enable) machines;
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      lennart_mail_passwordhash = {
        file = ../secrets/lennart_mail_passwordhash.age;
        mode = "0444";
      };
      "mail_backup_passphrase" = {
        file = ../secrets + "/mail_backup_passphrase.age";
      };
      "mail_backup_append_only_ed25519" = {
        file = ../secrets + "/mail_backup_append_only_ed25519.age";
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
      "antibuild_ing_dkim_rsa" = {
        file = ../secrets + "/antibuild_ing_dkim_rsa.age";
        owner = config.services.opendkim.user;
        inherit (config.services.opendkim) group;
        path = "${config.mailserver.dkimKeyDirectory}/antibuild.ing.mail.key";
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
      stateVersion = 1;
      debug = true;
      fqdn = mailFqdn;
      domains = [ domain "madmanfred.com" "antibuild.ing" ];

      messageSizeLimit = (2048 + 50) * 1024 * 1024; # 2 GiB + 50 MiB

      # According to the simple nix mailserver doc it is a good idea to run a local DNS resolver on the mail server
      # However, I also want to run an authoritative DNS server on the mail server, so for now I will disable the local DNS resolver (kresd)
      # TODO: Enable local DNS resolver again
      localDnsResolver = false;

      loginAccounts = {
        "lennart@${domain}" = {
          hashedPasswordFile = config.age.secrets.lennart_mail_passwordhash.path;
          aliases = [ "postmaster@${domain}" "dmarc-reports@${domain}" "abuse@${domain}" "@${domain}" "@madmanfred.com" "@antibuild.ing" ];
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

    services.rspamd.extraConfig = ''
      actions {
        reject = null; # Disable rejects, default is 15
        add_header = 13; # Add header when reaching this score
        greylist = 10; # Apply greylisting when reaching this score
      }
    '';

    # Open firewall port 9100 for traffic from the grafana server
    networking.firewall.extraInputRules = lib.mkMerge (builtins.map
      (machine: ''
        ip6 saddr { ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}/128 } tcp dport ${builtins.toString config.services.prometheus.exporters.rspamd.port} accept
        ip6 saddr { ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}/128 } tcp dport ${builtins.toString config.services.prometheus.exporters.postfix.port} accept
      '')
      # ip6 saddr { ${config.antibuilding.ipv6Prefix}::${builtins.toString machine.address}/128 } tcp dport ${builtins.toString config.services.prometheus.exporters.mail.port} accept
      grafanaServers);
    services.prometheus = {
      exporters.rspamd = {
        enable = true;
        listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
        port = 9256;
      };
      exporters.postfix = {
        enable = true;
        listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
        port = 9257;
      };
      # exporters.mail = {
      #   enable = true;
      #   listenAddress = "[${config.antibuilding.ipv6Prefix}::${builtins.toString thisMachine.address}]";
      #   port = 9258;
      # };
    };

    services.borgbackup.jobs = builtins.listToAttrs
      (builtins.map
        (borgRepo: {
          name = "mail-to-${borgRepo.name}";
          value =
            {
              archiveBaseName = "mail";
              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.age.secrets."mail_backup_passphrase".path}";
              };
              environment.BORG_RSH = "ssh -i ${config.age.secrets."mail_backup_append_only_ed25519".path}";
              environment.BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
              extraCreateArgs = "--stats --checkpoint-interval 600";
              repo = "${borgRepo.backupHost.locationPrefix}mail";
              startAt = "*-*-* 00/1:00:00";
              user = "root";
              paths = [
                "/var/vmail"
              ];
            };
        })
        config.allBackupHosts
      );

    environment.systemPackages = with pkgs; [
      (with pkgs;
      writeScriptBin "restore-mail-from-backup" ''
        #!${bash}/bin/bash

        # Mail restore script tested at 11.11.2024
        set -ex

        export BORG_RSH="ssh -i ${config.age.secrets."mail_backup_append_only_ed25519".path}"
        export BORG_PASSCOMMAND="cat ${config.age.secrets."mail_backup_passphrase".path}"
        ALL_BORG_REPOS=( ${ lib.concatStringsSep " " (builtins.map (machine: "'${machine.backupHost.locationPrefix}mail'") config.allBackupHosts)} )

        MODE="$1"
        if [ "$MODE" == list ] ; then
          for TEST_BORG_REPO in "''${ALL_BORG_REPOS[@]}"; do
            echo "Available snapshots at $TEST_BORG_REPO"
            borg list --sort timestamp $TEST_BORG_REPO | cut -d" " -f1 | grep -Po '^mail-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$' || true
            echo ""
          done
          echo "Please use '$0 restore TIMESTAMP' to restore from a specific timestamp "
          exit 0
        fi

        if [ "$MODE" != restore ] ; then
          echo "Usage: $0 COMMAND"
          echo ""
          echo "Commands:"
          echo "  list                 List all available timestamps"
          echo "  restore TIMESTAMP    Restore from a specific timestamp"
          echo "  restore              Restore from the latest timestamp"
          exit 0
        fi

        TIMESTAMP="$2"

        read -r -p "Are you sure you want to restore from the latest backup? This will destroy the current data. [y/N]" -n 1
        echo # (optional) move to a new line
        if [[ "$REPLY" =~ ^[^Yy]$ ]]; then
            echo "Operation aborted"
            exit 1
        fi
        
        systemctl stop dovecot2

        LATEST_TIMESTAMP=mail-0
        BORG_LIST_FILTER="--last 1"
        if [ -n "$TIMESTAMP" ] ; then
          BORG_LIST_FILTER="-a $TIMESTAMP"
        fi
        for TEST_BORG_REPO in "''${ALL_BORG_REPOS[@]}"; do
          THIS_REPO_TIMESTAMP="$(borg list --sort timestamp $BORG_LIST_FILTER $TEST_BORG_REPO | cut -d" " -f1 | grep -Po '^mail-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$' | tail -1 || true)"
          if [ -z "$THIS_REPO_TIMESTAMP" ] ; then
            continue
          fi
          if  [ "$LATEST_TIMESTAMP" \> "$THIS_REPO_TIMESTAMP" ] ; then
            continue
          fi
          export LATEST_TIMESTAMP="$THIS_REPO_TIMESTAMP"
          export BORG_REPO="$TEST_BORG_REPO"
          export ARCHIVE="$THIS_REPO_TIMESTAMP"
        done

        if [ -z "$BORG_REPO" ] || [ -z "$ARCHIVE" ] ; then
          echo "No backup found"
          exit 1
        fi

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

  imports = [
    # Add backup repo
    {
      config = {
        allBorgRepos = [{ name = "mail"; size = "1T"; }];
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

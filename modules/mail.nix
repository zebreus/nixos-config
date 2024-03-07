{ lib, config, ... }:
with lib;
let
  cfg = config.modules.mailserver;
  inherit (cfg) baseDomain;
  fqdnDomain = "mail.${baseDomain}";
  certEmail = cfg.certEmail;
  domain = baseDomain;
  name = builtins.replaceStrings [ "." "-" ] [ "_" "_" ] baseDomain;
in
{
  options.modules.mailserver = {
    enable = mkEnableOption "Enable mail server";

    baseDomain = mkOption {
      type = types.str;
      description = "Base domain for the mail server. You need to setup the DNS records according to the setup guide at https://nixos-mailserver.readthedocs.io/en/latest/setup-guide.html .";
    };

    certEmail = mkOption {
      type = types.str;
      description = "Email address to use for Let's Encrypt certificates.";
    };
  };

  config = mkIf cfg.enable {
    age.secrets.lennart_mail_passwordhash = {
      file = ../secrets/lennart_mail_passwordhash.age;
      mode = "0444";
    };

    mailserver = {
      enable = true;
      fqdn = fqdnDomain;
      domains = [ domain ];

      loginAccounts = {
        "lennart@${domain}" = {
          hashedPasswordFile = config.age.secrets.lennart_mail_passwordhash.path;
          aliases = [ "postmaster@${domain}" "lennart@${domain}" ];
        };
      };

      # User and group for mail storage
      vmailUserName = "virtualMail";
      vmailGroupName = "virtualMail";
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

    age.secrets."mail_${name}_backup_passphrase" = {
      file = ../secrets + "/mail_${name}_backup_passphrase.age";
    };
    age.secrets."mail_${name}_backup_append_only_ed25519" = {
      file = ../secrets + "/mail_${name}_backup_append_only_ed25519.age";
    };

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
              extraCreateArgs = "--stats --checkpoint-interval 600";
              repo = borgRepo.url;
              startAt = "*-*-* 00/1:00:00";
              user = "root";
              paths = [
                "/var/vmail"
                "/var/dkim"
              ];
            };
        })
        [
          { name = "kappril"; url = "ssh://borg@kappril//storage/borg/mail_${name}"; }
        ]
      );
  };
}

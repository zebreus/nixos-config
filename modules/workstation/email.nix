{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    age.secrets = {
      lennart_mail_password = {
        file = ../../secrets/lennart_mail_password.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      himmel_mail_password = {
        file = ../../secrets/himmel_mail_password.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      n50_himmel_mail_password = {
        file = ../../secrets/n50_himmel_mail_password.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      n50_camp_mail_password = {
        file = ../../secrets/n50_camp_mail_password.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      gmail_password = {
        file = ../../secrets/gmail_password.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      gmail_oauth2_token = {
        file = ../../secrets/gmail_oauth2_token.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
    };

    home-manager.users = {
      lennart = homeManagerConfig:
        let
          inherit (homeManagerConfig) lib;
          hmConfig = homeManagerConfig.config;
        in
        {
          services.secret-service = {
            enable = true;
            secrets = [
              {
                label = "GOA imap_smtp credentials for identity lennart_imap_smtp";
                secretCommand = "(password=\"$(${lib.concatStringsSep " " hmConfig.accounts.email.accounts.lennart.passwordCommand})\" ; echo -n \"{'imap-password': <'$password'>, 'smtp-password': <'$password'>}\")";
                attributes = {
                  "xdg:schema" = "org.gnome.OnlineAccounts";
                  "goa-identity" = "imap_smtp:gen0:lennart_imap_smtp";
                };
              }
              {
                label = "GOA imap_smtp credentials for identity himmel_imap_smtp";
                secretCommand = "(password=\"$(${lib.concatStringsSep " " hmConfig.accounts.email.accounts.himmel.passwordCommand})\" ; echo -n \"{'imap-password': <'$password'>, 'smtp-password': <'$password'>}\")";
                attributes = {
                  "xdg:schema" = "org.gnome.OnlineAccounts";
                  "goa-identity" = "imap_smtp:gen0:himmel_imap_smtp";
                };
              }
              {
                label = "GOA imap_smtp credentials for identity host_imap_smtp";
                secretCommand = "(password=\"$(${lib.concatStringsSep " " hmConfig.accounts.email.accounts.host.passwordCommand})\" ; echo -n \"{'imap-password': <'$password'>, 'smtp-password': <'$password'>}\")";
                attributes = {
                  "xdg:schema" = "org.gnome.OnlineAccounts";
                  "goa-identity" = "imap_smtp:gen0:host_imap_smtp";
                };
              }
              {
                label = "GOA google credentials for identity gmail_google";
                secretCommand = "cat ${config.age.secrets.gmail_oauth2_token.path}";
                attributes = {
                  "xdg:schema" = "org.gnome.OnlineAccounts";
                  "goa-identity" = "google:gen11:gmail_google";
                };
              }
            ];
          };

          programs.thunderbird = {
            enable = true;
            profiles.lennart = {
              isDefault = true;
            };
          };
          accounts.email.accounts = {
            host = {
              primary = lib.mkForce false;
              thunderbird.enable = true;
              # gnome-online-accounts.enable = true;
            };
            lennart = {
              primary = true;
              address = "lennart@zebre.us";
              imap = {
                host = "mail.zebre.us";
                port = 993;
              };
              smtp = {
                host = "mail.zebre.us";
                port = 465;
              };
              realName = "Lennart Eichhorn";
              userName = "lennart@zebre.us";
              passwordCommand = "cat ${config.age.secrets.lennart_mail_password.path}";
              neomutt = {
                enable = true;
                mailboxType = "imap";
                mailboxName = "lennart";
              };
              thunderbird.enable = true;
              msmtp.enable = true;
              # gnome-online-accounts.enable = true;
            };
            himmel = {
              address = "himmel@darmfest.de";
              imap = {
                host = "mail.zebre.us";
                port = 993;
              };
              smtp = {
                host = "mail.zebre.us";
                port = 465;
              };
              realName = "Engelsystem";
              userName = "himmel@darmfest.de";
              passwordCommand = "cat ${config.age.secrets.himmel_mail_password.path}";
              neomutt = {
                enable = true;
                mailboxType = "imap";
                mailboxName = "himmel";
              };
              thunderbird.enable = true;
              msmtp.enable = true;
              # gnome-online-accounts.enable = true;
            };
            himmelN50 = {
              address = "himmel@n50.lat";
              imap = {
                host = "mail.stapatum.dev";
                port = 993;
              };
              smtp = {
                host = "mail.stapatum.dev";
                port = 465;
              };
              realName = "N50 Camp";
              # The mail server logs in with the bare local part, not the full address.
              userName = "himmel";
              passwordCommand = "cat ${config.age.secrets.n50_himmel_mail_password.path}";
              neomutt = {
                enable = true;
                mailboxType = "imap";
                mailboxName = "himmelN50";
              };
              thunderbird.enable = true;
              msmtp.enable = true;
            };
            campN50 = {
              address = "camp@n50.lat";
              imap = {
                host = "mail.stapatum.dev";
                port = 993;
              };
              smtp = {
                host = "mail.stapatum.dev";
                port = 465;
              };
              realName = "N50 Camp";
              userName = "camp";
              passwordCommand = "cat ${config.age.secrets.n50_camp_mail_password.path}";
              neomutt = {
                enable = true;
                mailboxType = "imap";
                mailboxName = "campN50";
              };
              thunderbird.enable = true;
              msmtp.enable = true;
            };
            gmail = {
              primary = false;
              # flavor = "gmail.com";
              address = "lennarteichhorn@gmail.com";
              userName = "lennarteichhorn@gmail.com";
              imap = {
                host = "imap.gmail.com";
                port = 993;
              };
              smtp = {
                host = "smtp.gmail.com";
                port = 465;
              };
              realName = "Lennart Eichhorn";
              # I need an app password, which I can get at the bottom of https://myaccount.google.com/signinoptions/two-step-verification
              passwordCommand = "cat ${config.age.secrets.gmail_password.path}";
              neomutt = {
                enable = true;
                mailboxType = "imap";
                mailboxName = "gmail";
              };
              thunderbird.enable = true;
              msmtp.enable = true;
              # gnome-online-accounts = {
              #   enable = true;
              #   provider = "google";
              # };
            };
          };
        };
    };
  };
}

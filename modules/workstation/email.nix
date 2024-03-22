{ config, ... }: {
  age.secrets.lennart_mail_password = {
    file = ../../secrets/lennart_mail_password.age;
    owner = "lennart";
    group = config.users.users.lennart.group;
    mode = "0400";
  };
  age.secrets.gmail_password = {
    file = ../../secrets/gmail_password.age;
    owner = "lennart";
    group = config.users.users.lennart.group;
    mode = "0400";
  };

  home-manager.users = {
    lennart = homeManagerConfig:
      let
        lib = homeManagerConfig.lib;
        hmConfig = homeManagerConfig.config;
      in
      {
        imports = [
          ./secret-service-passwords.nix
        ];



        services.secret-service-passwords = {
          enable = true;
          secrets = [
            {
              label = "GOA imap_smtp credentials for identity lennart_imap_smtp";
              passwordCommand = "(password=\"$(${lib.concatStringsSep " " hmConfig.accounts.email.accounts.lennart.passwordCommand})\" ; echo -n \"{'imap-password': <'$password'>, 'smtp-password': <'$password'>}\")";
              attributes = {
                "xdg:schema" = "org.gnome.OnlineAccounts";
                "goa-identity" = "imap_smtp:gen0:lennart_imap_smtp";
              };
            }
            {
              label = "GOA imap_smtp credentials for identity host_imap_smtp";
              passwordCommand = "(password=\"$(${lib.concatStringsSep " " hmConfig.accounts.email.accounts.host.passwordCommand})\" ; echo -n \"{'imap-password': <'$password'>, 'smtp-password': <'$password'>}\")";
              attributes = {
                "xdg:schema" = "org.gnome.OnlineAccounts";
                "goa-identity" = "imap_smtp:gen0:host_imap_smtp";
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
        accounts.email = {
          accounts.host = {
            primary = lib.mkForce false;
            thunderbird.enable = true;
            gnome-online-accounts.enable = true;
          };
          accounts.lennart = {
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
            thunderbird = {
              enable = true;
            };
            msmtp.enable = true;
            gnome-online-accounts.enable = true;
          };
          accounts.gmail = {
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
            thunderbird = {
              enable = true;
            };
            msmtp.enable = true;
            gnome-online-accounts = {
              enable = true;
              provider = "google";
            };
          };
        };
      };
  };
}

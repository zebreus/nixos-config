{ config, ... }: {
  age.secrets.lennart_mail_password = {
    file = ../../secrets/lennart_mail_password.age;
    owner = "lennart";
    group = config.users.users.lennart.group;
    mode = "0400";
  };

  home-manager.users = {
    lennart = { pkgs, ... }: {
      # Provides sendmail
      programs.msmtp.enable = true;
      programs.mbsync.enable = true;
      programs.thunderbird = {
        enable = true;
        profiles.lennart = {
          isDefault = true;
        };
      };
      programs.notmuch = {
        enable = true;
        hooks = {
          preNew = "mbsync --all";
        };
      };
      programs.gpg = {
        enable = true;
        mutableKeys = false;
        mutableTrust = false;
      };
      accounts.email = {
        accounts.lennart = {
          address = "lennart@zebre.us";
          # gpg = {
          #   key = "F9119EC8FCC56192B5CF53A0BF4F64254BD8C8B5";
          #   signByDefault = true;
          # };
          imap = {
            host = "mail.zebre.us";
            port = 993;
          };
          userName = "lennart@zebre.us";
          passwordCommand = "cat ${config.age.secrets.lennart_mail_password.path}";
          mbsync = {
            enable = true;
            create = "maildir";
          };
          msmtp.enable = true;
          notmuch.enable = true;
          primary = true;
          realName = "Lennart Eichhorn";
          signature = {
            text = ''
              test signature
              https://keybase.io
            '';
            showSignature = "append";
          };
          smtp = {
            host = "mail.zebre.us";
            port = 465;
          };
          thunderbird.enable = true;
        };
      };
    };
  };
}

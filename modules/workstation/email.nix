{ config, ... }: {
  age.secrets.lennart_mail_password = {
    file = ../../secrets/lennart_mail_password.age;
    owner = "lennart";
    group = config.users.users.lennart.group;
    mode = "0400";
  };

  home-manager.users = {
    lennart = { pkgs, lib, ... }: {
      accounts.email = {
        accounts.${config.networking.hostName}.primary = lib.mkForce false;
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
            extraConfig = ''
              set header_cache = "~/.cache/neomutt/headers"
              set message_cachedir = "~/.cache/neomutt/messages"
              set tmpdir = ~/.cache/neomutt/tmp
              set imap_qresync = yes
            '';
          };
        };
      };
    };
  };
}

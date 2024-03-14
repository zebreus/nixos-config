{ config, lib, ... }: {
  age.secrets."${config.networking.hostName}_mail_password" = {
    file = ../../secrets + "/${config.networking.hostName}_mail_password.age";
    mode = "0444";
  };

  # We want to send emails with our fqdn. Some programs (neomutt) read it from /etc/mailname
  environment.etc."mailname".text = lib.mkForce "${config.networking.fqdnOrHostName}";

  # Disable postfix sendmail
  services.postfix.setSendmail = lib.mkForce false;

  programs.msmtp = {
    enable = true;
    accounts = {
      default = {
        auth = true;
        tls = true;
        host = "mail.zebre.us";
        tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
        port = 465;
        tls_starttls = "off";
        user = "root@${config.networking.hostName}.antibuild.ing";
        passwordeval = "cat ${config.age.secrets."${config.networking.hostName}_mail_password".path}";
        domain = "${config.networking.hostName}.antibuild.ing";
        set_from_header = true;
        from = "%U@${config.networking.hostName}.antibuild.ing";
        dsn_notify = "delay";
      };
    };
  };

  home-manager.users = { };

  home-manager.sharedModules = [
    # Enable neomutt and set some aliases
    ({ pkgs, ... }: {
      home.shellAliases = {
        mutt = "neomutt";
        mail = "neomutt";
      };
      programs.neomutt = {
        enable = true;
        extraConfig = ''
          set header_cache = "~/.cache/neomutt/headers"
          set message_cachedir = "~/.cache/neomutt/messages"
          set tmpdir = "~/.cache/neomutt/tmp"
          set imap_qresync = yes
        '';
      };
      home.file.".cache/neomutt/headers/.keep".text = "";
      home.file.".cache/neomutt/messages/.keep".text = "";
      home.file.".cache/neomutt/tmp/.keep".text = "";
      programs.msmtp = {
        enable = true;
      };
    })

    # Enable host email account
    # The host account is used to send emails from <username>@<hostname>.antibuild.ing
    # Every user on the system can use this account to send emails
    # All received emails are available to all users of the system
    (home-manager-args:
      let
        home-manager-config = home-manager-args.config;
        current-user = home-manager-config.home.username;
      in
      {
        accounts.email = {
          accounts.host = {
            primary = true;
            address = "root@${config.networking.hostName}.antibuild.ing";
            imap = {
              host = "mail.zebre.us";
              port = 993;
            };
            smtp = {
              host = "mail.zebre.us";
              port = 465;
            };
            realName = config.users.users."${current-user}".description;
            userName = "root@${config.networking.hostName}.antibuild.ing";
            passwordCommand = "cat ${config.age.secrets."${config.networking.hostName}_mail_password".path}";
            neomutt = {
              enable = true;
              mailboxType = "imap";
              mailboxName = "host";
            };
            msmtp.enable = true;
          };
        };
      })

    # Colors for neomutt
    {
      programs.neomutt.extraConfig = ''
        # Neonwolf Color Scheme for Mutt
        # Based mostly on the colors from the badwolf lightline theme
        # Project: https://codeberg.org/h3xx/mutt-colors-neonwolf

        # custom body highlights -----------------------------------------------

        # custom index highlights ----------------------------------------------


        # for background in 16 color terminal, valid background colors include:
        # base03, bg, black, any of the non brights

        # style notes:
        # when bg=235, that's a highlighted message
        # normal bg=233

        # basic colors ---------------------------------------------------------
        color error         color196        color235                        # message line error text
        color tilde         color81         color233                        # vi-like tildes marking blank lines
        color message       color82         color235
        color markers       brightcolor232  color222                        # wrapped-line /^\+/ markers
        color attachment    brightcolor165  color235                        # attachment headers
        color search        color232        color154                        # search patterns in pager
        color status        brightcolor232  color39
        color indicator     brightcolor232  color154                        # selected email in index
        color tree          brightcolor165  color233                        # arrow in threads (`-->')

        # basic monochrome screen
        mono bold           bold
        mono underline      underline
        mono indicator      reverse
        mono error          bold
        mono header         bold                            "^(From|Subject|Date|To|Cc|Bcc):"
        mono quoted         bold

        # index ----------------------------------------------------------------

        color index         color160        color233        "~A"            # all messages
        color index         color166        color233        "~E"            # expired messages
        color index         brightcolor154  color233        "~N"            # new messages
        color index         color154        color233        "~O"            # old messages
        color index         color244        color233        "~R"            # read messages
        color index         brightcolor39   color233        "~Q"            # messages that have been replied to
        color index         brightcolor154  color233        "~U"            # unread messages
        color index         brightcolor154  color233        "~U~$"          # unread, unreferenced messages
        color index         color222        color233        "~v"            # messages part of a collapsed thread
        color index         color222        color233        "~P"            # messages from me
        #color index         color39         color233        "~p!~F"        # messages to me
        #color index         color39         color233        "~N~p!~F"      # new messages to me
        #color index         color39         color233        "~U~p!~F"      # unread messages to me
        #color index         color244        color233        "~R~p!~F"      # messages to me
        color index         brightcolor165  color233        "~F"            # flagged messages
        color index         brightcolor165  color233        "~F~p"          # flagged messages to me
        color index         brightcolor165  color233        "~N~F"          # new flagged messages
        color index         brightcolor165  color233        "~N~F~p"        # new flagged messages to me
        color index         brightcolor165  color233        "~U~F~p"        # new flagged messages to me
        color index         color232        color196        "!~N ~D"        # deleted messages
        color index         color232        color196        "~N ~D"         # deleted new messages
        color index         color244        color233        "~v~(!~N)"      # collapsed thread with no unread
        color index         color81         color233        "~v~(~N)"       # collapsed thread with some unread
        color index         color81         color233        "~N~v~(~N)"     # collapsed thread with unread parent
        # statusbg used to indicated flagged when foreground color shows other status
        # for collapsed thread
        color index         color160        color233        "~v~(~F)!~N"    # collapsed thread with flagged, no unread
        color index         color81         color233        "~v~(~F~N)"     # collapsed thread with some unread & flagged
        color index         color81         color233        "~N~v~(~F~N)"   # collapsed thread with unread parent & flagged
        color index         color81         color233        "~N~v~(~F)"     # collapsed thread with unread parent, no unread inside, but some flagged
        color index         color39         color233        "~v~(~p)"       # collapsed thread with unread parent, no unread inside, some to me directly
        color index         color81         color160        "~v~(~D)"       # thread with deleted (doesn't differentiate between all or partial)
        color index         color222        color233        "~T"            # tagged messages
        color index         brightcolor222  color233        "~T~F"          # tagged, flagged messages
        color index         brightcolor222  color233        "~T~N"          # tagged, new messages
        color index         brightcolor222  color233        "~T~U"          # tagged, unread messages

        # message headers ------------------------------------------------------

        color hdrdefault    brightcolor222  color235
        color header        brightcolor39   color235        "^(From|To|Cc|Bcc)"
        color header        brightcolor165  color235        "^(Subject|Date)"

        # body -----------------------------------------------------------------

        color quoted        color39         color235
        color quoted1       color165        color235
        color quoted2       color39         color235
        color quoted3       color222        color235
        color quoted4       color166        color235
        color signature     color81         color235                        # everything below /^--\s*$/

        color bold          color255        color233
        color underline     color233        color244
        color normal        color244        color233

        ## pgp

        color body          color160        color233        "(BAD signature)"
        color body          color39         color233        "(Good signature)"
        color body          color235        color233        "^gpg: Good signature .*"
        color body          color241        color233        "^gpg: "
        color body          color241        color160        "^gpg: BAD signature from.*"
        mono  body          bold                            "^gpg: Good signature"
        mono  body          bold                            "^gpg: BAD signature from.*"

        # yes, an insane URL regex
        color body          brightcolor39   color233        "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"
        # and a heavy handed email regex
        color body          brightcolor39   color233        "((@(([0-9a-z-]+\\.)*[0-9a-z-]+\\.?|#[0-9]+|\\[[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\]),)*@(([0-9a-z-]+\\.)*[0-9a-z-]+\\.?|#[0-9]+|\\[[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\.[0-9]?[0-9]?[0-9]\\]):)?[0-9a-z_.+%$-]+@(([0-9a-z-]+\\.)*[0-9a-z-]+\\.?|#[0-9]+|\\[[0-2]?[0-9]?[0-9]\\.[0-2]?[0-9]?[0-9]\\.[0-2]?[0-9]?[0-9]\\.[0-2]?[0-9]?[0-9]\\])"

        # simplified regex for URL & email
        #color body		magenta		default	"(ftp|https?|gopher|news|telnet|finger)://[^ \"\t\r\n]+"
        #color body		magenta		default	"[-a-z_0-9.]+@[-a-z_0-9.]+"
      '';
    }
  ];
}

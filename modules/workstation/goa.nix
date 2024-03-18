{
  services.gnome-online-accounts.enable = true;
  services.gnome-online-accounts.settings = {
    account_1656063063_0 = {
      Provider = "google";
      Identity = "lennarteichhorn@gmail.com";
      PresentationIdentity = "lennarteichhorn@gmail.com";
      MailEnabled = true;
      CalendarEnabled = true;
      ContactsEnabled = true;
      PhotosEnabled = true;
      FilesEnabled = true;
      PrintersEnabled = true;
    };

    gamma = {
      Provider = "imap_smtp";
      Identity = "lennart.eichhornsfsf@stud.h-da.de";
      PresentationIdentity = "lennart.eichhorn@stud.h-da.de";
      Enabled = true;
      EmailAddress = "lennart.eichhorn@stud.h-da.de";
      Name = "Lennart Eichhorn";
      ImapHost = "email.h-da.de";
      ImapUserName = "lennart.eichhorn@stud.h-da.de";
      ImapUseSsl = true;
      ImapUseTls = false;
      ImapAcceptSslErrors = false;
      SmtpHost = "smtp.h-da.de";
      SmtpUseAuth = true;
      SmtpUserName = "stlteich";
      SmtpAuthLogin = false;
      SmtpAuthPlain = true;
      SmtpUseSsl = false;
      SmtpUseTls = true;
      SmtpAcceptSslErrors = false;
    };
  };
}

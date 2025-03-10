# Configuration of locales and keymaps
{
  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.utf8";
  i18n.extraLocaleSettings = {
    LANG = "en_US.utf8";
    LANGUAGE = "en_US.utf8";
    LC_ADDRESS = "en_US.utf8";
    LC_COLLATE = "C.utf8";
    LC_CTYPE = "en_US.utf8";
    LC_IDENTIFICATION = "en_US.utf8";
    LC_MEASUREMENT = "de_DE.utf8";
    LC_MESSAGES = "en_US.utf8";
    LC_MONETARY = "de_DE.utf8";
    LC_NAME = "en_US.utf8";
    LC_NUMERIC = "de_DE.utf8";
    LC_PAPER = "de_DE.utf8";
    LC_TELEPHONE = "de_DE.utf8";
    LC_TIME = "de_DE.utf8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
    # options = "caps:swapescape";
  };

  # Configure console keymap
  console.keyMap = "us-acentos";
}

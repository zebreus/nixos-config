# Enable the GNOME Desktop Environment.
{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
      desktopManager.gnome.enable = true;
    };
    services.gnome = {
      tracker.enable = true;
      tracker-miners.enable = true;
    };

    home-manager.users.lennart = {
      dconf = {
        enable = true;

        settings = {
          # Set the color scheme to dark.
          "org/gnome/desktop/interface".color-scheme = "prefer-dark";
          # Set the wallpaper to the NixOS wallpaper.
          "org/gnome/desktop/background" = {
            picture-uri = "file://${pkgs.nixos-wallpaper}/share/backgrounds/gnome/thinknix-l.svg";
            picture-uri-dark = "file://${pkgs.nixos-wallpaper}/share/backgrounds/gnome/thinknix-d.svg";
            primary-color = "#c41000";
            secondary-color = "#000000";
            color-shading-type = "solid";
          };
          # Try to enable lockscreen, but dont blank the screen
          "org/gnome/settings-daemon/plugins/power".idle-dim = false;
          "org/gnome/desktop/screensaver" = {
            idle-activation-enabled = true;
            lock-delay = 35;
            lock-enabled = true;
            status-message-enabled = false;
            user-switch-enabled = false;
          };
        };
      };
    };


    environment.systemPackages = with pkgs;
      [
        gnome.gnome-tweaks
        gnome.dconf-editor
        gnomeExtensions.appindicator
        headsetcontrol
        headset-charge-indicator
        pkgs.nixos-wallpaper
      ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    # GDMs does not work well
    security.pam.services.login.showMotd = lib.mkForce false;
  };
}

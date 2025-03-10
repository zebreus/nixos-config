# Various gui programs I like to use
{ lib, config, pkgs, ... }:
# let
#   wayland-chrome = pkgs.google-chrome.override {
#     commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
#   };
# in
{
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {


    # List packages installed in system profile. To search, run:
    environment.systemPackages = with pkgs;
      [
        vscode
        spotify
        # wayland-chrome
        rivalcfg
        google-chrome
        firefox
        gnome-secrets
        inkscape
        gimp-with-plugins
        gitg
        piper
        virt-manager
        gnome-boxes
        anki
        evolution
        fractal
        libreoffice
      ];
  };
}

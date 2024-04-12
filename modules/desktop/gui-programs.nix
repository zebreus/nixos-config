# Various gui programs I like to use
{ lib, config, pkgs, ... }:
let
  wayland-chrome = pkgs.google-chrome.override {
    commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
  };
in
{
  config = lib.mkIf config.modules.desktop.enable {


    # List packages installed in system profile. To search, run:
    environment.systemPackages = with pkgs;
      [
        vscode
        slack
        spotify
        wayland-chrome
        firefox
        gnome-secrets
        inkscape
        gimp-with-plugins
        gitg
        piper
        virt-manager
        gnome.gnome-boxes
        anki
        evolution
        fractal
      ];
  };
}

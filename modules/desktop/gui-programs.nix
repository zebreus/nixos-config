# Various gui programs I like to use
{ pkgs, ... }:
let
  # unstable = import <unstable> {
  #   config = {
  #     allowUnfree = true;
  #   };
  # };
  # unstable = pkgs;
  wayland-chrome = pkgs.google-chrome.override {
    commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
  };
in
{

  # google-chrome.commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
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
      gimp
      gitg
      piper
      virt-manager
      gnome.gnome-boxes
      anki
    ];
}

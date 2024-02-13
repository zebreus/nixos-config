# Various gui programs I like to use
{ pkgs, ... }:
let
  # unstable = import <unstable> {
  #   config = {
  #     allowUnfree = true;
  #   };
  # };
  unstable = pkgs;
in
{
  # google-chrome.commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs;
    [
      vscode
      slack
      spotify
      unstable.google-chrome
      firefox
      gnome-secrets
      inkscape
      gimp
      gitg
      piper
      obs-studio
      virt-manager
      gnome.gnome-boxes
    ];
}

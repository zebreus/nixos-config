# Various gui programs I like to use
{ pkgs, ... }:
let
  wayland-chrome = pkgs.google-chrome.override {
    commandLineArgs = "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer,TouchpadOverscrollHistoryNavigation";
  };
in
{

  # # gimp with plugins needs an old python version
  # nixpkgs.config.permittedInsecurePackages = [
  #   "python-2.7.18.7-env"
  #   "python-2.7.18.7"
  # ];
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     gimp = prev.gimp.override {
  #       withPython = true;
  #     };
  #   })
  # ];

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
      # gimp-with-plugins
      gimp
      gitg
      piper
      virt-manager
      gnome.gnome-boxes
      anki
      evolution
      fractal
    ];
}

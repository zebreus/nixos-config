# Various gui programs I like to use
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {


    # List packages installed in system profile. To search, run:
    environment.systemPackages = with pkgs;
      [
        vscode
        spotify
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

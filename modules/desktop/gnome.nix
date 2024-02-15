# Enable the GNOME Desktop Environment.
{ pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.gnome.tracker.enable = true;
  services.gnome.tracker-miners.enable = true;


  environment.systemPackages = with pkgs;
    [
      gnome.gnome-tweaks
      gnome.dconf-editor
      gnomeExtensions.appindicator
      headsetcontrol
      headset-charge-indicator
    ];
}

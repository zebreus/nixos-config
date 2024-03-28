# Enable flatpak
{ lib, config, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    # Enable flatpak
    services.flatpak.enable = true;
  };
}

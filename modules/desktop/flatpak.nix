# Enable flatpak
{ lib, config, ... }: {
  config = lib.mkIf config.meta.self.desktop.enable {
    # Enable flatpak
    services.flatpak.enable = true;
  };
}

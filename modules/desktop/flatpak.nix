# Enable flatpak
{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    # Enable flatpak
    services.flatpak.enable = true;
  };
}

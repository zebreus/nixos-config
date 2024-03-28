# Enable networkmanager
{ lib, config, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    networking.networkmanager.enable = true;

    users.extraGroups.networkmanager.members = [ "lennart" ];
  };
}

# Enable networkmanager
{ lib, config, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    networking.networkmanager.enable = true;

    users.extraGroups.networkmanager.members = [ "lennart" ];
  };
}

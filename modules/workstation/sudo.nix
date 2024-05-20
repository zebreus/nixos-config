{ lib, config, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.workstation.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    users.extraGroups.wheel.members = [ "lennart" ];
  };
}

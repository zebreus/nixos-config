{ lib, config, ... }:
{
  config = lib.mkIf config.modules.workstation.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    users.extraGroups.wheel.members = [ "lennart" ];
  };
}

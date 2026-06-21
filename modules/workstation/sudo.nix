{ lib, config, ... }:
{
  config = lib.mkIf config.meta.self.workstation.enable {
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    users.extraGroups.wheel.members = [ "lennart" ];
  };
}

# Enable networkmanager
{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    networking.networkmanager.enable = true;
    # Wait online creates more problems than its worth
    systemd.services.NetworkManager-wait-online = {
      serviceConfig = {
        ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
      };
    };

    users.extraGroups.networkmanager.members = [ "lennart" ];
  };
}

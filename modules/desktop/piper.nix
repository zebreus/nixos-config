# Adds piper and enables libratbagd
{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.modules.desktop.enable {
    services.ratbagd.enable = true;
    environment.systemPackages = with pkgs;
      [
        piper
      ];

    users.extraGroups.input.members = [ "lennart" ];
  };
}

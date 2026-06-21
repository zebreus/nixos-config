# Adds piper and enables libratbagd
{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.meta.self.desktop.enable {
    services.ratbagd.enable = true;
    environment.systemPackages = with pkgs;
      [
        piper
      ];

    users.extraGroups.input.members = [ "lennart" ];
  };
}

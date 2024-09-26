# Tries to perform some maintenance tasks between 3 and 5 AM
{ config, ... }:
let
  hostname = config.networking.hostName;
  thisMachine = config.machines."${config.networking.hostName}";
in
{
  config = {
    system.autoUpgrade = {
      enable = thisMachine.auto-maintenance.upgrade;
      flake = ''github:zebreus/nixos-config#${hostname}'';
      flags = [
        "--refresh"
        "-L" # print build logs
      ];
      dates = "hourly";
      randomizedDelaySec = "5min";
      allowReboot = true;
      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
    };

    nix.gc = {
      automatic = thisMachine.auto-maintenance.cleanup;
      dates = "03:25";
      options = "--delete-older-than 30d";
    };

    nix.optimise = {
      automatic = thisMachine.auto-maintenance.cleanup;
      dates = [ "03:40" ];
    };
  };
}

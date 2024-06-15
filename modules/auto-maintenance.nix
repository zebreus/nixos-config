# Tries to perform some maintenance tasks between 3 and 5 AM
{ config, lib, ... }:
let
  hostname = config.networking.hostName;
  thisMachine = config.machines."${config.networking.hostName}";
in
{
  config = lib.mkIf thisMachine.auto-maintenance.enable {
    system.autoUpgrade = {
      enable = true;
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
      automatic = true;
      dates = "03:25";
      options = "--delete-older-than +4";
    };

    nix.optimise = {
      automatic = true;
      dates = [ "03:40" ];
    };
  };
}

# Tries to perform some maintenance tasks between 3 and 5 AM
{ config, lib, ... }:
let
  hostname = config.networking.hostName;
in
{
  options.modules.auto-maintenance = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable automatic maintenance tasks.
      '';
    };
  };

  config = lib.mkIf config.modules.auto-maintenance.enable {
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
      options = "--delete-older-than +5";
    };

    nix.optimise = {
      automatic = true;
      dates = [ "03:40" ];
    };
  };
}

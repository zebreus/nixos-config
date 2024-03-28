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
        "--update-input"
        "nixpkgs"
        "--no-write-lock-file"
        "-L" # print build logs
      ];
      dates = "03:20";
      randomizedDelaySec = "5min";
      allowReboot = true;
    };

    nix.gc = {
      automatic = true;
      dates = "04:00";
      options = "--delete-older-than +5";
    };

    nix.optimise = {
      automatic = true;
      dates = [ "04:40" ];
    };
  };
}

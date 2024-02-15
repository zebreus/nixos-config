{ config, ... }:
let
  hostname = config.networking.hostName;
in
{
  system.autoUpgrade = {
    enable = true;
    flake = ''github:zebreus/nixos-config#${hostname}'';
    flags = [
      "--impure"
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "03:40";
    randomizedDelaySec = "45min";
    allowReboot = true;
  };
}

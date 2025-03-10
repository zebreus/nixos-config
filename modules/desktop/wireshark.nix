# Enable wireshark
{ lib, config, pkgs, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    programs.wireshark.enable = true;

    environment.systemPackages = [
      pkgs.wireshark
    ];

    services.udev = {
      extraRules = ''
        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
      '';
    };
  };
}

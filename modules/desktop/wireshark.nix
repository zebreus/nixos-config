# Enable wireshark
{ lib, config, ... }:
{
  config = lib.mkIf config.machines.${config.networking.hostName}.desktop.enable {
    programs.wireshark.enable = true;

    services.udev = {
      extraRules = ''
        SUBSYSTEM=="usbmon", GROUP="wireshark", MODE="0640"
      '';
    };
  };
}

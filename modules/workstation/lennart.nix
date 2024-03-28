{ lib, config, ... }:
let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  config = lib.mkIf config.modules.workstation.enable {
    users.users.lennart = {
      isNormalUser = true;
      description = "Lennart";
      extraGroups = [ ];
      openssh.authorizedKeys.keys = [
        publicKeys.lennart
      ];
      home = "/home/lennart";
    };
  };
}

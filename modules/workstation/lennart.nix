{ lib, config, ... }:
let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  config = lib.mkIf config.modules.workstation.enable {
    age.secrets.lennart_login_passwordhash = {
      file = ../../secrets/lennart_login_passwordhash.age;
    };

    users = {
      mutableUsers = false;
      users.lennart = {
        isNormalUser = true;
        description = "Lennart";
        extraGroups = [ ];
        openssh.authorizedKeys.keys = [
          publicKeys.lennart
        ];
        home = "/home/lennart";
        hashedPasswordFile = config.age.secrets.lennart_login_passwordhash.path;
      };
    };
  };
}

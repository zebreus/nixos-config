{ config, lib, ... }:
{
  config = lib.mkIf config.modules.workstation.enable {
    # age.identityPaths = [ config.age.secrets.lennart_ed25519.path ];
    age.secrets = {
      lennart_ed25519 = {
        file = ../../secrets/lennart_ed25519.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
        path = "/home/lennart/.ssh/id_ed25519";
      };
      lennart_ed25519_pub = {
        file = ../../secrets/lennart_ed25519_pub.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0444";
        path = "/home/lennart/.ssh/id_ed25519.pub";
      };

      w17_door_ed25519 = {
        file = ../../secrets/w17_door_ed25519.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
        path = "/home/lennart/.ssh/w17_door_ed25519";
      };
      w17_door_ed25519_pub = {
        file = ../../secrets/w17_door_ed25519_pub.age;
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0444";
        path = "/home/lennart/.ssh/w17_door_ed25519.pub";
      };
    };
  };
}

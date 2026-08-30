{ config, lib, ... }:
{
  config = lib.mkIf config.meta.self.workstation.enable {
    age.secrets = {
      lennart_ed25519 = {
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
        path = "/home/lennart/.ssh/id_ed25519";
      };
      lennart_ed25519_pub = {
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0444";
        path = "/home/lennart/.ssh/id_ed25519.pub";
      };

      w17_door_ed25519 = {
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
        path = "/home/lennart/.ssh/w17_door_ed25519";
      };
      w17_door_ed25519_pub = {
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0444";
        path = "/home/lennart/.ssh/w17_door_ed25519.pub";
      };
    };
  };
}

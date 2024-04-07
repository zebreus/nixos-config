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
      mutableUsers = true;
      users.lennart = {
        isNormalUser = true;
        description = "Lennart";
        extraGroups = [ ];
        openssh.authorizedKeys.keys = [
          publicKeys.lennart
        ];
        home = "/home/lennart";
        hashedPasswordFile = config.age.secrets.lennart_login_passwordhash.path;
        createHome = true;
      };
    };

    # I have some weird permission errors in the user home directory with nixos-anywhere and agenix.
    # I am to lazy to think of a proper solution, so this should work for now.
    system.activationScripts = {
      "fix-permissions" = ''
        mkdir -p /home/lennart
        chmod 700 /home/lennart
        mkdir -p /home/lennart/.ssh /home/lennart/.cache /home/lennart/.config
        chmod 700 /home/lennart/.ssh /home/lennart/.config
        chmod 755 /home/lennart/.cache
        # Recursively chown, if they are not owned by lennart
        test "$(stat -c "%U" /home/lennart/.ssh)" == "root" && chown -R lennart:${config.users.users.lennart.group} /home/lennart/.ssh
        test "$(stat -c "%U" /home/lennart/.config)" == "root" && chown -R lennart:${config.users.users.lennart.group} /home/lennart/.config
        test "$(stat -c "%U" /home/lennart/.cache)" == "root" && chown -R lennart:${config.users.users.lennart.group} /home/lennart/.cache
      '';
    };
  };
}

{ config, ... }:
{
  age = {
    identityPaths = [ config.age.secrets.ssh_host_key_ed25519.path ];

    secrets = {
      ssh_host_key_ed25519 = {
        name = "${config.networking.hostName}_ed25519";
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/etc/ssh/ssh_host_ed25519_key";
        # Copy the key, because it is used to decrypt the other keys
        symlink = false;
      };

      ssh_host_key_ed25519_pub = {
        name = "${config.networking.hostName}_ed25519_pub";
        owner = "root";
        group = "root";
        mode = "0444";
        path = "/etc/ssh/ssh_host_ed25519_key.pub";
        symlink = false;
      };

      ssh_host_key_rsa = {
        name = "${config.networking.hostName}_rsa";
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/etc/ssh/ssh_host_rsa_key";
      };

      ssh_host_key_rsa_pub = {
        name = "${config.networking.hostName}_rsa_pub";
        owner = "root";
        group = "root";
        mode = "0444";
        path = "/etc/ssh/ssh_host_rsa_key.pub";
      };
    };
  };
}

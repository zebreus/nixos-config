let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      publicKeys.lennart
    ];
  };
}

{ lib, ... }:
let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  users.users.root = {
    description = lib.mkForce "Root";
    openssh.authorizedKeys.keys = [
      publicKeys.lennart
    ];
  };
}

{ modulesPath, lib, pkgs, ... }:
let
  publicKeys = import ../../secrets/public-keys.nix;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./networking.nix
    ../../modules/common/boot.nix
  ];

  system.stateVersion = "23.11";
  networking.hostName = "blanderdash";

  # Remove this and import ../../modules/common
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    publicKeys.lennart
  ];
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];


}

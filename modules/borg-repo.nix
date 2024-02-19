let
  publicKeys = import ../secrets/public-keys.nix;
in
{
  services.borgbackup.repos = {
    main = {
      quota = "6T";
      path = "/storage/borg/main";
      authorizedKeys = [
        publicKeys.lennart
      ];
    };
  };
}

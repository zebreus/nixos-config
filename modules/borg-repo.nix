let
  publicKeys = import ../secrets/public-keys.nix;
in
{
  services.borgbackup.repos = {
    main = {
      quota = "3T";
      path = "/storage/borg/erms/home";
      authorizedKeysAppendOnly = [
        publicKeys.lennart_borg_backup
      ];
      authorizedKeys = [
        publicKeys.lennart
      ];
    };
    matrix = {
      quota = "1T";
      path = "/storage/borg/matrix";
      authorizedKeysAppendOnly = [
        publicKeys.kashenblade
      ];
      authorizedKeys = [
        publicKeys.lennart
      ];
    };
  };
}

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
    janek = {
      quota = "2T";
      path = "/storage/borg/janek";
      authorizedKeysAppendOnly = [
        publicKeys.janek_borg_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.tick
      ];
    };
    nele = {
      quota = "2T";
      path = "/storage/borg/nele";
      authorizedKeysAppendOnly = [
        publicKeys.nele_borg_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.tick
      ];
    };
    simone = {
      quota = "2T";
      path = "/storage/borg/simone";
      authorizedKeysAppendOnly = [
        publicKeys.simone_borg_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.tick
      ];
    };
  };
}

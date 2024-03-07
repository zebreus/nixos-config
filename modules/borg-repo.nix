let
  publicKeys = import ../secrets/public-keys.nix;
in
{
  services.borgbackup.repos = {
    main = {
      quota = "3T";
      path = "/storage/borg/erms/home";
      authorizedKeysAppendOnly = [
        publicKeys.lennart_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.lennart_backup_trusted
      ];
    };
    matrix = {
      quota = "1T";
      path = "/storage/borg/matrix";
      authorizedKeysAppendOnly = [
        publicKeys.matrix_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.matrix_backup_trusted
      ];
    };
    mail_zebre_us = {
      quota = "1T";
      path = "/storage/borg/mail_zebre_us";
      authorizedKeysAppendOnly = [
        publicKeys.mail_zebre_us_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.mail_zebre_us_backup_trusted
      ];
    };
    janek = {
      quota = "2T";
      path = "/storage/borg/janek";
      authorizedKeysAppendOnly = [
        publicKeys.janek_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.janek_backup_trusted
      ];
    };
    janek-proxmox = {
      quota = "2T";
      path = "/storage/borg/janek-proxmox";
      authorizedKeysAppendOnly = [
        publicKeys.janek-proxmox_backup_append_only
      ];
      authorizedKeys = [
        publicKeys.janek-proxmox_backup_trusted
      ];
    };
  };
}

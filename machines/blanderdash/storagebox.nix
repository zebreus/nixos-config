{ pkgs, config, ... }: {
  age.secrets.blanderdash_storagebox_smb_secrets = {
    file = ../../secrets/blanderdash_storagebox_smb_secrets.age;
  };

  # Mount storage box as smb share
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/storage/storagebox" = {
    device = "//u425538.your-storagebox.de/backup";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in
      [ "${automount_opts},seal,uid=borg,gid=borg,credentials=${config.age.secrets.blanderdash_storagebox_smb_secrets.path}" ];
  };
}

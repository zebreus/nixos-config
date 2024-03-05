{ config, ... }:
let
  common-excludes = [
    # Largest cache dirs
    ".cache"
    "*/cache2" # firefox
    "*/Cache"
    ".config/Slack/logs"
    ".config/Code/CachedData"
    ".container-diff"
    ".npm/_cacache"
    # Work related dirs
    "*/node_modules"
    "*/bower_components"
    "*/_build"
    "*/.tox"
    "*/venv"
    "*/.venv"
    ".local/share/Steam/steamapps"
    ".local/share/containers"
    ".config/Code/Service Worker/CacheStorage"
    ".ssh"
    ".npm"
    ".conda"
  ];
in
{
  age.secrets.erms_backup_home_passphrase = {
    file = ../../secrets + "/${config.networking.hostName}_backup_home_passphrase.age";
    owner = "lennart";
    group = config.users.users.lennart.group;
    mode = "0400";
  };

  services.borgbackup.jobs = builtins.listToAttrs
    (builtins.map
      (borgRepo: {
        name = "home-to-${borgRepo.name}";
        value = rec {
          encryption = {
            mode = "repokey";
            passCommand = "cat ${config.age.secrets.erms_backup_home_passphrase.path}";
          };
          environment.BORG_RSH = "ssh -i ${config.age.secrets.lennart_borg_backup_append_only_ed25519.path}";
          extraCreateArgs = "--stats --checkpoint-interval 600";
          repo = borgRepo.url;
          startAt = "*-*-* 01:00:00";
          user = "lennart";
          paths = "/home/lennart";
          exclude = map (x: paths + "/" + x) (common-excludes);
        };
      })
      [
        { name = "kappril"; url = "ssh://borg@kappril//storage/borg/${config.networking.hostName}/home"; }
        { name = "janek-backup"; url = "ssh://borg@janek-backup//backups/lennart/main"; }
      ]
    );
}

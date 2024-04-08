{ config, lib, ... }:
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
  imports = [
    ../helpers/borgMeteredConnectionOption.nix
  ];

  config = lib.mkIf config.modules.workstation.enable {

    age.secrets = {
      "lennart_${config.networking.hostName}_backup_passphrase" = {
        file = ../../secrets + "/lennart_${config.networking.hostName}_backup_passphrase.age";
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
      };
      "lennart_${config.networking.hostName}_backup_append_only_ed25519" = {
        file = ../../secrets + "/lennart_${config.networking.hostName}_backup_append_only_ed25519.age";
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0400";
        path = "/home/lennart/.ssh/lennart_${config.networking.hostName}_backup_append_only_ed25519";
      };
      "lennart_${config.networking.hostName}_backup_append_only_ed25519_pub" = {
        file = ../../secrets + "/lennart_${config.networking.hostName}_backup_append_only_ed25519_pub.age";
        owner = "lennart";
        inherit (config.users.users.lennart) group;
        mode = "0444";
        path = "/home/lennart/.ssh/lennart_${config.networking.hostName}_backup_append_only_ed25519.pub";
      };
    };

    services.borgbackup.jobs = builtins.listToAttrs
      (lib.imap0
        (index: borgRepo: {
          name = "home-to-${borgRepo.name}";
          value = rec {
            encryption = {
              mode = "repokey";
              passCommand = "cat ${config.age.secrets."lennart_${config.networking.hostName}_backup_passphrase".path}";
            };
            environment.BORG_RSH = "ssh -i ${config.age.secrets."lennart_${config.networking.hostName}_backup_append_only_ed25519".path}";
            environment.BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
            extraCreateArgs = "--stats --checkpoint-interval 600";
            repo = borgRepo.url;
            startAt = "*-*-* 0${builtins.toString index}/3:00:00";
            persistentTimer = true;
            # user = "lennart";
            # group = config.users.users.lennart.group;
            paths = "/home/lennart";
            exclude = map (x: paths + "/" + x) common-excludes;
            dontStartOnMeteredConnection = true;
          };
        })
        [
          { name = "kappril"; url = "ssh://borg@kappril//storage/borg/${config.networking.hostName}/home"; }
          { name = "janek-backup"; url = "ssh://borg@janek-backup//backups/lennart/${config.networking.hostName}/home"; }
        ]
      );
  };
}

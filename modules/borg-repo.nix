{ lib, config, ... }:
let
  cfg = config.machines.${config.networking.hostName}.backupHost;

  publicKeys = import ../secrets/public-keys.nix;

  borgRepos = config.allBorgRepos;

in
{
  config = lib.mkIf cfg.enable {
    services.borgbackup.repos =
      (builtins.listToAttrs (builtins.map
        (repo: lib.nameValuePair repo.name {
          quota = repo.size;
          path = "/storage/borg/${repo.name}";
          authorizedKeysAppendOnly = [
            publicKeys."${repo.name}_backup_append_only"
          ];
          authorizedKeys = [
            publicKeys."${repo.name}_backup_trusted"
          ];
        })
        borgRepos));
  };
}

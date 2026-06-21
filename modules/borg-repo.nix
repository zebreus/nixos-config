{ lib, config, ... }:
let
  cfg = config.meta.self.backup;
  thisMachine = config.meta.self;

  publicKeys = import ../secrets/public-keys.nix;

  borgRepos = config.meta.allBorgRepos;

in
{
  config = lib.mkIf cfg.enable {
    services.borgbackup.repos =
      (builtins.listToAttrs (builtins.map
        (repo: lib.nameValuePair repo.name {
          quota = repo.size;
          path = "${thisMachine.backup.storagePath}/${repo.name}";
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

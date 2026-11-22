# Backs up each isocon container that has something to back up (see
# isocon.<name>.backup) into a restic repo of the container's name, and adds
# restore-<name>-from-backup.
{ config, lib, pkgs, ... }:
let
  containers = lib.filterAttrs (_: container: container.backup != null) config.isocon;
  password = name: "${name}_restic_password";
in
{
  meta.allBackupRepos = lib.mapAttrsToList (name: _: { inherit name; machines = [ config.networking.hostName ]; }) containers;

  assertions = lib.mapAttrsToList
    (name: _: {
      assertion = builtins.pathExists ../../../secrets/${password name}.age && builtins.pathExists ../../../secrets/shared_restic_environment.age;
      message = "isocon.${name} has backups, but its restic secrets are missing. Run `nix run .#terraform -- apply && nix run .#sync-restic-secrets`.";
    })
    containers;

  age.secrets = lib.mkIf (containers != { }) ({ shared_restic_environment = { }; } // lib.mapAttrs' (name: _: lib.nameValuePair (password name) { }) containers);

  services.restic.backups = lib.concatMapAttrs
    (name: container:
      let
        repo = {
          inherit (lib.findFirst (repo: repo.name == name) null config.meta.allBackupRepos) repository;
          passwordFile = config.age.secrets.${password name}.path;
          environmentFile = config.age.secrets.shared_restic_environment.path;
        };
      in
      {
        "isocon-${name}" = repo // container.backup // { initialize = true; };
        # In a job of its own, so that the container isn't stopped or paused
        # meanwhile.
        "isocon-${name}-prune" = repo // {
          # The B2 key cannot hard-delete: pruned data is only hidden and the
          # bucket lifecycle rule removes it for good after its grace period.
          # The repo holds one container, so all of its snapshots count, also
          # those from before a change of its paths.
          pruneOpts = [
            "--keep-within 2d"
            "--keep-daily 14"
            "--keep-weekly 8"
            "--keep-monthly 12"
            "--group-by ''"
          ];
          timerConfig.OnCalendar = "04:30";
        };
      })
    containers;

  # Bounds how long a backup keeps its container stopped or paused.
  systemd.services = lib.mapAttrs'
    (name: _: lib.nameValuePair "restic-backups-isocon-${name}" { serviceConfig.TimeoutStartSec = "30min"; })
    (lib.filterAttrs (_: container: container.duringBackup != "run") containers);

  environment.systemPackages = lib.mapAttrsToList
    (name: container:
      # --delete only removes what the snapshot doesn't have below the paths,
      # so nothing for a snapshot without them. The owners are the
      # container's IDs on the host, as restic restores them numerically.
      let restore = "restic-isocon-${name} restore \"$SNAPSHOT\" --target / --delete ${lib.concatMapStringsSep " " (path: "--include ${path}") container.backup.paths}";
      in pkgs.writeShellScriptBin "restore-${name}-from-backup" ''
        set -e
        SNAPSHOT="''${1:-latest}"
        ${restore} --dry-run
        read -r -p "Replace the backed up files of isocon.${name} with snapshot $SNAPSHOT, as above? List the snapshots with restic-isocon-${name} snapshots. [y/N] " -n 1
        echo
        [[ "$REPLY" == [Yy] ]] || { echo "Aborted"; exit 1; }
        set -x
        systemctl stop isocon-${name}.service
        ${restore}
        systemctl start isocon-${name}.service
      '')
    containers;
}

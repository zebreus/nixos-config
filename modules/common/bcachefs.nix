{ pkgs, ... }:
{
  # mount.bcachefs (1.39) draws recovery progress on /dev/console and holds an exclusive flock on it
  # for the whole mount. systemd takes that lock before handing any unit the console, so when a slow
  # fsck times out (the mount itself is unkillable) the emergency shell hangs until the fsck finishes.
  boot.bcachefs.package = pkgs.bcachefs-tools.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./bcachefs-release-console-lock.patch ];
  });
}

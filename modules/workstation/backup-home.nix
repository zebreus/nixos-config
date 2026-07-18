{ config, lib, ... }:
let
  # Excludes anchored to the home directory.
  home-excludes = [
    # Largest cache dirs
    ".cache"
    ".config/Slack/logs"
    ".config/Code/CachedData"
    ".config/Code/Service Worker/CacheStorage"
    ".container-diff"
    ".npm"
    ".conda"
    ".rustup"
    ".cargo/registry"
    ".platformio"
    ".arduino15"
    "oldcache"
    # Re-downloadable data
    ".config/google-chrome/OptGuideOnDeviceModel"
    ".local/share/kicad/*/3rdparty"
    ".local/share/Steam/steamapps"
    ".local/share/containers"
    ".local/share/Trash"
    "Downloads/*.iso"
    ".ssh"
  ];
  # Excludes matched by name at any depth. Restic's `*` does not cross `/`
  # (unlike borg's), so nested cache dirs need bare-name patterns.
  anywhere-excludes = [
    "cache2" # firefox
    "Cache"
    "node_modules"
    "bower_components"
    "_build"
    ".tox"
    "venv"
    ".venv"
  ];

  repoName = "lennart_${config.networking.hostName}";
  repo = lib.findFirst (r: r.name == repoName)
    (throw "No backup repo ${repoName} in meta.allBackupRepos")
    config.meta.allBackupRepos;

  passwordSecret = "${repoName}_restic_password";
  environmentSecret = "shared_restic_environment";
  # The secrets only exist once terraform has been run for this repo.
  # Until then the backup job is disabled (with a warning) so that new
  # workstations still evaluate.
  secretsPresent = builtins.pathExists (../../secrets + "/${passwordSecret}.age")
    && builtins.pathExists ../../secrets/shared_restic_environment.age;
in
{
  imports = [
    ../helpers/resticMeteredConnectionOption.nix
  ];

  config = lib.mkIf config.meta.self.workstation.enable {
    warnings = lib.optional (!secretsPresent)
      "Home backups on ${config.networking.hostName} are disabled because the restic secrets are missing. Run `nix run .#terraform -- apply && nix run .#sync-restic-secrets` and rebuild.";

    age.secrets = lib.optionalAttrs secretsPresent {
      ${passwordSecret}.file = ../../secrets + "/${passwordSecret}.age";
      ${environmentSecret}.file = ../../secrets + "/${environmentSecret}.age";
    };

    services.restic.backups = lib.optionalAttrs secretsPresent {
      home = {
        inherit (repo) repository;
        initialize = true;
        passwordFile = config.age.secrets.${passwordSecret}.path;
        environmentFile = config.age.secrets.${environmentSecret}.path;
        paths = [ "/home/lennart" ];
        exclude = map (x: "/home/lennart/" + x) home-excludes ++ anywhere-excludes;
        # Also skip everything marked with CACHEDIR.TAG (cargo target dirs etc).
        extraBackupArgs = [ "--exclude-caches" ];
        timerConfig = {
          OnCalendar = "*-*-* 00/3:00:00";
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
        # The B2 key cannot hard-delete: pruned data is only hidden and the
        # bucket lifecycle rule removes it for good after its grace period.
        pruneOpts = [
          "--keep-within 3d"
          "--keep-daily 14"
          "--keep-weekly 8"
          "--keep-monthly 12"
        ];
        # Provides restic-home with repo, password and credentials preset.
        createWrapper = true;
        dontStartOnMeteredConnection = true;
      };
    };
  };
}

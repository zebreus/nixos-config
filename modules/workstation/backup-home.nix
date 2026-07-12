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
        exclude = map (x: "/home/lennart/" + x) common-excludes;
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

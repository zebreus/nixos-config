# Restic-to-B2 backups. Config-only (no backup hosts anymore): the fleet-wide
# S3 endpoint and the single shared bucket. Each entry in meta.allBackupRepos is
# a prefix in that bucket; all machines share one append-only application key
# (isolation between repos comes from the per-repo restic passwords).
{ config, lib, ... }:
with lib;
let
  backupRepoOpts = self: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the backup repository.

          Every repository needs a B2 bucket with an append-only application key
          and a restic password. Run `nix run .#terraform -- apply` to create
          the bucket and the key, then `nix run .#sync-restic-secrets`
          to store them (and a fresh restic password) with geheimnix.
        '';
      };
      machines = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Machines (geheimnix key names) that need to decrypt this repo's restic
          secrets, besides recovery and lennart. Used by sync-restic-secrets
          to write the secrets.nix rules.
        '';
      };
      repository = mkOption {
        type = types.str;
        readOnly = true;
        default = "s3:https://${config.meta.services.backup.endpoint}/${config.meta.services.backup.bucket}/${self.config.name}";
        defaultText = literalExpression ''"s3:https://''${meta.services.backup.endpoint}/''${meta.services.backup.bucket}/''${name}"'';
        description = "The restic repository URL for this repo: a prefix in the shared backup bucket.";
      };
    };
  };
in
{
  imports = [
    (import ../../helpers/meta-service.nix "backup" {
      cardinality = "none";
      config = {
        endpoint = mkOption {
          type = types.str;
          example = "s3.eu-central-003.backblazeb2.com";
          description = "S3 endpoint of the Backblaze B2 region the backup bucket lives in.";
        };
        bucket = mkOption {
          type = types.str;
          example = "zebreus-backup";
          description = "Name of the single B2 bucket holding all restic repos (as prefixes). Must match the bucket name in terraform/main.tf.";
        };
      };
    })
  ];

  options.meta.allBackupRepos = mkOption {
    type = types.listOf (types.submodule backupRepoOpts);
    description = ''
      All restic backup repositories: one home repo per workstation, plus
      the ones service modules (mail, matrix, …) add.
    '';
    default = [ ];
  };

  # A home repo for every workstation. Service modules merge in their own repos.
  config.meta.allBackupRepos =
    builtins.concatMap
      (m: optional m.workstation.enable { name = "lennart_${m.name}"; machines = [ m.name ]; })
      (attrValues config.meta.machines);
}

{ pkgs }:
# Runs tofu in terraform/ with the credentials from
# secrets/terraform_environment.age (B2 provisioner key, INWX login, HCLOUD
# token, state passphrase) decrypted into the environment. Nothing else — the restic
# secrets are managed by sync-restic-secrets.
with pkgs; writeScriptBin "terraform" ''
  #!${bash}/bin/bash
  set -e

  AGENIX=${pkgs.agenix}/bin/agenix

  if [ ! -f flake.nix ] || [ ! -d terraform ]; then
    echo "Run this from the root of the nixos-config repository"
    exit 1
  fi

  if [ -z "''${B2_APPLICATION_KEY_ID:-}" ] || [ -z "''${TF_VAR_state_passphrase:-}" ]; then
    if [ ! -f secrets/terraform_environment.age ]; then
      echo "Missing secrets/terraform_environment.age (the B2 terraform key)."
      echo "Bootstrap it once with the master key:"
      echo "  B2_APPLICATION_KEY_ID=<masterKeyId> B2_APPLICATION_KEY=<masterKey> \\"
      echo "    b2 key create terraform listBuckets,readBuckets,writeBuckets,deleteBuckets,readBucketLifecycleRules,writeBucketLifecycleRules,readBucketRetentions,writeBucketRetentions,readBucketEncryption,writeBucketEncryption,listKeys,writeKeys,deleteKeys"
      echo "and store the result with:"
      echo "  printf 'B2_APPLICATION_KEY_ID=%s\nB2_APPLICATION_KEY=%s\n' '<keyId>' '<key>' | (cd secrets && $AGENIX -e terraform_environment.age)"
      exit 1
    fi
    # Assignment first: unlike a bare eval-of-substitution, a failing
    # decryption aborts the script here (set -e).
    TF_ENV="$(cd secrets && $AGENIX -d terraform_environment.age)"
    set -a
    eval "$TF_ENV"
    set +a
  fi

  if [ -z "''${TF_VAR_state_passphrase:-}" ]; then
    echo "TF_VAR_state_passphrase is missing from secrets/terraform_environment.age."
    echo "Add a 'TF_VAR_state_passphrase=<state passphrase>' line with:"
    echo "  (cd secrets && $AGENIX -e terraform_environment.age)"
    exit 1
  fi

  exec ${lib.getExe opentofu} -chdir=terraform "$@"
''

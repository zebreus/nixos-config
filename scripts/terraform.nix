{ pkgs }:
# Runs tofu in terraform/ with the B2 provisioner key and the state
# passphrase decrypted into the environment. Nothing else — the restic
# secrets are managed by sync-restic-secrets.
with pkgs; writeScriptBin "terraform" ''
  #!${bash}/bin/bash
  set -e

  AGENIX=${pkgs.agenix}/bin/agenix

  if [ ! -f flake.nix ] || [ ! -d terraform ]; then
    echo "Run this from the root of the nixos-config repository"
    exit 1
  fi

  if [ -z "''${B2_APPLICATION_KEY_ID:-}" ]; then
    if [ ! -f secrets/terraform_environment.age ]; then
      echo "Missing secrets/terraform_environment.age (the B2 provisioner key)."
      echo "Bootstrap it once with the master key:"
      echo "  B2_APPLICATION_KEY_ID=<masterKeyId> B2_APPLICATION_KEY=<masterKey> \\"
      echo "    b2 key create terraform-provisioner listBuckets,readBuckets,writeBuckets,listFiles,readFiles,writeFiles,listKeys,writeKeys,deleteKeys"
      echo "and store the result with:"
      echo "  printf 'B2_APPLICATION_KEY_ID=%s\nB2_APPLICATION_KEY=%s\n' '<keyId>' '<key>' | (cd secrets && $AGENIX -e terraform_environment.age)"
      exit 1
    fi
    # Assignment first: unlike a bare eval-of-substitution, a failing
    # decryption aborts the script here (set -e).
    B2_ENV="$(cd secrets && $AGENIX -d terraform_environment.age)"
    set -a
    eval "$B2_ENV"
    set +a
  fi

  if [ -z "''${TF_VAR_state_passphrase:-}" ]; then
    TF_VAR_state_passphrase="$(cd secrets && $AGENIX -d terraform_state_passphrase.age)"
    export TF_VAR_state_passphrase
  fi

  exec ${lib.getExe opentofu} -chdir=terraform "$@"
''

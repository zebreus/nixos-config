{ pkgs }:
# Stores the provisioned restic secrets with agenix: the shared append-only
# B2 key (from the tofu output, via terraform) and a fresh restic password
# for every repo in meta.allBackupRepos that does not have one yet.
with pkgs;
let
  terraform = pkgs.callPackage ./terraform.nix { };
in
writeScriptBin "sync-restic-secrets" ''
  #!${bash}/bin/bash
  set -e

  AGENIX=${pkgs.agenix}/bin/agenix
  JQ=${lib.getExe jq}

  if [ ! -f flake.nix ] || [ ! -d terraform ]; then
    echo "Run this from the root of the nixos-config repository"
    exit 1
  fi

  KEY_JSON=$(${terraform}/bin/terraform output -json application_key)
  KEY_ID=$($JQ -r '.key_id // empty' <<<"$KEY_JSON")
  KEY_SECRET=$($JQ -r '.key // empty' <<<"$KEY_JSON")
  if [ -z "$KEY_ID" ] || [ -z "$KEY_SECRET" ]; then
    echo "No application key in the tofu output. Run 'terraform apply' first."
    exit 1
  fi

  echo "Reading the repo list from meta.allBackupRepos"
  REPOS_JSON=$(nix eval --json .#nixosConfigurations \
    --apply 'cs: map (r: { inherit (r) name machines; }) (builtins.head (builtins.attrValues cs)).config.meta.allBackupRepos')

  cd secrets

  if [ ! -f shared_restic_environment.age ]; then
    echo "Storing the append-only B2 application key"
    printf 'AWS_ACCESS_KEY_ID=%s\nAWS_SECRET_ACCESS_KEY=%s\n' "$KEY_ID" "$KEY_SECRET" | $AGENIX -e shared_restic_environment.age
  fi

  for NAME in $($JQ -r '.[].name' <<<"$REPOS_JSON"); do
    PASSWORD_FILE="$NAME"_restic_password.age
    if [ -f "$PASSWORD_FILE" ]; then
      echo "Restic password for $NAME already exists, skipping"
      continue
    fi
    DECRYPTORS=$($JQ -r --arg name "$NAME" '.[] | select(.name == $name) | .machines + ["lennart"] | join(" ")' <<<"$REPOS_JSON")
    if ! grep -F "\"$PASSWORD_FILE\"" secrets.nix >/dev/null; then
      ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSWORD_FILE'".publicKeys = [ recovery '"$DECRYPTORS"' ];) . qq(\n) . $_ if /'MARKER_RESTIC_SECRETS'/' secrets.nix
    fi
    echo "Generating a restic password for $NAME"
    tr -dc A-Za-z0-9 </dev/urandom | head -c 64 | $AGENIX -e "$PASSWORD_FILE"
  done

  echo "Done. Remember to 'git add' the new .age files and secrets.nix"
''

{ pkgs }:
with pkgs; writeScriptBin "gen-borg-keys" ''
  #!${bash}/bin/bash
  BORG_REPONAME=$1
  APPEND_ONLY_USERS=$2
  TRUSTED_USERS=$3

  if [[ -z "$BORG_REPONAME" || -z "$APPEND_ONLY_USERS" || -z "$TRUSTED_USERS" ]]; then
    echo "Usage: gen-borg-keys <BORG_REPONAME> <APPEND_ONLY_USERS> <TRUSTED_USERS>"
    echo "APPEND_ONLY_USERS lists the names of the keys that can decrypt the append only key"
    echo "TRUSTED_USERS lists the names of the keys that can decrypt the trusted key and the append only key"
    echo "Example: gen-borg-keys myrepo 'erms' 'lennart'"
    exit 1
  fi
  set -x
  KEYDIR=$HOME/.ssh

  if [ ! -f secrets.nix ]; then
    if [ ! -d secrets ]; then
      echo "You need to run this script in the directory with the agenix secrets.nix"
      exit 1
    fi

    cd secrets

    if [ ! -f secrets.nix ]; then
      echo "You need to run this script in the directory with the agenix secrets.nix2"
      exit 1
    fi
  fi

  if grep -F "$BORG_REPONAME"_append_only_ed25519 secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${BORG_REPONAME}_append_only_ed25519. Are you sure you want to do this?"
    exit 1
  fi
  if grep -F "$BORG_REPONAME"_trusted_ed25519 secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${BORG_REPONAME}_trusted_ed25519. Are you sure you want to do this?"
    exit 1
  fi

  echo "Generating keys for borg repo ''${BORG_REPONAME}"

  function add_key {
    local key_name=$1
    local public_keys_marker=$2
    local secrets_marker=$3
    # Comment in the key file
    local comment=$4
    local key_type=$5
    local decryptors="$(echo -ne "$6" | ${lib.getExe pkgs.gawk} '{$1=$1};1')"

    KEY_BASENAME="$key_name"_"$key_type"
    PRIVATE_KEY_NAME="$KEY_BASENAME"
    PUBLIC_KEY_NAME="$KEY_BASENAME".pub
    PRIVATE_KEY_SECRETS_NAME=$PRIVATE_KEY_NAME.age
    PUBLIC_KEY_SECRETS_NAME="$PRIVATE_KEY_NAME"_pub.age

    ${openssh}/bin/ssh-keygen -t ''${key_type} -N "" -f $KEYDIR/$PRIVATE_KEY_NAME -C "$comment"

    PUBLIC_KEY=$(cat $KEYDIR/$PUBLIC_KEY_NAME | cut -d " " -f 1-2)


    ${perl}/bin/perl -pi -e '$_ = q(  '$key_name' = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /'"$public_keys_marker"'/' public-keys.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PRIVATE_KEY_SECRETS_NAME'".publicKeys = [ recovery '"$decryptors"' ];) . qq(\n) . $_ if /'"$secrets_marker"'/' secrets.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PUBLIC_KEY_SECRETS_NAME'".publicKeys = [ recovery '"$decryptors"' ];) . qq(\n) . $_ if /'"$secrets_marker"'/' secrets.nix

    cat $KEYDIR/$PRIVATE_KEY_NAME | ${pkgs.agenix}/bin/agenix -e "$PRIVATE_KEY_SECRETS_NAME"
    cat $KEYDIR/$PUBLIC_KEY_NAME | ${pkgs.agenix}/bin/agenix -e "$PUBLIC_KEY_SECRETS_NAME"
  }

  add_key ''${BORG_REPONAME}_append_only MARKER_BORG_BACKUP_KEYS MARKER_BORG_BACKUP_KEYS "" ed25519 "$APPEND_ONLY_USERS $TRUSTED_USERS"
  add_key ''${BORG_REPONAME}_trusted MARKER_BORG_BACKUP_KEYS MARKER_BORG_BACKUP_KEYS "" ed25519 "$TRUSTED_USERS"

  echo Generating borg passphrase

  PASSPHRASE_SECRETS_NAME="$BORG_REPONAME"_passphrase.age
  ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSPHRASE_SECRETS_NAME'".publicKeys = [ recovery '"$(echo -ne "$APPEND_ONLY_USERS $TRUSTED_USERS" | ${lib.getExe pkgs.gawk} '{$1=$1};1')"' ];) . qq(\n) . $_ if /'MARKER_BORG_PASSPHRASES'/' secrets.nix
  tr -dc A-Za-z0-9 </dev/urandom | head -c 64 | ${pkgs.agenix}/bin/agenix -e "$PASSPHRASE_SECRETS_NAME"

  echo "Successfully generated keys for ''${BORG_REPONAME}"
  echo "The public ed25519 was written to secrets.nix and all other keys were added to agenix"
  echo "The unencrypted private key is at $KEYDIR/''${BORG_REPONAME}_ed25519"
''

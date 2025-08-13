{ pkgs }:
with pkgs; writeScriptBin "gen-mail-account" ''
  #!${bash}/bin/bash
  USERNAME=$1

  if [[ -z "$USERNAME" ]]; then
    echo "Usage: gen-mail-account <USERNAME>"
    echo "USERNAME you want to generate a password for."
    echo "Example: gen-mail-account martha"
    exit 1
  fi
  set -x
  set -e

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

  if grep -F "$USERNAME"_mail_password secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${USERNAME}_mail_password. Are you sure you want to do this?"
    exit 1
  fi

  echo "Generating mail account for ''${USERNAME}"

  # all_decryptors="$MAIL_RELAY_HOST_NAME blanderdash kashenblade"

  PASSWORD=
  PASSWORDHASH=
  function add_login_password {
    VPN_MAIL_SECRETS_MARKER="MARKER_VPN_MAIL_SECRETS"

    PASSWORD_SECRETS_NAME="$USERNAME"_mail_password.age
    PASSWORDHASH_SECRETS_NAME="$USERNAME"_mail_passwordhash.age

    PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64)
    PASSWORDHASH=$(${lib.getExe' pkgs.mkpasswd "mkpasswd"} -m bcrypt "$PASSWORD" )

    ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSWORD_SECRETS_NAME'".publicKeys = [ recovery blanderdash kashenblade ];) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSWORDHASH_SECRETS_NAME'".publicKeys = [ recovery ] ++ mailServers;) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix

    echo "$PASSWORD" | ${pkgs.agenix}/bin/agenix -e "$PASSWORD_SECRETS_NAME"
    echo "$PASSWORDHASH" | ${pkgs.agenix}/bin/agenix -e "$PASSWORDHASH_SECRETS_NAME"
  }

  add_login_password
  echo "Successfully added a mail login password for ''${USERNAME}"
  echo "The password is '$PASSWORD'. You should copy it now, because it will not be shown again."
''

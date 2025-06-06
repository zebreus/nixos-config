{ pkgs }:
with pkgs; writeScriptBin "gen-vpn-mail-secrets" ''
  #!${bash}/bin/bash
  HOST_NAME=$1
  MAIL_RELAY_HOST_NAME=$2

  if [[ -z "$HOST_NAME" || -z "$MAIL_RELAY_HOST_NAME" ]]; then
    echo "Usage: gen-vpn-mail-secrets <HOST_NAME> <MAIL_RELAY_HOST_NAME>"
    echo "HOST_NAME is the name of the host you want to generate keys for."
    echo "MAIL_RELAY_HOST_NAME is the name of the mail relay in the VPN."
    echo "Example: gen-vpn-mail-secrets erms sempriaq"
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

  if grep -F "$HOST_NAME"_dkim_rsa secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${HOST_NAME}_dkim_rsa. Are you sure you want to do this?"
    exit 1
  fi
  if grep -F "$HOST_NAME"_mail_password secrets.nix >/dev/null; then
    echo "Your secrets.nix already mentions ''${HOST_NAME}_mail_password. Are you sure you want to do this?"
    exit 1
  fi

  echo "Generating VPN mail secrets for ''${HOST_NAME}"

  all_decryptors="$HOST_NAME"
  if [ "$MAIL_RELAY_HOST_NAME" != "$HOST_NAME" ]; then
    all_decryptors="$all_decryptors $MAIL_RELAY_HOST_NAME"
  fi


  function add_dkim_key {
    VPN_MAIL_SECRETS_MARKER="MARKER_VPN_MAIL_SECRETS"
    VPN_MAIL_PUBLIC_KEYS_MARKER="MARKER_VPN_MAIL_DKIM_PUBLIC_KEYS"

    PUBLIC_KEY_NAME=''${HOST_NAME}_dkim
    PRIVATE_KEY_SECRETS_NAME="$PUBLIC_KEY_NAME"_rsa.age
    PUBLIC_KEY_SECRETS_NAME="$PUBLIC_KEY_NAME"_rsa_pub.age

    PRIVATE_KEY=$(${lib.getExe pkgs.openssl} genrsa 4096)
    PUBLIC_KEY=$(echo "$PRIVATE_KEY" | ${lib.getExe pkgs.openssl} rsa -pubout -outform der | ${lib.getExe pkgs.openssl} base64 -A)


    ${perl}/bin/perl -pi -e '$_ = q(  '$PUBLIC_KEY_NAME' = "'"$PUBLIC_KEY"'";) . qq(\n) . $_ if /'"$VPN_MAIL_PUBLIC_KEYS_MARKER"'/' public-keys.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PRIVATE_KEY_SECRETS_NAME'".publicKeys = [ recovery '"$MAIL_RELAY_HOST_NAME"' ];) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PUBLIC_KEY_SECRETS_NAME'".publicKeys = [ recovery '"$MAIL_RELAY_HOST_NAME"' ];) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix

    echo "$PRIVATE_KEY" | ${pkgs.agenix}/bin/agenix -e "$PRIVATE_KEY_SECRETS_NAME"
    echo "$PUBLIC_KEY" | ${pkgs.agenix}/bin/agenix -e "$PUBLIC_KEY_SECRETS_NAME"
  }

  function add_login_password {
    VPN_MAIL_SECRETS_MARKER="MARKER_VPN_MAIL_SECRETS"

    PASSWORD_SECRETS_NAME="$HOST_NAME"_mail_password.age
    PASSWORDHASH_SECRETS_NAME="$HOST_NAME"_mail_passwordhash.age

    PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64)
    PASSWORDHASH=$(${lib.getExe' pkgs.mkpasswd "mkpasswd"} -m bcrypt "$PASSWORD" )

    ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSWORD_SECRETS_NAME'".publicKeys = [ recovery '"$HOST_NAME"' ];) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix
    ${perl}/bin/perl -pi -e '$_ = q(  "'$PASSWORDHASH_SECRETS_NAME'".publicKeys = [ recovery '"$all_decryptors"' ] ++ mailServers;) . qq(\n) . $_ if /'"$VPN_MAIL_SECRETS_MARKER"'/' secrets.nix

    echo "$PASSWORD" | ${pkgs.agenix}/bin/agenix -e "$PASSWORD_SECRETS_NAME"
    echo "$PASSWORDHASH" | ${pkgs.agenix}/bin/agenix -e "$PASSWORDHASH_SECRETS_NAME"
  }

  add_dkim_key

  echo "Successfully added a dkim key for ''${HOST_NAME}"

  add_login_password
  echo "Successfully added a mail login password for ''${HOST_NAME}"

  echo "Successfully generated VPN mail secrets for ''${HOST_NAME}"
  echo "The DKIM private key was written to secrets.nix"
  echo "The DKIM public key was written to secrets.nix and public-keys.nix"
''
